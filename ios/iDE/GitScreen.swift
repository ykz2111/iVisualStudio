import SwiftUI

/// S9 · Git / Diff. Changes, one tap per file to its diff, then the commit bar.
/// The bar is a 48 pt field plus the one action the screen exists for.
struct GitScreen: View {
    let workspace: Workspace
    let onBindingsChanged: (Workspace) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var changes: [PendingChange] = []
    @State private var selected: Set<String> = []
    @State private var message = ""
    @State private var isLoading = true
    @State private var isBusy = false
    @State private var banner: Banner?
    @State private var statusLine: String?

    enum Banner {
        case error(String)
        case pushRejected(String)
        case info(String)
    }

    private var github: GitHubBinding? { workspace.github }
    private var ssh: SSHBinding? { workspace.ssh }

    var body: some View {
        List {
            if let banner {
                Section { bannerRow(banner) }
                    .listRowBackground(IDETheme.canvas)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            Section {
                if isLoading {
                    HStack(spacing: 10) {
                        ProgressView().tint(IDETheme.azure)
                        Text("Reading the workspace…")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                    }
                    .frame(minHeight: IDETheme.recommendedHitTarget)
                    .listRowBackground(IDETheme.chassis)
                } else if changes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Working tree clean")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(IDETheme.primary)
                        Text(workspace.transportLabel)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                    }
                    .frame(minHeight: IDETheme.recommendedHitTarget)
                    .listRowBackground(IDETheme.chassis)
                } else {
                    ForEach(changes) { change in
                        NavigationLink {
                            DiffScreen(
                                title: change.name,
                                original: originalText(for: change),
                                current: change.current,
                                subtitle: change.path
                            )
                        } label: {
                            changeRow(change)
                        }
                        .listRowBackground(IDETheme.chassis)
                        .listRowSeparatorTint(IDETheme.elevated)
                    }
                }
            } header: {
                HStack {
                    Text("CHANGES")
                    Spacer()
                    Text("\(changes.count)")
                        .foregroundStyle(IDETheme.muted)
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(0.7)
                .foregroundStyle(IDETheme.secondary)
                .textCase(nil)
            }

            if let statusLine {
                Section {
                    Text(statusLine)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(IDETheme.emerald)
                        .listRowBackground(IDETheme.chassis)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(IDETheme.canvas)
        .navigationTitle("Git")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .frame(minHeight: IDETheme.minimumHitTarget)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { commitBar }
        .task { await load() }
    }

    // MARK: Rows

    private func bannerRow(_ banner: Banner) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: bannerIcon(banner))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(bannerColor(banner))
            VStack(alignment: .leading, spacing: 6) {
                Text(bannerText(banner))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(IDETheme.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if case .pushRejected = banner {
                    Button {
                        Task { await pullThenPush() }
                    } label: {
                        Text("Pull, then push")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .frame(height: IDETheme.recommendedHitTarget)
                            .background(IDETheme.amber.opacity(0.16), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(IDETheme.amber)
                    .disabled(isBusy)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private func changeRow(_ change: PendingChange) -> some View {
        HStack(spacing: 12) {
            Text(change.status.rawValue)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(color(for: change.status))
                .frame(width: 20, height: 20)
                .background(color(for: change.status).opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(change.name)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(IDETheme.primary)
                    .lineLimit(1)
                if !change.directory.isEmpty {
                    Text(change.directory)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(IDETheme.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
        }
        .frame(minHeight: IDETheme.recommendedHitTarget)
        .contentShape(Rectangle())
    }

    private var commitBar: some View {
        VStack(spacing: 8) {
            TextField("Commit message", text: $message, axis: .vertical)
                .lineLimit(1...3)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: IDETheme.recommendedHitTarget, alignment: .leading)
                .background(IDETheme.chassis, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(IDETheme.elevated, lineWidth: 1)
                }

            Button {
                Task { await commit() }
            } label: {
                HStack(spacing: 8) {
                    if isBusy {
                        ProgressView().tint(IDETheme.oledBlack)
                    }
                    Text(isBusy ? "PUSHING" : "COMMIT & PUSH")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: IDETheme.recommendedHitTarget)
                .background(canCommit ? IDETheme.emerald : IDETheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(canCommit ? IDETheme.oledBlack : IDETheme.muted)
            .disabled(!canCommit)
            .accessibilityHint("Commits the selected changes and pushes to the branch")
        }
        .padding(.horizontal, IDETheme.pageGutter)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(IDETheme.canvas)
        .overlay(alignment: .top) {
            Rectangle().fill(IDETheme.elevated).frame(height: 1)
        }
    }

    // MARK: State helpers

    private var canCommit: Bool {
        !isBusy && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !changes.isEmpty
    }

    private func originalText(for change: PendingChange) -> String {
        if let mirrored = change.mirrored { return mirrored }
        // GitHub base text is fetched while loading and cached here.
        return baseCache[change.path] ?? ""
    }

    @State private var baseCache: [String: String] = [:]

    private func color(for status: PendingChange.Status) -> Color {
        switch status {
        case .added: return IDETheme.emerald
        case .modified: return IDETheme.amber
        case .deleted: return IDETheme.coral
        }
    }

    private func bannerIcon(_ banner: Banner) -> String {
        switch banner {
        case .error, .pushRejected: return "exclamationmark.triangle.fill"
        case .info: return "checkmark.circle.fill"
        }
    }

    private func bannerColor(_ banner: Banner) -> Color {
        switch banner {
        case .error: return IDETheme.coral
        case .pushRejected: return IDETheme.amber
        case .info: return IDETheme.emerald
        }
    }

    private func bannerText(_ banner: Banner) -> String {
        switch banner {
        case .error(let text), .info(let text), .pushRejected(let text): return text
        }
    }

    // MARK: Actions

    private func load() async {
        isLoading = true
        banner = nil
        baseCache = [:]
        do {
            if let github {
                let pending = try await WorkspaceSync.shared.changes(binding: github)
                for change in pending where change.baseSHA != nil && change.status != .added {
                    if let base = try? await WorkspaceSync.shared.baseText(binding: github, path: change.path) {
                        baseCache[change.path] = base
                    }
                }
                changes = pending
            } else if let ssh, workspace.rootURL != nil {
                changes = try await WorkspaceSync.shared.sshGitStatus(binding: ssh, workspaceID: workspace.id)
            }
        } catch {
            banner = .error(error.localizedDescription)
        }
        isLoading = false
    }

    private func commit() async {
        isBusy = true
        banner = nil
        statusLine = nil
        defer { isBusy = false }
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if let github {
                let updated = try await WorkspaceSync.shared.commitGitHub(
                    binding: github,
                    message: text,
                    paths: changes.map(\.path)
                )
                var next = workspace
                next.github = updated
                onBindingsChanged(next)
                await storeIntoLibrary(next)
                Haptics.success()
                statusLine = "Pushed \(changes.count) change\(changes.count == 1 ? "" : "s") to \(updated.label)"
                message = ""
                await load()
            } else if let ssh {
                let output = try await WorkspaceSync.shared.sshGitCommit(
                    binding: ssh,
                    workspaceID: workspace.id,
                    message: text,
                    paths: changes.map(\.path)
                )
                Haptics.success()
                statusLine = output.isEmpty ? "Committed on the host." : output
                message = ""
                await load()
            }
        } catch {
            Haptics.error()
            if let githubError = error as? GitHubError, case .http(let status, _) = githubError, status == 409 || status == 422 {
                banner = .pushRejected(error.localizedDescription)
            } else {
                banner = .error(error.localizedDescription)
            }
        }
    }

    private func pullThenPush() async {
        guard let github else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let (updated, conflicts) = try await WorkspaceSync.shared.pullGitHub(binding: github)
            var next = workspace
            next.github = updated
            onBindingsChanged(next)
            await storeIntoLibrary(next)
            if conflicts.isEmpty {
                banner = .info("Pulled. Review the changes, then commit again.")
            } else {
                banner = .error("Pulled, but these files were edited on both sides and kept as-is: \(conflicts.joined(separator: ", "))")
            }
            await load()
        } catch {
            Haptics.error()
            banner = .error(error.localizedDescription)
        }
    }

    private func storeIntoLibrary(_ workspace: Workspace) async {
        guard let binding = workspace.github else { return }
        var library = WorkspaceLibrary.load()
        library.storeGithub(id: workspace.id, name: workspace.name, binding: binding)
        library.save()
    }
}

/// Unified diff, two-signal per design decision 7: a glyph and a 2 pt rule, with
/// colour only as the third signal.
struct DiffScreen: View {
    let title: String
    let original: String
    let current: String
    var subtitle: String = ""

    @State private var hunks: [DiffHunk] = []
    @State private var tooLarge = false

    var body: some View {
        Group {
            if tooLarge {
                ContentUnavailableView(
                    "Too large to diff",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Files over \(LineDiff.maximumLines) lines open in the editor instead.")
                )
            } else if hunks.isEmpty {
                ContentUnavailableView(
                    "No differences",
                    systemImage: "equal.circle",
                    description: Text("This file matches the version it was compared against.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(hunks) { hunk in
                            Text(hunk.header)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(IDETheme.azure)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(IDETheme.chassis)

                            ForEach(hunk.lines) { line in
                                DiffLineRow(line: line)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .background(IDETheme.oledBlack)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: title + current.hashValue.description) { load() }
    }

    private func load() {
        if let diff = LineDiff.between(old: original, new: current) {
            hunks = LineDiff.hunks(from: diff)
            tooLarge = false
        } else {
            hunks = []
            tooLarge = true
        }
    }
}

private struct DiffLineRow: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(ruleColor)
                .frame(width: line.kind == .context ? 0 : 2)
            Text(line.glyph)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ruleColor)
                .frame(width: 18, alignment: .center)
                .padding(.top, 3)
            Text(line.text.isEmpty ? " " : line.text)
                .font(.system(size: 13.5, design: .monospaced))
                .foregroundStyle(line.kind == .context ? IDETheme.primary : ruleColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .padding(.trailing, 12)
        }
        .frame(minHeight: 20)
        .background(background)
        .accessibilityLabel("\(accessibilityPrefix)\(line.text)")
    }

    private var ruleColor: Color {
        switch line.kind {
        case .context: return IDETheme.muted
        case .added: return IDETheme.emerald
        case .removed: return IDETheme.coral
        }
    }

    private var background: Color {
        switch line.kind {
        case .context: return .clear
        case .added: return IDETheme.emerald.opacity(0.08)
        case .removed: return IDETheme.coral.opacity(0.08)
        }
    }

    private var accessibilityPrefix: String {
        switch line.kind {
        case .context: return ""
        case .added: return "Added: "
        case .removed: return "Removed: "
        }
    }
}
