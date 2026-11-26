import Foundation

/// GitHub REST client — the git *data* endpoints only, which is what lets the
/// app clone, diff and commit without libgit2 (build plan Phase 3).
///
/// Auth is a personal access token in the Keychain. The device flow was left out
/// on purpose: it needs a registered OAuth app, which is a release-time detail.
actor GitHubClient {
    static let baseURL = URL(string: "https://api.github.com")!

    private let token: String
    private let session: URLSession

    init(token: String) {
        self.token = token
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        configuration.httpAdditionalHeaders = ["Accept": "application/vnd.github+json"]
        self.session = URLSession(configuration: configuration)
    }

    static var storedToken: String? { KeychainStore.read(KeychainStore.githubTokenAccount) }
    static var isSignedIn: Bool { (storedToken?.isEmpty == false) }

    // MARK: Transport

    private func send(
        _ path: String,
        method: String = "GET",
        body: Any? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: path, relativeTo: Self.baseURL) else {
            throw GitHubError.transport("That API path is not valid.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw GitHubError.transport("GitHub sent an unreadable response.")
            }
            guard (200..<300).contains(http.statusCode) else {
                let message = (try? JSONDecoder().decode(APIError.self, from: data))?.message
                throw GitHubError.http(status: http.statusCode, message: message ?? "")
            }
            return (data, http)
        } catch let error as GitHubError {
            throw error
        } catch {
            throw GitHubError.transport(error.localizedDescription)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from path: String, method: String = "GET", body: Any? = nil) async throws -> T {
        let (data, _) = try await send(path, method: method, body: body)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw GitHubError.transport("GitHub's reply did not match what this app expects.")
        }
    }

    // MARK: Identity

    func currentUser() async throws -> String {
        let user: User = try await decode(User.self, from: "/user")
        return user.login
    }

    func repository(owner: String, repo: String) async throws -> RepositorySummary {
        try await decode(RepositorySummary.self, from: "/repos/\(owner)/\(repo)")
    }

    /// Cheapest call available: one repo lookup, used for the latency pill.
    func ping(owner: String, repo: String) async throws -> Int {
        _ = try await send("/repos/\(owner)/\(repo)/branches/\(try encodeBranch(await repository(owner: owner, repo: repo).defaultBranch))")
        return 0
    }

    private func encodeBranch(_ branch: String) throws -> String {
        guard let encoded = branch.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw GitHubError.transport("That branch name cannot be requested.")
        }
        return encoded
    }

    // MARK: Git data — read

    func head(owner: String, repo: String, branch: String) async throws -> BranchHead {
        try await decode(BranchHead.self, from: "/repos/\(owner)/\(repo)/branches/\(try encodeBranch(branch))")
    }

    func tree(owner: String, repo: String, sha: String) async throws -> [TreeEntry] {
        let reply: TreeReply = try await decode(TreeReply.self, from: "/repos/\(owner)/\(repo)/git/trees/\(sha)?recursive=1")
        return reply.tree
    }

    /// Blob contents, base64-decoded. GitHub wraps encoded text at 60 columns,
    /// which `Data(base64Encoded:options:.ignoreUnknownCharacters)` tolerates.
    func blobText(owner: String, repo: String, sha: String) async throws -> String {
        let blob: BlobReply = try await decode(BlobReply.self, from: "/repos/\(owner)/\(repo)/git/blobs/\(sha)")
        guard let data = Data(base64Encoded: blob.content, options: .ignoreUnknownCharacters) else {
            throw GitHubError.transport("A file in this repository could not be decoded.")
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw GitHubError.notText
        }
        return text
    }

    // MARK: Git data — write

    func createBlob(owner: String, repo: String, text: String) async throws -> String {
        let reply: SHAOnly = try await decode(
            SHAOnly.self,
            from: "/repos/\(owner)/\(repo)/git/blobs",
            method: "POST",
            body: ["content": text, "encoding": "utf-8"]
        )
        return reply.sha
    }

    func createTree(owner: String, repo: String, baseTree: String?, entries: [[String: Any]]) async throws -> String {
        var body: [String: Any] = ["tree": entries]
        if let baseTree { body["base_tree"] = baseTree }
        let reply: SHAOnly = try await decode(
            SHAOnly.self,
            from: "/repos/\(owner)/\(repo)/git/trees",
            method: "POST",
            body: body
        )
        return reply.sha
    }

    func createCommit(
        owner: String,
        repo: String,
        message: String,
        tree: String,
        parents: [String]
    ) async throws -> String {
        let reply: SHAOnly = try await decode(
            SHAOnly.self,
            from: "/repos/\(owner)/\(repo)/git/commits",
            method: "POST",
            body: ["message": message, "tree": tree, "parents": parents]
        )
        return reply.sha
    }

    /// Fast-forward the branch. `force: false` makes GitHub reject the update if
    /// the branch moved while this device was editing, which is exactly the
    /// "push rejected — pull first" state the design asks for.
    func updateRef(owner: String, repo: String, branch: String, sha: String) async throws {
        _ = try await send(
            "/repos/\(owner)/\(repo)/git/refs/heads/\(try encodeBranch(branch))",
            method: "PATCH",
            body: ["sha": sha, "force": false]
        )
    }

    // MARK: Wire types

    private struct APIError: Decodable { let message: String }
    private struct User: Decodable { let login: String }
    private struct SHAOnly: Decodable { let sha: String }

    struct RepositorySummary: Decodable {
        let defaultBranch: String
        let privateRepo: Bool

        enum CodingKeys: String, CodingKey {
            case defaultBranch = "default_branch"
            case privateRepo = "private"
        }
    }

    struct BranchHead: Decodable {
        let commit: Commit

        struct Commit: Decodable {
            let sha: String
            let commit: Inner

            struct Inner: Decodable { let tree: Tree }
            struct Tree: Decodable { let sha: String }
        }

        var commitSHA: String { commit.sha }
        var treeSHA: String { commit.commit.tree.sha }
    }

    struct TreeEntry: Decodable {
        let path: String
        let mode: String
        let type: String
        let sha: String
        let size: Int?
    }

    private struct TreeReply: Decodable {
        let tree: [TreeEntry]
    }

    private struct BlobReply: Decodable {
        let content: String
        let encoding: String
    }
}

enum GitHubError: LocalizedError {
    case notSignedIn
    case transport(String)
    case notText
    case http(status: Int, message: String)
    case emptyChange
    case remoteMoved

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Add a GitHub token in Connections first."
        case .transport(let message):
            return message
        case .notText:
            return "That file is not UTF-8 text, so it is not mirrored on device."
        case .http(let status, let message):
            switch status {
            case 401: return "GitHub rejected the token (401). It may have expired or lost scope."
            case 403: return message.isEmpty ? "GitHub refused this request (403). Rate limit or missing scope." : "GitHub refused this request: \(message)"
            case 404: return message.isEmpty ? "GitHub could not find that repository or branch (404)." : message
            case 409: return "The branch moved on GitHub. Pull before pushing again."
            case 422: return message.isEmpty ? "GitHub rejected the update (422). Pull before pushing again." : message
            default: return "GitHub returned \(status). \(message)"
            }
        case .emptyChange:
            return "There is nothing to commit."
        case .remoteMoved:
            return "The branch moved on GitHub since the last pull. Pull before pushing again."
        }
    }
}
