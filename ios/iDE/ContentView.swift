import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var navigationPath: [NavigationRoute] = []
    @State private var importedWorkspaces: [Workspace] = []
    @State private var showFolderImporter = false
    @State private var quickOpenWorkspace: Workspace?
    @State private var importError: String?
    @State private var activeFolderAccess: [URL] = []

    private var workspaces: [Workspace] {
        [.sample] + importedWorkspaces
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeScreen(
                workspaces: workspaces,
                onOpenFolder: { showFolderImporter = true }
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
            _ = url.startAccessingSecurityScopedResource()
            activeFolderAccess.append(url)
            let workspace = Workspace(
                id: url.standardizedFileURL.absoluteString,
                name: url.deletingLastPathComponent().lastPathComponent.isEmpty
                    ? url.lastPathComponent
                    : url.lastPathComponent,
                rootURL: url
            )
            if !importedWorkspaces.contains(workspace) {
                importedWorkspaces.append(workspace)
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

private struct HomeScreen: View {
    let workspaces: [Workspace]
    let onOpenFolder: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workspaces")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(IDETheme.primary)
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
                    SectionEyebrow(title: "ON THIS DEVICE", trailing: "\(workspaces.count) WORKSPACES")
                    ForEach(workspaces) { workspace in
                        NavigationLink(value: NavigationRoute.workspace(workspace)) {
                            WorkspaceCard(workspace: workspace)
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
            Button(action: onOpenFolder) {
                Label("Open a folder", systemImage: "folder.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: IDETheme.recommendedHitTarget)
                    .background(IDETheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(IDETheme.secondary.opacity(0.22), lineWidth: 1)
                    }
            }
            .foregroundStyle(IDETheme.primary)
            .padding(.horizontal, IDETheme.pageGutter)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(IDETheme.canvas)
        }
    }
}

private struct WorkspaceCard: View {
    let workspace: Workspace

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(IDETheme.thumbBar)
                Image(systemName: workspace.isSample ? "chevron.left.forwardslash.chevron.right" : "folder.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(IDETheme.azure)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(workspace.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(IDETheme.primary)
                    .lineLimit(1)
                Text(workspace.isSample ? "Sample project · 6 files" : "Local folder · editable")
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

    private var entries: [WorkspaceEntry] {
        WorkspaceContent.entries(in: workspace, at: directoryPath)
    }

    var body: some View {
        List {
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
                Button(action: onQuickOpen) {
                    Image(systemName: "magnifyingglass")
                        .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                }
                .accessibilityLabel("Quick Open")
            }
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
        workspace.isSample ? "Workspace root" : "\(workspace.name) · root"
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


