import Foundation
import UniformTypeIdentifiers

/// A GitHub repository behind a workspace. `baseCommit` and `baseTree` are the
/// last commit this device synced with; `blobs` records the blob id of every
/// file that was pulled down, so a commit only sends what actually changed.
struct GitHubBinding: Hashable, Codable {
    let owner: String
    let repo: String
    let branch: String
    var baseCommit: String
    var baseTree: String
    var blobs: [String: String]

    var fullName: String { "\(owner)/\(repo)" }
    var label: String { "\(fullName) · \(branch)" }
}

/// An SSH host behind a workspace. `remotePath` is the directory mirrored into
/// the workspace folder; edits are written back over the same session.
struct SSHBinding: Hashable, Codable {
    let host: String
    let port: Int
    let username: String
    let remotePath: String

    var label: String { "\(username)@\(host)" }
}

struct Workspace: Identifiable, Hashable {
    let id: String
    let name: String
    let rootURL: URL?
    var github: GitHubBinding?
    var ssh: SSHBinding?

    static let sample = Workspace(id: "ide-sample", name: "iDE Sample", rootURL: nil)
    var isSample: Bool { rootURL == nil }
    var isGitHub: Bool { github != nil }
    var isSSH: Bool { ssh != nil }

    /// Protocol line under a workspace card (design plan S1: protocol · latency).
    var transportLabel: String {
        if let github { return "HTTPS · GitHub · \(github.branch)" }
        if let ssh { return "SSH · \(ssh.label)" }
        return isSample ? "Sample project · read-write" : "Local folder · editable"
    }
}

struct CodeFile: Identifiable, Hashable {
    let workspace: Workspace
    let relativePath: String

    var id: String { "\(workspace.id)/\(relativePath)" }
    var name: String { URL(fileURLWithPath: relativePath).lastPathComponent }

    func readText() throws -> String {
        if workspace.isSample {
            if let edited = SessionState.editedFiles[id] {
                return edited
            }
            guard let text = SampleWorkspace.files[relativePath] else {
                throw WorkspaceReadError.fileNotFound
            }
            return text
        }

        guard let rootURL = workspace.rootURL else {
            throw WorkspaceReadError.fileNotFound
        }
        let fileURL = rootURL.appendingPathComponent(relativePath)
        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        guard let text = String(data: data, encoding: .utf8) else {
            throw WorkspaceReadError.notUTF8
        }
        return text
    }

    /// Persists an edit: imported folders write back to disk atomically;
    /// the sample workspace records the edit in a session overlay that
    /// `readText` reads back.
    func writeText(_ text: String) throws {
        if workspace.isSample {
            SessionState.editedFiles[id] = text
            return
        }
        guard let rootURL = workspace.rootURL else {
            throw WorkspaceReadError.fileNotFound
        }
        let fileURL = rootURL.appendingPathComponent(relativePath)
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

enum WorkspaceReadError: LocalizedError {
    case fileNotFound
    case notUTF8

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "This file could not be found in the workspace."
        case .notUTF8:
            return "This file is not UTF-8 text and cannot be previewed."
        }
    }
}

/// Session-scoped overlay of edits made in the bundled sample workspace.
/// The sample has no backing folder, so edits live in memory for the app run.
enum SessionState {
    static var editedFiles: [String: String] = [:]
}

enum NavigationRoute: Hashable {
    case workspace(Workspace)
    case directory(Workspace, String)
    case file(CodeFile)
    case web(String)
}

struct WorkspaceEntry: Identifiable, Hashable {
    let workspace: Workspace
    let relativePath: String
    let isDirectory: Bool

    var id: String { relativePath }
    var name: String { URL(fileURLWithPath: relativePath).lastPathComponent }
    var file: CodeFile { CodeFile(workspace: workspace, relativePath: relativePath) }
}

enum WorkspaceContent {
    static let ignoredDirectoryNames: Set<String> = [
        ".git", "node_modules", "Pods", ".build", "DerivedData", "build", "dist"
    ]

    /// Text test by path only, for content that has not been written yet.
    static func isLikelyTextPath(_ path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent
        let textExtensions: Set<String> = [
            "swift", "h", "m", "mm", "c", "cc", "cpp", "cxx", "rs", "go", "py", "rb",
            "js", "jsx", "ts", "tsx", "html", "css", "scss", "json", "xml", "yaml", "yml",
            "toml", "md", "txt", "sh", "bash", "zsh", "sql", "kt", "java", "dart", "php",
            "vue", "svelte", "gradle", "properties", "plist", "xcconfig", "gitignore", "makefile"
        ]
        return textExtensions.contains(url.pathExtension.lowercased()) ||
            ["Makefile", "Dockerfile", ".gitignore"].contains(name)
    }

    static func entries(in workspace: Workspace, at path: String = "") -> [WorkspaceEntry] {
        if workspace.isSample {
            return sampleEntries(workspace: workspace, at: path)
        }
        guard let rootURL = workspace.rootURL else { return [] }
        let directoryURL = path.isEmpty ? rootURL : rootURL.appendingPathComponent(path)
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls.compactMap { url in
            let name = url.lastPathComponent
            guard !ignoredDirectoryNames.contains(name),
                  let values = try? url.resourceValues(forKeys: [.isDirectoryKey]) else {
                return nil
            }
            let relativePath = path.isEmpty ? name : "\(path)/\(name)"
            return WorkspaceEntry(
                workspace: workspace,
                relativePath: relativePath,
                isDirectory: values.isDirectory == true
            )
        }
        .sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        .prefix(300)
        .map { $0 }
    }

    static func allTextFiles(in workspace: Workspace) -> [CodeFile] {
        if workspace.isSample {
            return SampleWorkspace.files.keys.sorted().map {
                CodeFile(workspace: workspace, relativePath: $0)
            }
        }
        guard let rootURL = workspace.rootURL,
              let enumerator = FileManager.default.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        var files: [CodeFile] = []
        while let url = enumerator.nextObject() as? URL {
            let name = url.lastPathComponent
            if ignoredDirectoryNames.contains(name) {
                enumerator.skipDescendants()
                continue
            }
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]) else { continue }
            if values.isDirectory == true { continue }
            guard isLikelyTextFile(url) else { continue }
            let relativePath = String(url.path.dropFirst(rootURL.path.count + 1))
            files.append(CodeFile(workspace: workspace, relativePath: relativePath))
            if files.count >= 800 { break }
        }
        return files.sorted { $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending }
    }

    private static func sampleEntries(workspace: Workspace, at path: String) -> [WorkspaceEntry] {
        let prefix = path.isEmpty ? "" : "\(path)/"
        var children: [String: Bool] = [:]

        for filePath in SampleWorkspace.files.keys where filePath.hasPrefix(prefix) {
            let remainder = String(filePath.dropFirst(prefix.count))
            guard !remainder.isEmpty else { continue }
            let components = remainder.split(separator: "/", maxSplits: 1).map(String.init)
            guard let first = components.first else { continue }
            let childPath = path.isEmpty ? first : "\(path)/\(first)"
            children[childPath] = components.count > 1
        }

        return children.map { WorkspaceEntry(workspace: workspace, relativePath: $0.key, isDirectory: $0.value) }
            .sorted {
                if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    static func isLikelyTextFile(_ url: URL) -> Bool {
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
           type.conforms(to: .text) || type.conforms(to: .sourceCode) {
            return true
        }
        let textExtensions: Set<String> = [
            "swift", "h", "m", "mm", "c", "cc", "cpp", "cxx", "rs", "go", "py", "rb",
            "js", "jsx", "ts", "tsx", "html", "css", "scss", "json", "xml", "yaml", "yml",
            "toml", "md", "txt", "sh", "bash", "zsh", "sql", "kt", "java", "dart", "php",
            "vue", "svelte", "gradle", "properties", "plist", "xcconfig", "gitignore", "makefile"
        ]
        return textExtensions.contains(url.pathExtension.lowercased()) ||
            ["Makefile", "Dockerfile", ".gitignore"].contains(url.lastPathComponent)
    }
}

enum SampleWorkspace {
    static let files: [String: String] = [
        "README.md": """
        # iDE Sample Workspace

        A small local project for exploring the native pocket IDE.

        - Browse files from the workspace screen.
        - Open Quick Open from the search button.
        - Search within a file from the editor toolbar.
        """,
        "Package.swift": """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "PocketSample",
            targets: [
                .executableTarget(name: "PocketSample")
            ]
        )
        """,
        "Sources/EditorView.swift": """
        import SwiftUI

        struct EditorView: View {
            @State private var title = "Workspace ready"

            var body: some View {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.title2.weight(.semibold))

                    Button("Open a source file") {
                        title = "Ready to explore"
                    }
                }
                .padding()
            }
        }
        """,
        "Sources/WorkspaceStore.swift": """
        import Foundation

        struct WorkspaceStore {
            let rootURL: URL

            func files() throws -> [URL] {
                try FileManager.default.contentsOfDirectory(
                    at: rootURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
            }
        }
        """,
        "Sources/ConnectionState.swift": """
        enum ConnectionState: Equatable {
            case local
            case connecting
            case connected(host: String, latencyMilliseconds: Int)
            case disconnected(reason: String)
        }
        """,
        "Resources/Welcome.txt": """
        Welcome to iDE.

        This workspace is bundled with the app so you can explore the first native
        file-browser and code-viewer pass without connecting a remote host.
        """
    ]
}
