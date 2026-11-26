import SwiftUI

/// S8 · Terminal. Streams `exec` output from an SSH session into a native sheet —
/// no embedded terminal emulator, no on-device shell (build plan §8).
struct TerminalSheet: View {
    let workspace: Workspace

    @Environment(\.dismiss) private var dismiss
    @State private var output: [String] = []
    @State private var command = ""
    @State private var isRunning = false
    @State private var exitNote: String?
    @State private var tasks: [RemoteTask] = []
    @State private var runTask: Task<Void, Never>?

    private var remoteDirectory: String? {
        workspace.ssh?.remotePath
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if remoteDirectory == nil {
                    ContentUnavailableView(
                        "No remote session",
                        systemImage: "terminal",
                        description: Text("The terminal needs an SSH workspace. Open one from Connections, then come back.")
                    )
                } else {
                    transcript
                    accessoryRow
                    inputRow
                }
            }
            .background(IDETheme.oledBlack)
            .navigationTitle("Terminal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        output.removeAll()
                        exitNote = nil
                        Haptics.light()
                    }
                    .frame(minHeight: IDETheme.minimumHitTarget)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .frame(minHeight: IDETheme.minimumHitTarget)
                }
            }
            .task { await loadTasks() }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.fraction(0.62), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Pieces

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(output.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(ansiColor(for: line))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(index)
                    }
                    if let exitNote {
                        Text(exitNote)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(exitNote.hasPrefix("exit 0") ? IDETheme.emerald : IDETheme.coral)
                            .padding(.top, 6)
                            .id("exit-note")
                    }
                }
                .padding(12)
            }
            .onChange(of: output.count) { _, _ in
                if let last = output.indices.last {
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IDETheme.oledBlack)
    }

    private var accessoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: IDETheme.minimumGap) {
                if !tasks.isEmpty {
                    Menu {
                        ForEach(tasks) { task in
                            Button(task.name) { runTaskNow(task) }
                        }
                    } label: {
                        Label("TASKS", systemImage: "list.bullet.rectangle")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 12)
                            .frame(height: IDETheme.recommendedHitTarget)
                            .background(IDETheme.thumbBar, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .foregroundStyle(IDETheme.primary)
                }
                ForEach(["Esc", "Tab", "↑", "↓", "⇥"], id: \.self) { key in
                    Button {
                        Haptics.light()
                        sendSpecial(key)
                    } label: {
                        Text(key)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .frame(width: 44, height: IDETheme.recommendedHitTarget)
                            .background(IDETheme.thumbBar, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(IDETheme.primary)
                    .accessibilityLabel(key == "⇥" ? "Control C" : key)
                }
                if isRunning {
                    Button {
                        runTask?.cancel()
                        exitNote = "cancelled"
                        isRunning = false
                        Haptics.medium()
                    } label: {
                        Text("STOP")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 14)
                            .frame(height: IDETheme.recommendedHitTarget)
                            .background(IDETheme.coral.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(IDETheme.coral)
                }
            }
            .padding(.horizontal, IDETheme.pageGutter)
        }
        .frame(height: IDETheme.recommendedHitTarget + 8)
        .background(IDETheme.chassis)
        .overlay(alignment: .top) { Rectangle().fill(IDETheme.elevated).frame(height: 1) }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            Text("$")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(IDETheme.emerald)
            TextField("command", text: $command)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.go)
                .onSubmit { run(command) }
            Button {
                run(command)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .frame(width: IDETheme.minimumHitTarget, height: IDETheme.minimumHitTarget)
            }
            .buttonStyle(.plain)
            .foregroundStyle(command.isEmpty || isRunning ? IDETheme.muted : IDETheme.emerald)
            .disabled(command.isEmpty || isRunning)
        }
        .padding(.horizontal, IDETheme.pageGutter)
        .padding(.vertical, 6)
        .background(IDETheme.chassis)
    }

    // MARK: Actions

    private func run(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isRunning else { return }
        command = ""
        append("$ " + text, color: IDETheme.secondary)

        let directory = remoteDirectory ?? ""
        // Base64 the command so the user's quoting survives the shell intact.
        let encoded = Data(text.utf8).base64EncodedString()
        let wrapped = "cd \(WorkspaceSync.quote(directory)) 2>/dev/null; " +
            "__ide_cmd=$(printf %s \(WorkspaceSync.quote(encoded)) | base64 -d); " +
            "sh -c \"$__ide_cmd\""

        isRunning = true
        exitNote = nil
        runTask = Task {
            do {
                if let binding = workspace.ssh {
                    try await WorkspaceSync.shared.ensureSSHSession(workspaceID: workspace.id, binding: binding)
                }
                let result = try await WorkspaceSync.shared.sshRun(workspaceID: workspace.id, command: wrapped) { chunk, isError in
                    append(chunk, color: isError ? IDETheme.coral : IDETheme.primary)
                }
                await MainActor.run {
                    exitNote = "exit \(result.exitStatus)"
                    finish()
                }
            } catch {
                await MainActor.run {
                    append(error.localizedDescription, color: IDETheme.coral)
                    exitNote = "failed"
                    finish()
                }
            }
        }
    }

    private func finish() {
        isRunning = false
        runTask = nil
    }

    private func sendSpecial(_ key: String) {
        switch key {
        case "Esc": run("printf '\\033'")
        case "Tab": run("printf '\\t'")
        case "↑": run("history | tail -1")
        case "↓": run("history | tail -1")
        case "⇥": run("kill -INT $$")
        default: break
        }
    }

    private func append(_ chunk: String, color: Color) {
        // Split on newlines so the transcript scrolls and selects line by line.
        let lines = chunk.components(separatedBy: "\n")
        for line in lines {
            if line.isEmpty { continue }
            output.append(line)
        }
        if output.count > 800 { output.removeFirst(output.count - 800) }
        _ = color
    }

    private func ansiColor(for line: String) -> Color {
        if line.hasPrefix("$ ") { return IDETheme.secondary }
        if line.contains("error") || line.contains("Error") || line.contains("FAIL") { return IDETheme.coral }
        if line.contains("warning") || line.contains("WARN") { return IDETheme.amber }
        if line.contains("PASS") || line.contains("✔") || line.contains("passed") { return IDETheme.emerald }
        return IDETheme.primary
    }

    private func loadTasks() async {
        guard let directory = remoteDirectory, let binding = workspace.ssh else { return }
        do {
            try await WorkspaceSync.shared.ensureSSHSession(workspaceID: workspace.id, binding: binding)
            let result = try await WorkspaceSync.shared.sshRun(
                workspaceID: workspace.id,
                command: "cd \(WorkspaceSync.quote(directory)) && (cat .ide/tasks.json 2>/dev/null || cat .vscode/tasks.json 2>/dev/null)"
            ) { _, _ in }
            tasks = RemoteTask.parse(result.stdout)
        } catch {
            tasks = []
            if output.isEmpty {
                append(error.localizedDescription, color: IDETheme.coral)
            }
        }
    }

    private func runTaskNow(_ task: RemoteTask) {
        run(task.command)
    }
}

/// A named command from `.ide/tasks.json` or VS Code's `.vscode/tasks.json`.
struct RemoteTask: Identifiable, Hashable {
    let id: String
    let name: String
    let command: String

    /// Tolerant of VS Code's JSON-with-comments and of the two shapes it allows
    /// (`{"label", "command": "npm test"}` and `{"command": "npm", "args": [...]}`).
    static func parse(_ text: String) -> [RemoteTask] {
        guard let data = stripComments(text).data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = root["tasks"] as? [[String: Any]] else { return [] }

        return list.compactMap { entry in
            let name = (entry["label"] as? String) ?? (entry["name"] as? String) ?? (entry["command"] as? String)
            guard let name else { return nil }
            var command = (entry["command"] as? String) ?? ""
            if let args = entry["args"] as? [String], !args.isEmpty {
                command += " " + args.map { WorkspaceSync.quote($0) }.joined(separator: " ")
            }
            guard !command.isEmpty else { return nil }
            return RemoteTask(id: name, name: name, command: command)
        }
    }

    /// VS Code allows // and /* */ comments plus trailing commas.
    private static func stripComments(_ text: String) -> String {
        var result = ""
        var inString = false
        var escaped = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if inString {
                result.append(character)
                if escaped { escaped = false }
                else if character == "\\" { escaped = true }
                else if character == "\"" { inString = false }
                index = text.index(after: index)
                continue
            }
            if character == "\"" {
                inString = true
                result.append(character)
                index = text.index(after: index)
                continue
            }
            if character == "/", text.index(after: index) < text.endIndex {
                let next = text[text.index(after: index)]
                if next == "/" {
                    while index < text.endIndex && text[index] != "\n" {
                        index = text.index(after: index)
                    }
                    continue
                }
                if next == "*" {
                    var cursor = text.index(index, offsetBy: 2)
                    while cursor < text.endIndex {
                        if text[cursor] == "*", text.index(after: cursor) < text.endIndex, text[text.index(after: cursor)] == "/" {
                            cursor = text.index(cursor, offsetBy: 2)
                            break
                        }
                        cursor = text.index(after: cursor)
                    }
                    index = cursor
                    continue
                }
            }
            result.append(character)
            index = text.index(after: index)
        }
        return result
    }
}
