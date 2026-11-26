import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var navigationPath: [NavigationRoute] = []
    @State private var library = WorkspaceLibrary.load()
    @State private var showFolderImporter = false
    @State private var showConnections = false
    @State private var showSettings = false
    @State private var quickOpenWorkspace: Workspace?
    @State private var importError: String?
    @State private var activeFolderAccess: [URL] = []
    @AppStorage("ide.advanced.webview") private var advancedWeb = false
    @AppStorage("ide.advanced.webURL") private var advancedWebURL = ""

    private var workspaces: [Workspace] {
        [.sample] + library.workspaces()
    }

    /// The webview workspace exists only when Settings enables it, and it is
    /// never the default surface (build plan §5).
    private var webURL: String? {
        let trimmed = advancedWebURL.trimmingCharacters(in: .whitespaces)
        guard advancedWeb, !trimmed.isEmpty else { return nil }
        return trimmed.contains("://") ? trimmed : "https://" + trimmed
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeScreen(
                workspaces: workspaces,
                webURL: webURL,
                onOpenFolder: { showFolderImporter = true },
                onConnect: { showConnections = true },
                onSettings: { showSettings = true },
                onRemove: remove
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .workspace(let workspace):
                    WorkspaceBrowserView(workspace: workspace) {
                        quickOpenWorkspace = workspace
                    }
                case .directory(let workspace, let path):
                    WorkspaceBrowserView(workspace: workspace, directoryPath: path) {
                        quickOpenWorkspace = workspace
                    }
                case .file(let file):
                    EditorScreenView(file: file)
                case .web(let url):
                    WebWorkspaceView(urlString: url)
                }
            }
        }
        .tint(IDETheme.azure)
        .background(IDETheme.canvas.ignoresSafeArea())
        .fileImporter(
            isPresented: $showFolderImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false,
            onCompletion: handleFolderImport
        )
        .sheet(item: $quickOpenWorkspace) { workspace in
            QuickOpenSheet(workspace: workspace) { file in
                quickOpenWorkspace = nil
                navigationPath.append(.file(file))
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showConnections) {
            NavigationStack {
                ConnectScreen { workspace in
                    library = WorkspaceLibrary.load()
                    navigationPath.append(.workspace(workspace))
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsScreen()
            }
            .preferredColorScheme(.dark)
        }
        .alert("Couldn't open folder", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "Please choose a folder that the Files app can access.")
        }
    }

    private func handleFolderImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importError = "iOS did not grant access to that folder. Try one from On My iPhone or iCloud Drive."
                return
            }
            activeFolderAccess.append(url)
            do {
                try library.upsert(local: url, name: url.lastPathComponent)
                library.save()
                Haptics.success()
            } catch {
                importError = error.localizedDescription
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    private func remove(_ workspace: Workspace) {
        library.remove(id: workspace.id)
        library.save()
        Haptics.medium()
    }
}

private struct HomeScreen: View {
    let workspaces: [Workspace]
    let webURL: String?
    let onOpenFolder: () -> Void
    let onConnect: () -> Void
    let onSettings: () -> Void
    let onRemove: (Workspace) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Workspaces")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(IDETheme.primary)
                        Spacer()
                        Button(action: onSettings) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: IDETheme.minimumHitTarget, height: IDETheme.minimumHitTarget)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(IDETheme.secondary)
                        .accessibilityLabel("Settings")
                    }
                    HStack(spacing: 8) {
                        Circle()
                            .fill(IDETheme.emerald)
                            .frame(width: 7, height: 7)
                        Text("LOCAL · READY TO EXPLORE")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .tracking(0.6)
                            .foregroundStyle(IDETheme.secondary)
                    }
                }
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 12) {
                    SectionEyebrow(title: "WORKSPACES", trailing: "\(workspaces.count)")
                    ForEach(workspaces) { workspace in
                        NavigationLink(value: NavigationRoute.workspace(workspace)) {
                            WorkspaceCard(workspace: workspace)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if !workspace.isSample {
                                Button("Remove from list", systemImage: "trash", role: .destructive) {
                                    onRemove(workspace)
                                }
                            }
                        }
                    }
                }

                if let webURL {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionEyebrow(title: "ADVANCED", trailing: "WEBKIT")
                        NavigationLink(value: NavigationRoute.web(webURL)) {
                            RecentFileRow(
                                icon: "globe",
                                title: URL(string: webURL)?.host ?? "Web workspace",
                                subtitle: "Remote VS Code in WebKit",
                                accent: IDETheme.amber
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionEyebrow(title: "START HERE", trailing: "SAMPLE")
                    NavigationLink(value: NavigationRoute.file(
                        CodeFile(workspace: .sample, relativePath: "Sources/EditorView.swift")
                    )) {
                        RecentFileRow(
                            icon: "swift",
                            title: "EditorView.swift",
                            subtitle: "Sources · SwiftUI view",
                            accent: IDETheme.coral
                        )
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: NavigationRoute.file(
                        CodeFile(workspace: .sample, relativePath: "README.md")
                    )) {
                        RecentFileRow(
                            icon: "doc.text",
                            title: "README.md",
                            subtitle: "iDE Sample Workspace",
                            accent: IDETheme.azure
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, IDETheme.pageGutter)
            .padding(.bottom, 20)
        }
        .background(IDETheme.canvas)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: IDETheme.minimumGap) {
                bottomButton("Open a folder", systemImage: "folder.badge.plus", action: onOpenFolder)
                bottomButton("Connect", systemImage: "antenna.radiowaves.left.and.right", action: onConnect)
            }
            .padding(.horizontal, IDETheme.pageGutter)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(IDETheme.canvas)
        }
    }

    private func bottomButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: IDETheme.recommendedHitTarget)
                .background(IDETheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(IDETheme.secondary.opacity(0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(IDETheme.primary)
    }
}

private struct WorkspaceCard: View {
    let workspace: Workspace

    private var glyph: String {
        if workspace.isSample { return "chevron.left.forwardslash.chevron.right" }
        if workspace.isGitHub { return "arrow.triangle.branch" }
        if workspace.isSSH { return "terminal" }
        return "folder.fill"
    }

    private var accent: Color {
        if workspace.isGitHub { return IDETheme.violet }
        if workspace.isSSH { return IDETheme.cyan }
        return IDETheme.azure
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(IDETheme.thumbBar)
                Image(systemName: glyph)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(workspace.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(IDETheme.primary)
                    .lineLimit(1)
                Text(workspace.transportLabel)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(IDETheme.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(IDETheme.muted)
        }
        .padding(12)
        .background(IDETheme.chassis, in: RoundedRectangle(cornerRadius: IDETheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: IDETheme.cardRadius)
                .strokeBorder(IDETheme.elevated, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: IDETheme.cardRadius))
    }
}

private struct RecentFileRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 44, height: 44)
                .background(IDETheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(IDETheme.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(IDETheme.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(IDETheme.muted)
        }
        .padding(.horizontal, 4)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

private struct SectionEyebrow: View {
    let title: String
    let trailing: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(trailing)
                .foregroundStyle(IDETheme.muted)
        }
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .tracking(0.8)
        .foregroundStyle(IDETheme.secondary)
    }
}

private struct WorkspaceBrowserView: View {
    let workspace: Workspace
    var directoryPath = ""
    let onQuickOpen: () -> Void

    @State private var showGit = false
    @State private var showTerminal = false
    @State private var showPorts = false
    @State private var isSyncing = false
    @State private var syncNote: String?
    @StateObject private var status = ConnectionStatus()

    private var entries: [WorkspaceEntry] {
        WorkspaceContent.entries(in: workspace, at: directoryPath)
    }

    private var canGit: Bool { workspace.isGitHub || workspace.isSSH }

    var body: some View {
        List {
            if let syncNote {
                Section {
                    Text(syncNote)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(IDETheme.emerald)
                        .listRowBackground(IDETheme.chassis)
                }
            }

            if entries.isEmpty {
                ContentUnavailableView(
                    "No files here",
                    systemImage: "folder",
                    description: Text("This folder is empty or iOS couldn't read its contents.")
                )
                .listRowBackground(IDETheme.canvas)
            } else {
                Section {
                    ForEach(entries) { entry in
                        NavigationLink(value: entry.isDirectory
                            ? NavigationRoute.directory(workspace, entry.relativePath)
                            : NavigationRoute.file(entry.file)) {
                            FileEntryRow(entry: entry)
                        }
                        .listRowBackground(IDETheme.chassis)
                        .listRowSeparatorTint(IDETheme.elevated)
                    }
                } header: {
                    Text(directoryPath.isEmpty ? "WORKSPACE FILES" : directoryPath.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(0.7)
                        .foregroundStyle(IDETheme.secondary)
                        .textCase(nil)
                        .padding(.top, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(IDETheme.canvas)
        .navigationTitle(directoryPath.isEmpty ? workspace.name : URL(fileURLWithPath: directoryPath).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Quick Open", systemImage: "magnifyingglass", action: onQuickOpen)
                    if canGit {
                        Button("Git", systemImage: "arrow.triangle.branch") { showGit = true }
                    }
                    if workspace.isSSH {
                        Button("Terminal", systemImage: "terminal") { showTerminal = true }
                        Button("Ports", systemImage: "network") { showPorts = true }
                        Button("Send edits to host", systemImage: "arrow.up.circle") {
                            Task { await sendEditsToHost() }
                        }
                        Button("Pull from host", systemImage: "arrow.down.circle") {
                            Task { await pullFromHost() }
                        }
                        .disabled(isSyncing)
                    }
                    if workspace.isGitHub {
                        Button("Pull from GitHub", systemImage: "arrow.down.circle") {
                            Task { await pullFromGitHub() }
                        }
                        .disabled(isSyncing)
                    }
                } label: {
                    Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : "ellipsis.circle")
                        .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                }
                .accessibilityLabel("Workspace actions")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ConnectionPill(state: status.state) {
                Task { await measureLatency() }
            }
            .background(IDETheme.chassis)
            .overlay(alignment: .top) { Rectangle().fill(IDETheme.elevated).frame(height: 1) }
        }
        .sheet(isPresented: $showGit) {
            NavigationStack {
                GitScreen(workspace: workspace) { _ in }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showTerminal) {
            TerminalSheet(workspace: workspace)
        }
        .sheet(isPresented: $showPorts) {
            PortsSheet(workspace: workspace)
        }
        .task(id: workspace.id) { await describeConnection() }
        .onDisappear { status.reset() }
    }

    /// The pill describes the transport when nothing is measured yet, and turns
    /// into a live latency readout while the workspace is on screen.
    private func describeConnection() {
        if let github = workspace.github {
            status.update(.online(host: github.fullName, protocolName: "GITHUB", latency: 0))
        } else if let ssh = workspace.ssh {
            status.update(.online(host: ssh.label, protocolName: "SSH", latency: 0))
        } else {
            status.update(.local)
        }
    }

    private func measureLatency() async {
        if let github = workspace.github {
            status.startProbing(host: github.fullName, protocolName: "GITHUB") {
                do {
                    return .success(try await WorkspaceSync.shared.githubLatency(
                        owner: github.owner,
                        repo: github.repo,
                        branch: github.branch
                    ))
                } catch {
                    return .failure(error)
                }
            }
        } else if let ssh = workspace.ssh {
            status.startProbing(host: ssh.label, protocolName: "SSH") {
                do {
                    return .success(try await WorkspaceSync.shared.sshLatency(workspaceID: workspace.id, binding: ssh))
                } catch {
                    return .failure(error)
                }
            }
        }
    }

    private func pullFromGitHub() async {
        guard let binding = workspace.github else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let (updated, conflicts) = try await WorkspaceSync.shared.pullGitHub(binding: binding)
            var library = WorkspaceLibrary.load()
            library.storeGithub(id: workspace.id, name: workspace.name, binding: updated)
            library.save()
            syncNote = conflicts.isEmpty
                ? "Pulled \(updated.label)"
                : "Pulled; \(conflicts.count) file\(conflicts.count == 1 ? " was" : "s were") edited on both sides."
            Haptics.success()
        } catch {
            syncNote = error.localizedDescription
            Haptics.error()
        }
    }

    private func pullFromHost() async {
        guard let binding = workspace.ssh else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let conflicts = try await WorkspaceSync.shared.pullSSH(workspaceID: workspace.id, binding: binding)
            syncNote = conflicts.isEmpty
                ? "Pulled from \(binding.label)"
                : "Pulled; \(conflicts.count) file\(conflicts.count == 1 ? " was" : "s were") edited on both sides."
            Haptics.success()
        } catch {
            syncNote = error.localizedDescription
            Haptics.error()
        }
    }

    private func sendEditsToHost() async {
        guard let binding = workspace.ssh else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let changes = await WorkspaceSync.shared.localSSHChanges(workspaceID: workspace.id)
            guard !changes.isEmpty else {
                syncNote = "The host already matches this device."
                return
            }
            let count = try await WorkspaceSync.shared.pushSSH(
                workspaceID: workspace.id,
                binding: binding,
                paths: changes.map(\.path)
            )
            syncNote = "Sent \(count) file\(count == 1 ? "" : "s") to \(binding.label)"
            Haptics.success()
        } catch {
            syncNote = error.localizedDescription
            Haptics.error()
        }
    }
}

private struct FileEntryRow: View {
    let entry: WorkspaceEntry

    private var fileAccent: Color {
        switch entry.name.lowercased().split(separator: ".").last {
        case "swift": return IDETheme.coral
        case "md", "txt": return IDETheme.secondary
        case "json", "yaml", "yml", "toml": return IDETheme.amber
        default: return IDETheme.azure
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isDirectory ? "folder.fill" : "doc.text")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(entry.isDirectory ? IDETheme.azure : fileAccent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(.system(size: 15, weight: entry.isDirectory ? .semibold : .regular, design: .monospaced))
                    .foregroundStyle(IDETheme.primary)
                    .lineLimit(1)
                if !entry.isDirectory {
                    Text(URL(fileURLWithPath: entry.relativePath).deletingLastPathComponent().path == "."
                        ? workspacePathLabel(entry.workspace)
                        : URL(fileURLWithPath: entry.relativePath).deletingLastPathComponent().path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(IDETheme.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }

    private func workspacePathLabel(_ workspace: Workspace) -> String {
        if workspace.isSample { return "Workspace root" }
        if let github = workspace.github { return github.label }
        if let ssh = workspace.ssh { return ssh.label }
        return "\(workspace.name) · root"
    }
}

private struct QuickOpenSheet: View {
    let workspace: Workspace
    let onSelect: (CodeFile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var files: [CodeFile] = []

    private var filteredFiles: [CodeFile] {
        guard !query.isEmpty else { return files }
        return files.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
                $0.relativePath.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredFiles.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .listRowBackground(IDETheme.canvas)
                } else {
                    ForEach(filteredFiles) { file in
                        Button {
                            onSelect(file)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(IDETheme.azure)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(file.name)
                                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                                        .foregroundStyle(IDETheme.primary)
                                    Text(file.relativePath)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(IDETheme.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(minHeight: 48)
                            .contentShape(Rectangle())
                        }
                        .listRowBackground(IDETheme.chassis)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(IDETheme.canvas)
            .navigationTitle("Quick Open")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .frame(minHeight: IDETheme.minimumHitTarget)
                }
            }
            .searchable(text: $query, prompt: "Search files")
        }
        .task {
            files = WorkspaceContent.allTextFiles(in: workspace)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
