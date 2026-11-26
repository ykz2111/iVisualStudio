import SwiftUI

enum EditorSaveState {
    case unsaved
    case saving
    case saved
    case failed

    var label: String {
        switch self {
        case .unsaved: return "UNSAVED"
        case .saving: return "SAVING"
        case .saved: return "SAVED"
        case .failed: return "SAVE FAILED"
        }
    }

    var color: Color {
        switch self {
        case .unsaved: return IDETheme.amber
        case .saving: return IDETheme.azure
        case .saved: return IDETheme.emerald
        case .failed: return .red
        }
    }
}

/// Phase 2 editor screen, Phase 3 round trip: fully editable, autosaved with a
/// 0.9 s debounce plus a synchronous flush on disappear, thumb bar, find &
/// replace, and Git / Terminal entry points for connected workspaces.
struct EditorScreenView: View {
    let file: CodeFile

    @StateObject private var handle = EditorHandle()
    @State private var text = ""
    @State private var lastSavedText = ""
    @State private var loadError: String?
    @State private var saveState: EditorSaveState = .saved
    @State private var showFindSheet = false
    @State private var showGitSheet = false
    @State private var showTerminal = false
    @State private var showLanguageSheet = false
    @State private var showAssist = false
    @State private var selection = ""
    @StateObject private var language = LanguageClient()
    @State private var saveTask: Task<Void, Never>?
    /// The Settings stepper sets the base size; Dynamic Type scales it.
    @ScaledMetric(relativeTo: .footnote) private var scaledCodeSize = IDETheme.codeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var codeSize: CGFloat {
        let base = IDETheme.codeSize
        let factor = base > 0 ? scaledCodeSize / base : 1
        return max(CGFloat(IDESettings.codeSize) * factor, 9)
    }

    var body: some View {
        Group {
            if let loadError {
                ContentUnavailableView(
                    "Can't open this file",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(loadError)
                )
                .background(IDETheme.oledBlack)
            } else {
                ZStack(alignment: .topLeading) {
                    EditorTextView(
                        text: $text,
                        handle: handle,
                        codeSize: codeSize,
                        wrapLines: verticalSizeClass != .compact
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    GutterRulerView(handle: handle)
                        .frame(width: handle.gutterWidth)
                        .allowsHitTesting(false)
                }
                .background(IDETheme.oledBlack)
            }
        }
        .background(IDETheme.oledBlack.ignoresSafeArea())
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFindSheet = true
                } label: {
                    Image(systemName: "text.magnifyingglass")
                        .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                }
                .accessibilityLabel("Find and replace")
            }
            if file.workspace.isGitHub || file.workspace.isSSH {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        flushSave()
                        showGitSheet = true
                    } label: {
                        Image(systemName: "arrow.triangle.branch")
                            .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                    }
                    .accessibilityLabel("Git changes")
                }
            }
            if file.workspace.isSSH {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTerminal = true
                    } label: {
                        Image(systemName: "terminal")
                            .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                    }
                    .accessibilityLabel("Terminal")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await openLanguageSheet() }
                    } label: {
                        Image(systemName: "list.bullet.indent")
                            .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                    }
                    .accessibilityLabel("Diagnostics and completions")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    selection = handle.selectedText()
                    showAssist = true
                } label: {
                    Image(systemName: "wand.and.stars")
                        .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                }
                .accessibilityLabel("lpBOT assist for the selection")
            }
        }
        .sheet(isPresented: $showFindSheet) {
            FindReplaceSheet(handle: handle)
        }
        .sheet(isPresented: $showGitSheet) {
            NavigationStack {
                GitScreen(workspace: file.workspace) { _ in }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showTerminal) {
            TerminalSheet(workspace: file.workspace)
        }
        .sheet(isPresented: $showLanguageSheet) {
            LanguageSheet(
                client: language,
                fileName: file.name,
                onInsert: { text in
                    handle.insert(text)
                },
                onJump: { line in
                    handle.jump(toLine: line)
                },
                line: handle.cursorLine,
                column: handle.cursorColumn
            )
        }
        .sheet(isPresented: $showAssist) {
            AssistSheet(selection: selection, fileName: file.name) { replacement in
                guard !replacement.isEmpty else { return }
                handle.replaceSelection(with: replacement)
            }
        }
        .onDisappear {
            flushSave()
            Task {
                await language.closeDocument()
                await language.stop()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ThumbBar(handle: handle)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            statusStrip
        }
        .task(id: file.id) { load() }
        .onChange(of: text) { _, newValue in
            guard newValue != lastSavedText else { return }
            scheduleSave()
        }
    }

    private func openLanguageSheet() async {
        await language.start(workspace: file.workspace, relativePath: file.relativePath)
        await language.openDocument(path: file.relativePath, text: text)
        showLanguageSheet = true
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            ConnectionPill(state: connectionState)
                .accessibilityAddTraits(.isStaticText)
            Spacer(minLength: 8)
            Text("LN \(handle.cursorLine) COL \(handle.cursorColumn)")
                .monospacedDigit()
            Text(saveState.label)
                .foregroundStyle(saveState.color)
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(IDETheme.secondary)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(IDETheme.chassis)
        .accessibilityElement(children: .combine)
    }

    private var connectionState: ConnectionStatus.State {
        if let github = file.workspace.github {
            return .online(host: github.fullName, protocolName: "GITHUB", latency: 0)
        }
        if let ssh = file.workspace.ssh {
            return .online(host: ssh.label, protocolName: "SSH", latency: 0)
        }
        return .local
    }

    private func load() {
        do {
            let loaded = try file.readText()
            text = loaded
            lastSavedText = loaded
            loadError = nil
            saveState = .saved
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveState = .unsaved
        saveTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(0.9))
            } catch {
                return // cancelled; a newer edit rescheduled
            }
            await save()
        }
    }

    private func save() async {
        saveState = .saving
        do {
            try file.writeText(text)
            lastSavedText = text
            saveState = .saved
        } catch {
            saveState = .failed
        }
    }

    private func flushSave() {
        saveTask?.cancel()
        guard text != lastSavedText else { return }
        do {
            try file.writeText(text)
            lastSavedText = text
            saveState = .saved
        } catch {
            saveState = .failed
        }
    }
}
