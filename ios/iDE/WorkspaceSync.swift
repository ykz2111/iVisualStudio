import Foundation

/// The transport-facing half of a workspace: clone, pull, list changes, diff,
/// commit and push. GitHub goes through REST (blobs → tree → commit → ref);
/// SSH keeps a local mirror and pushes back with `git` on the host. Both paths
/// end at the same three calls the Git screen makes.
actor WorkspaceSync {
    static let shared = WorkspaceSync()

    private var sessions: [String: SSHConnection] = [:]

    // MARK: GitHub

    /// Copies the branch's text files into the workspace folder and records the
    /// blob ids, so a later commit only has to send what changed.
    func cloneGitHub(owner: String, repo: String, branch: String) async throws -> (binding: GitHubBinding, name: String) {
        guard let token = GitHubClient.storedToken, !token.isEmpty else { throw GitHubError.notSignedIn }
        let client = GitHubClient(token: token)
        let repository = try await client.repository(owner: owner, repo: repo)
        let branchName = branch.isEmpty ? repository.defaultBranch : branch
        let head = try await client.head(owner: owner, repo: repo, branch: branchName)
        let tree = try await client.tree(owner: owner, repo: repo, sha: head.treeSHA)

        let id = "github:\(owner)/\(repo)@\(branchName)"
        let folder = WorkspaceStorage.workspaceDirectory(for: id)
        try WorkspaceStorage.ensureDirectory(WorkspaceStorage.root)
        guard !FileManager.default.fileExists(atPath: folder.path) else {
            throw GitHubError.workspaceAlreadyExists
        }
        let stagingFolder = WorkspaceStorage.root.appendingPathComponent(".clone-\(UUID().uuidString)", isDirectory: true)
        try WorkspaceStorage.ensureDirectory(stagingFolder)
        defer { try? FileManager.default.removeItem(at: stagingFolder) }

        var blobs: [String: String] = [:]
        var fileWriteError: Error?
        var fetchError: String?
        let candidates = tree.filter { entry in
            entry.type == "blob" && entry.mode != "120000" &&
                Self.isSafeRelativePath(entry.path) && (entry.size ?? 0) <= 400_000
        }

        // Fetch in batches so a large repository does not open hundreds of
        // sockets at once.
        for batch in candidates.chunked(into: 8) {
            await withTaskGroup(of: (String, String?, String?).self) { group in
                for entry in batch {
                    group.addTask {
                        do {
                            return (entry.path, try await client.blobText(owner: owner, repo: repo, sha: entry.sha), nil)
                        } catch let error as GitHubError {
                            if case .notText = error { return (entry.path, nil, nil) }
                            return (entry.path, nil, error.localizedDescription)
                        } catch {
                            return (entry.path, nil, error.localizedDescription)
                        }
                    }
                }
                for await (path, text, error) in group {
                    if let error {
                        fetchError = error
                        continue
                    }
                    guard let text else { continue }
                    do {
                        try WorkspaceStorage.write(text, to: stagingFolder.appendingPathComponent(path))
                        blobs[path] = batch.first { $0.path == path }?.sha ?? ""
                    } catch {
                        fileWriteError = error
                    }
                }
            }
        }
        if let fileWriteError { throw fileWriteError }
        if let fetchError { throw GitHubError.transport(fetchError) }
        try FileManager.default.moveItem(at: stagingFolder, to: folder)

        let binding = GitHubBinding(
            owner: owner,
            repo: repo,
            branch: branchName,
            baseCommit: head.commitSHA,
            baseTree: head.treeSHA,
            blobs: blobs
        )
        return (binding, repo)
    }

    /// Pulls files that changed on the branch since the last sync. Files edited
    /// on this device that also changed upstream are reported, not overwritten.
    func pullGitHub(binding: GitHubBinding) async throws -> (binding: GitHubBinding, conflicts: [String]) {
        guard let token = GitHubClient.storedToken, !token.isEmpty else { throw GitHubError.notSignedIn }
        let client = GitHubClient(token: token)
        let head = try await client.head(owner: binding.owner, repo: binding.repo, branch: binding.branch)
        guard head.commitSHA != binding.baseCommit else { return (binding, []) }

        let tree = try await client.tree(owner: binding.owner, repo: binding.repo, sha: head.treeSHA)
        let id = "github:\(binding.owner)/\(binding.repo)@\(binding.branch)"
        let folder = WorkspaceStorage.workspaceDirectory(for: id)

        var updated = binding
        var conflicts: [String] = []
        let presentPaths = Set(tree.compactMap { entry in
            entry.type == "blob" && Self.isSafeRelativePath(entry.path) ? entry.path : nil
        })
        let candidates = tree.filter { entry in
            entry.type == "blob" && entry.mode != "120000" &&
                Self.isSafeRelativePath(entry.path) && (entry.size ?? 0) <= 400_000
        }

        // A remote deletion must not erase an edit that exists only on this device.
        for (path, baseSHA) in binding.blobs where !presentPaths.contains(path) {
            let localURL = folder.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: localURL.path) {
                guard let local = WorkspaceStorage.readText(localURL) else {
                    conflicts.append(path)
                    updated.blobs[path] = nil
                    continue
                }
                let base = try await client.blobText(owner: binding.owner, repo: binding.repo, sha: baseSHA)
                if WorkspaceStorage.digest(local) != WorkspaceStorage.digest(base) {
                    conflicts.append(path)
                    updated.blobs[path] = nil
                    continue
                }
                try FileManager.default.removeItem(at: localURL)
            }
            updated.blobs[path] = nil
        }

        for entry in candidates where binding.blobs[entry.path] != entry.sha {
            let localURL = folder.appendingPathComponent(entry.path)
            let remoteText: String
            do {
                remoteText = try await client.blobText(owner: binding.owner, repo: binding.repo, sha: entry.sha)
            } catch let error as GitHubError {
                if case .notText = error {
                    conflicts.append(entry.path)
                    updated.blobs[entry.path] = nil
                    continue
                }
                throw error
            }

            if FileManager.default.fileExists(atPath: localURL.path) {
                guard let local = WorkspaceStorage.readText(localURL) else {
                    conflicts.append(entry.path)
                    updated.blobs[entry.path] = entry.sha
                    continue
                }
                if WorkspaceStorage.digest(local) != WorkspaceStorage.digest(remoteText) {
                    // Locally edited and changed upstream: keep the device's text
                    // and surface the conflict rather than silently losing an edit.
                    conflicts.append(entry.path)
                    updated.blobs[entry.path] = entry.sha
                    continue
                }
            }
            try WorkspaceStorage.write(remoteText, to: localURL)
            updated.blobs[entry.path] = entry.sha
        }

        updated.baseCommit = head.commitSHA
        updated.baseTree = head.treeSHA
        return (updated, conflicts)
    }

    /// Local files that differ from the last sync, with both sides loaded.
    func changes(binding: GitHubBinding) async throws -> [PendingChange] {
        let id = "github:\(binding.owner)/\(binding.repo)@\(binding.branch)"
        let folder = WorkspaceStorage.workspaceDirectory(for: id)
        var changes: [PendingChange] = []

        for path in WorkspaceStorage.textFiles(under: folder) {
            guard let current = WorkspaceStorage.readText(folder.appendingPathComponent(path)) else { continue }
            guard let baseSHA = binding.blobs[path] else {
                changes.append(PendingChange(path: path, status: .added, current: current, baseSHA: nil, mirrored: nil))
                continue
            }
            changes.append(PendingChange(path: path, status: .modified, current: current, baseSHA: baseSHA, mirrored: nil))
        }

        // Drop the ones whose text is byte-identical to the base version. The
        // base text is only fetched for files that are already suspect.
        guard let token = GitHubClient.storedToken, !token.isEmpty else { return changes }
        let client = GitHubClient(token: token)
        var filtered: [PendingChange] = []
        for change in changes {
            guard let baseSHA = change.baseSHA else {
                filtered.append(change)
                continue
            }
            if let base = try? await client.blobText(owner: binding.owner, repo: binding.repo, sha: baseSHA) {
                if WorkspaceStorage.digest(base) == WorkspaceStorage.digest(change.current) {
                    continue
                }
                if change.status == .deleted {
                    // Keep the removed text so the diff can show what went away.
                    filtered.append(
                        PendingChange(path: change.path, status: .deleted, current: "", baseSHA: baseSHA, mirrored: base)
                    )
                    continue
                }
            }
            filtered.append(change)
        }

        let localPaths = Set(filtered.map(\.path) + WorkspaceStorage.textFiles(under: folder))
        for (path, sha) in binding.blobs where !localPaths.contains(path) {
            filtered.append(PendingChange(path: path, status: .deleted, current: "", baseSHA: sha, mirrored: nil))
        }

        return filtered.sorted { $0.path < $1.path }
    }

    /// Sends blobs, a tree, a commit and the ref update, then re-reads the branch
    /// so the workspace knows its new base.
    func commitGitHub(binding: GitHubBinding, message: String, paths: [String]) async throws -> GitHubBinding {
        guard let token = GitHubClient.storedToken, !token.isEmpty else { throw GitHubError.notSignedIn }
        let client = GitHubClient(token: token)
        let id = "github:\(binding.owner)/\(binding.repo)@\(binding.branch)"
        let folder = WorkspaceStorage.workspaceDirectory(for: id)

        let all = try await changes(binding: binding)
        let selected = all.filter { paths.contains($0.path) }
        guard !selected.isEmpty else { throw GitHubError.emptyChange }

        var entries: [[String: Any]] = []
        var newBlobs = binding.blobs

        for change in selected {
            switch change.status {
            case .deleted:
                entries.append(["path": change.path, "mode": "100644", "type": "blob", "sha": NSNull()])
                newBlobs[change.path] = nil
            case .added, .modified:
                let blob = try await client.createBlob(owner: binding.owner, repo: binding.repo, text: change.current)
                entries.append(["path": change.path, "mode": "100644", "type": "blob", "sha": blob])
                newBlobs[change.path] = blob
            }
        }

        let tree = try await client.createTree(
            owner: binding.owner,
            repo: binding.repo,
            baseTree: binding.baseTree,
            entries: entries
        )
        let commit = try await client.createCommit(
            owner: binding.owner,
            repo: binding.repo,
            message: message,
            tree: tree,
            parents: [binding.baseCommit]
        )
        try await client.updateRef(owner: binding.owner, repo: binding.repo, branch: binding.branch, sha: commit)

        var updated = binding
        updated.baseCommit = commit
        updated.baseTree = tree
        updated.blobs = newBlobs
        return updated
    }

    func baseText(binding: GitHubBinding, path: String) async throws -> String {
        guard let sha = binding.blobs[path] else { return "" }
        guard let token = GitHubClient.storedToken, !token.isEmpty else { throw GitHubError.notSignedIn }
        let client = GitHubClient(token: token)
        return try await client.blobText(owner: binding.owner, repo: binding.repo, sha: sha)
    }

    // MARK: SSH

    /// Mirrors a remote directory into the workspace folder and records the
    /// digests, so later writes know what the remote last looked like.
    func connectSSH(
        host: String,
        port: Int,
        username: String,
        remotePath: String,
        auth: SSHConnection.Auth,
        trustedFingerprint: String? = nil
    ) async throws -> (name: String, fingerprint: String, files: [String]) {
        let library = WorkspaceLibrary.load()
        let id = "ssh:\(username)@\(host):\(port)/\(remotePath)"
        let known = trustedFingerprint ?? library.sshEntry(id: id)?.fingerprint
        let connection = try await SSHConnection.open(
            host: host,
            port: port,
            username: username,
            auth: auth,
            knownFingerprint: known
        )

        let listing = try await connection.run(
            "cd \(Self.quote(remotePath)) || exit 9; find . -type f -size -400k 2>/dev/null | sed 's|^\\./||' | head -2500"
        )
        guard listing.succeeded else {
            await connection.close()
            throw SSHError.commandFailed(listing.combined)
        }

        let paths = listing.stdout
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { path in
                !path.isEmpty && !path.split(separator: "/").contains { WorkspaceContent.ignoredDirectoryNames.contains(String($0)) }
            }

        let folder = WorkspaceStorage.workspaceDirectory(for: id)
        try WorkspaceStorage.ensureDirectory(folder)

        let contents = try await readRemote(paths: paths, remotePath: remotePath, connection: connection)
        var mirror: WorkspaceLibrary.Mirror = [:]
        for (path, text) in contents {
            guard let text, WorkspaceContent.isLikelyTextPath(path) else { continue }
            try? WorkspaceStorage.write(text, to: folder.appendingPathComponent(path))
            mirror[path] = WorkspaceStorage.digest(text)
        }
        WorkspaceLibrary.saveMirror(mirror, id: id)

        sessions[id] = connection
        let name = (remotePath as NSString).lastPathComponent
        return (name.isEmpty ? host : name, connection.fingerprint, Array(mirror.keys).sorted())
    }

    /// Runs a command on an already-connected SSH workspace, for the terminal
    /// sheet, the task runner and ports.
    func sshRun(workspaceID: String, command: String, onChunk: @MainActor @escaping (String, Bool) -> Void) async throws -> SSHConnection.CommandResult {
        guard let connection = sessions[workspaceID] else {
            throw SSHError.transport("The SSH session was closed. Reconnect from Connections.")
        }
        return try await connection.runStreaming(command, onChunk: onChunk)
    }

    func sshConnection(workspaceID: String) -> SSHConnection? { sessions[workspaceID] }

    /// Re-opens a cached session that was dropped (relaunch, network change)
    /// before the terminal or a task runs on it.
    func ensureSSHSession(workspaceID: String, binding: SSHBinding) async throws {
        _ = try await requireSession(workspaceID: workspaceID, binding: binding)
    }

    /// One cheap round trip, for the connection pill.
    func sshLatency(workspaceID: String, binding: SSHBinding) async throws -> Int {
        let connection = try await requireSession(workspaceID: workspaceID, binding: binding)
        return try await connection.latencyProbe()
    }

    /// Opens a long-lived remote process (a language server) on a workspace.
    func sshStream(
        workspaceID: String,
        binding: SSHBinding,
        command: String,
        onOutput: @MainActor @escaping (String, Bool) -> Void
    ) async throws -> SSHConnection.StreamHandle {
        let connection = try await requireSession(workspaceID: workspaceID, binding: binding)
        return try await connection.openStream(command, onOutput: onOutput)
    }

    func githubLatency(owner: String, repo: String, branch: String) async throws -> Int {
        guard let token = GitHubClient.storedToken, !token.isEmpty else { throw GitHubError.notSignedIn }
        let started = Date()
        _ = try await GitHubClient(token: token).head(owner: owner, repo: repo, branch: branch)
        return max(Int(Date().timeIntervalSince(started) * 1000), 1)
    }

    func disconnectSSH(workspaceID: String) async {
        guard let connection = sessions.removeValue(forKey: workspaceID) else { return }
        await connection.close()
    }

    /// Pulls whatever changed on the host since the last mirror into the folder.
    func pullSSH(workspaceID: String, binding: SSHBinding) async throws -> [PendingChange] {
        let connection = try await requireSession(workspaceID: workspaceID, binding: binding)
        let mirror = WorkspaceLibrary.mirror(id: workspaceID)
        let folder = WorkspaceStorage.workspaceDirectory(for: workspaceID)

        let listing = try await connection.run(
            "cd \(Self.quote(binding.remotePath)) || exit 9; find . -type f -size -400k 2>/dev/null | sed 's|^\\./||' | head -2500"
        )
        let paths = listing.stdout
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { path in
                !path.isEmpty && !path.split(separator: "/").contains { WorkspaceContent.ignoredDirectoryNames.contains(String($0)) }
            }

        var conflicts: [PendingChange] = []
        var updatedMirror = mirror
        let contents = try await readRemote(paths: paths, remotePath: binding.remotePath, connection: connection)

        for (path, text) in contents {
            guard let text, WorkspaceContent.isLikelyTextPath(path) else { continue }
            let local = WorkspaceStorage.readText(folder.appendingPathComponent(path))
            let remoteDigest = WorkspaceStorage.digest(text)
            if let local, let mirroredDigest = mirror[path], WorkspaceStorage.digest(local) != mirroredDigest {
                // Edited here and on the host: never overwrite the device's copy.
                conflicts.append(PendingChange(path: path, status: .modified, current: local, baseSHA: nil, mirrored: text))
                updatedMirror[path] = remoteDigest
                continue
            }
            try? WorkspaceStorage.write(text, to: folder.appendingPathComponent(path))
            updatedMirror[path] = remoteDigest
        }

        WorkspaceLibrary.saveMirror(updatedMirror, id: workspaceID)
        return conflicts
    }

    /// Files whose local text no longer matches the last mirror.
    func localSSHChanges(workspaceID: String) -> [PendingChange] {
        let folder = WorkspaceStorage.workspaceDirectory(for: workspaceID)
        let mirror = WorkspaceLibrary.mirror(id: workspaceID)
        var changes: [PendingChange] = []

        let localPaths = WorkspaceStorage.textFiles(under: folder)
        let localSet = Set(localPaths)

        for path in localPaths {
            guard let current = WorkspaceStorage.readText(folder.appendingPathComponent(path)) else { continue }
            guard let mirroredDigest = mirror[path] else {
                changes.append(PendingChange(path: path, status: .added, current: current, baseSHA: nil, mirrored: ""))
                continue
            }
            if WorkspaceStorage.digest(current) != mirroredDigest {
                changes.append(PendingChange(path: path, status: .modified, current: current, baseSHA: nil, mirrored: nil))
            }
        }
        for (path, _) in mirror where !localSet.contains(path) {
            changes.append(PendingChange(path: path, status: .deleted, current: "", baseSHA: nil, mirrored: nil))
        }
        return changes.sorted { $0.path < $1.path }
    }

    /// Writes edited files back to the host so the mirror stays truthful.
    func pushSSH(workspaceID: String, binding: SSHBinding, paths: [String]) async throws -> Int {
        let connection = try await requireSession(workspaceID: workspaceID, binding: binding)
        let folder = WorkspaceStorage.workspaceDirectory(for: workspaceID)
        var mirror = WorkspaceLibrary.mirror(id: workspaceID)
        var pushed = 0

        for path in paths {
            let localURL = folder.appendingPathComponent(path)
            let target = binding.remotePath.hasSuffix("/")
                ? binding.remotePath + path
                : binding.remotePath + "/" + path

            if let text = WorkspaceStorage.readText(localURL) {
                let encoded = Data(text.utf8).base64EncodedString()
                let result = try await connection.run(
                    "mkdir -p \"$(dirname \(Self.quote(target)))\" && printf %s \(Self.quote(encoded)) | base64 -d > \(Self.quote(target + ".ide-tmp")) && mv \(Self.quote(target + ".ide-tmp")) \(Self.quote(target))"
                )
                guard result.succeeded else { throw SSHError.commandFailed(result.combined) }
                mirror[path] = WorkspaceStorage.digest(text)
                pushed += 1
            } else {
                let result = try await connection.run("rm -f \(Self.quote(target))")
                guard result.succeeded else { throw SSHError.commandFailed(result.combined) }
                mirror[path] = nil
                pushed += 1
            }
        }

        WorkspaceLibrary.saveMirror(mirror, id: workspaceID)
        return pushed
    }

    /// Reads host-side Git changes and local mirror edits without sending files.
    /// The explicit commit action is the only Git-screen path that pushes edits.
    func sshGitStatus(binding: SSHBinding, workspaceID: String) async throws -> [PendingChange] {
        let pendingLocal = localSSHChanges(workspaceID: workspaceID)
        let connection = try await requireSession(workspaceID: workspaceID, binding: binding)
        let status = try await connection.run("cd \(Self.quote(binding.remotePath)) && git status --porcelain 2>/dev/null")
        guard status.succeeded else { throw SSHError.commandFailed(status.combined) }

        var remoteChanges: [PendingChange] = []
        for line in status.stdout.components(separatedBy: .newlines) where line.count > 3 {
            let code = String(line.prefix(2))
            var path = String(line.dropFirst(3))
            if let arrow = path.range(of: " -> ") {
                path = String(path[arrow.upperBound...])
            }
            let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let changeStatus: PendingChange.Status
            if code.contains("D") {
                changeStatus = .deleted
            } else if code.contains("A") || code.contains("?") {
                changeStatus = .added
            } else {
                changeStatus = .modified
            }

            let current = try await connection.run(
                "cd \(Self.quote(binding.remotePath)) && cat \(Self.quote(trimmedPath)) 2>/dev/null | base64 | tr -d '\\n'"
            )
            let text = Data(base64Encoded: current.stdout.trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { String(data: $0, encoding: .utf8) }
            let base = changeStatus == .added
                ? ""
                : (try await remoteGitText(connection: connection, remotePath: binding.remotePath, path: trimmedPath) ?? "")
            remoteChanges.append(
                PendingChange(
                    path: trimmedPath,
                    status: changeStatus,
                    current: text ?? "",
                    baseSHA: nil,
                    mirrored: base
                )
            )
        }

        let localPaths = Set(pendingLocal.map(\.path))
        let remotePaths = Set(remoteChanges.map(\.path))
        let overlapping = localPaths.intersection(remotePaths).sorted()
        guard overlapping.isEmpty else {
            throw SSHError.transport(
                "These files changed on both this device and the host: \(overlapping.joined(separator: ", ")). Pull from the host before committing."
            )
        }

        var changes = remoteChanges
        for change in pendingLocal {
            let base = change.status == .added
                ? ""
                : (try await remoteGitText(connection: connection, remotePath: binding.remotePath, path: change.path) ?? "")
            changes.append(
                PendingChange(
                    path: change.path,
                    status: change.status,
                    current: change.current,
                    baseSHA: nil,
                    mirrored: base
                )
            )
        }
        return changes.sorted { $0.path < $1.path }
    }

    func sshGitCommit(binding: SSHBinding, workspaceID: String, message: String, paths: [String]) async throws -> String {
        let connection = try await requireSession(workspaceID: workspaceID, binding: binding)
        // Send any edit that has not reached the host yet, so the commit
        // contains what the editor shows.
        let selectedPaths = Set(paths)
        let pendingLocal = localSSHChanges(workspaceID: workspaceID)
            .filter { selectedPaths.contains($0.path) }
        if !pendingLocal.isEmpty {
            _ = try await pushSSH(workspaceID: workspaceID, binding: binding, paths: pendingLocal.map(\.path))
        }
        let quotedPaths = paths.map(Self.quote).joined(separator: " ")
        let commit = try await connection.run(
            "cd \(Self.quote(binding.remotePath)) && git add -A \(quotedPaths) && git -c user.name=\"iDE\" -c user.email=\"ide@localhost\" commit -m \(Self.quote(message)) && git push --porcelain 2>&1"
        )
        guard commit.succeeded else { throw SSHError.commandFailed(commit.combined) }
        return commit.combined
    }

    // MARK: SSH plumbing

    private func remoteGitText(connection: SSHConnection, remotePath: String, path: String) async throws -> String? {
        let result = try await connection.run(
            "cd \(Self.quote(remotePath)) && git show \(Self.quote("HEAD:\(path)")) 2>/dev/null | base64 | tr -d '\\n'"
        )
        guard result.succeeded else { return nil }
        let encoded = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return Data(base64Encoded: encoded).flatMap { String(data: $0, encoding: .utf8) }
    }

    private func requireSession(workspaceID: String, binding: SSHBinding) async throws -> SSHConnection {
        if let connection = sessions[workspaceID] { return connection }
        let library = WorkspaceLibrary.load()
        guard let entry = library.sshEntry(id: workspaceID) else {
            throw SSHError.transport("This SSH workspace is no longer in the library.")
        }
        guard let auth = Self.storedSSHAuth() else {
            throw SSHError.transport("No SSH credential is stored. Add one in Connections.")
        }
        let connection = try await SSHConnection.open(
            host: entry.host,
            port: entry.port,
            username: entry.username,
            auth: auth,
            knownFingerprint: entry.fingerprint
        )
        sessions[workspaceID] = connection
        return connection
    }

    /// The app keeps one SSH credential. Multiple hosts are supported; multiple
    /// keys are a later, deliberate step.
    static func storedSSHAuth() -> SSHConnection.Auth? {
        if let key = KeychainStore.read(KeychainStore.sshKeyAccount), !key.isEmpty {
            return .privateKey(key)
        }
        if let password = KeychainStore.read(KeychainStore.sshPasswordAccount), !password.isEmpty {
            return .password(password)
        }
        return nil
    }

    private func readRemote(
        paths: [String],
        remotePath: String,
        connection: SSHConnection
    ) async throws -> [(String, String?)] {
        var results: [(String, String?)] = []
        for batch in paths.chunked(into: 12) {
            let commands = batch.map { "base64 < \(Self.quote($0)) 2>/dev/null | tr -d '\\n'" }.joined(separator: "; echo; ")
            let result = try await connection.run("cd \(Self.quote(remotePath)) && ( \(commands) )")
            let lines = result.stdout.components(separatedBy: "\n")
            for (index, path) in batch.enumerated() {
                let encoded = index < lines.count ? lines[index].trimmingCharacters(in: .whitespaces) : ""
                guard let data = Data(base64Encoded: encoded), let text = String(data: data, encoding: .utf8) else {
                    results.append((path, nil))
                    continue
                }
                results.append((path, text))
            }
        }
        return results
    }

    private static func isSafeRelativePath(_ path: String) -> Bool {
        guard !path.isEmpty, !path.hasPrefix("/") else { return false }
        return path.split(separator: "/", omittingEmptySubsequences: false)
            .allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }

    /// Single-quoted shell literal. Safe for every path we allow.
    static func quote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
