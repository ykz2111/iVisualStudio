import Crypto
import Foundation

/// One side of a pending change: what the remote holds (`baseSHA`, GitHub) or
/// what this device last mirrored (`current`, SSH), plus the working text.
struct PendingChange: Identifiable, Hashable {
    enum Status: String, Hashable {
        case added = "A"
        case modified = "M"
        case deleted = "D"
    }

    let path: String
    let status: Status
    /// Text in the workspace folder right now ("" for a deleted file).
    let current: String
    /// GitHub blob id of the base version, when the workspace is GitHub-backed.
    let baseSHA: String?
    /// Mirrored text this device last pulled, when the workspace is SSH-backed.
    let mirrored: String?

    var id: String { path }
    var name: String { URL(fileURLWithPath: path).lastPathComponent }
    var directory: String {
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        return parent == "." ? "" : parent
    }
}

/// Local filesystem helpers shared by the local, GitHub and SSH workspaces.
/// Workspace folders live in Application Support so imports survive relaunch
/// and nothing is exposed in the Files app that the user did not import.
enum WorkspaceStorage {
    static var root: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Workspaces", isDirectory: true)
    }

    static var libraryFile: URL { root.appendingPathComponent("library.json") }

    static func workspaceDirectory(for id: String) -> URL {
        root.appendingPathComponent(sanitize(id), isDirectory: true)
    }

    static func baseDirectory(for id: String) -> URL {
        root.appendingPathComponent(sanitize(id) + ".base", isDirectory: true)
    }

    static func mirrorFile(for id: String) -> URL {
        root.appendingPathComponent(sanitize(id) + ".mirror.json")
    }

    static func sanitize(_ id: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
        let mapped = id.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "-" }
        return String(mapped.prefix(120))
    }

    static func ensureDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    static func write(_ text: String, to url: URL) throws {
        try ensureDirectory(url.deletingLastPathComponent())
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Every text file under `root`, relative paths, skipping the directories a
    /// pocket IDE must never walk (build output, dependencies, VCS metadata).
    static func textFiles(under root: URL, limit: Int = 3000) -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants]
        ) else { return [] }

        var paths: [String] = []
        while let url = enumerator.nextObject() as? URL {
            let name = url.lastPathComponent
            if WorkspaceContent.ignoredDirectoryNames.contains(name) {
                enumerator.skipDescendants()
                continue
            }
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true { continue }
            guard WorkspaceContent.isLikelyTextFile(url) else { continue }
            paths.append(String(url.path.dropFirst(root.path.count + 1)))
            if paths.count >= limit { break }
        }
        return paths.sorted()
    }

    static func readText(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// SHA-256 of the text, so a mirror can tell "unchanged" from "edited"
    /// without keeping a second copy of every file.
    static func digest(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Persisted list of workspaces plus the bookmarks that make imported folders
/// survive a relaunch. GitHub and SSH workspaces are re-opened from their
/// bindings; only their folders are cached.
struct WorkspaceLibrary: Codable {
    struct LocalEntry: Codable {
        let id: String
        let name: String
        let bookmark: Data
    }

    struct GitHubEntry: Codable {
        let id: String
        let name: String
        let owner: String
        let repo: String
        let branch: String
        let baseCommit: String
        let baseTree: String
        let mirror: Mirror
    }

    struct SSHEntry: Codable {
        let id: String
        let name: String
        let host: String
        let port: Int
        let username: String
        let remotePath: String
        let fingerprint: String?
    }

    /// path → digest of the text this device last pulled.
    typealias Mirror = [String: String]

    var local: [LocalEntry] = []
    var github: [GitHubEntry] = []
    var ssh: [SSHEntry] = []

    static func load() -> WorkspaceLibrary {
        guard let data = try? Data(contentsOf: WorkspaceStorage.libraryFile),
              let library = try? JSONDecoder().decode(WorkspaceLibrary.self, from: data) else {
            return WorkspaceLibrary()
        }
        return library
    }

    func save() {
        do {
            try WorkspaceStorage.ensureDirectory(WorkspaceStorage.root)
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            try data.write(to: WorkspaceStorage.libraryFile, options: .atomic)
        } catch {
            // Losing the library is recoverable; a crash mid-edit is not.
        }
    }

    /// Resolves every stored entry to a `Workspace`, dropping entries whose
    /// folder or bookmark no longer resolves.
    func workspaces() -> [Workspace] {
        var result: [Workspace] = []

        for entry in local {
            var stale = false
            guard let url = try? URL(
                resolvingBookmarkData: entry.bookmark,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) else { continue }
            _ = url.startAccessingSecurityScopedResource()
            result.append(Workspace(id: entry.id, name: entry.name, rootURL: url))
        }

        for entry in github {
            let root = WorkspaceStorage.workspaceDirectory(for: entry.id)
            let binding = GitHubBinding(
                owner: entry.owner,
                repo: entry.repo,
                branch: entry.branch,
                baseCommit: entry.baseCommit,
                baseTree: entry.baseTree,
                blobs: entry.mirror
            )
            result.append(Workspace(id: entry.id, name: entry.name, rootURL: root, github: binding))
        }

        for entry in ssh {
            let root = WorkspaceStorage.workspaceDirectory(for: entry.id)
            let binding = SSHBinding(
                host: entry.host,
                port: entry.port,
                username: entry.username,
                remotePath: entry.remotePath
            )
            result.append(Workspace(id: entry.id, name: entry.name, rootURL: root, ssh: binding))
        }

        return result
    }

    mutating func upsert(local url: URL, name: String) throws {
        let bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        let id = "local:" + url.standardizedFileURL.path
        local.removeAll { $0.id == id }
        local.append(LocalEntry(id: id, name: name, bookmark: bookmark))
    }

    mutating func remove(id: String) {
        local.removeAll { $0.id == id }
        github.removeAll { $0.id == id }
        ssh.removeAll { $0.id == id }
    }

    mutating func storeGithub(id: String, name: String, binding: GitHubBinding) {
        github.removeAll { $0.id == id }
        github.append(
            GitHubEntry(
                id: id,
                name: name,
                owner: binding.owner,
                repo: binding.repo,
                branch: binding.branch,
                baseCommit: binding.baseCommit,
                baseTree: binding.baseTree,
                mirror: binding.blobs
            )
        )
    }

    mutating func storeSSH(id: String, name: String, binding: SSHBinding, fingerprint: String?) {
        ssh.removeAll { $0.id == id }
        ssh.append(
            SSHEntry(
                id: id,
                name: name,
                host: binding.host,
                port: binding.port,
                username: binding.username,
                remotePath: binding.remotePath,
                fingerprint: fingerprint
            )
        )
    }

    func sshEntry(id: String) -> SSHEntry? {
        ssh.first { $0.id == id }
    }

    func updateMirror(id: String, mirror: Mirror) {
        WorkspaceLibrary.saveMirror(mirror, id: id)
    }

    static func mirror(id: String) -> Mirror {
        guard let data = try? Data(contentsOf: WorkspaceStorage.mirrorFile(for: id)),
              let mirror = try? JSONDecoder().decode(Mirror.self, from: data) else {
            return [:]
        }
        return mirror
    }

    static func saveMirror(_ mirror: Mirror, id: String) {
        try? WorkspaceStorage.ensureDirectory(WorkspaceStorage.root)
        try? JSONEncoder().encode(mirror).write(to: WorkspaceStorage.mirrorFile(for: id), options: .atomic)
    }
}
