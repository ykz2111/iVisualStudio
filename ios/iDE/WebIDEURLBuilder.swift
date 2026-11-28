import Foundation

enum WebIDEURLBuilder {
    static func codespaces(for binding: GitHubBinding) -> URL? {
        codespaces(owner: binding.owner, repo: binding.repo, branch: binding.branch)
    }

    static func codespaces(owner: String, repo: String, branch: String) -> URL? {
        guard let encodedOwner = encodePath(owner, preservingSlashes: false),
              let encodedRepo = encodePath(repo, preservingSlashes: false),
              let encodedBranch = encodePath(branch, preservingSlashes: true) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "codespaces.new"
        let branchPath = branch.isEmpty ? "" : "/tree/\(encodedBranch)"
        components.percentEncodedPath = "/\(encodedOwner)/\(encodedRepo)\(branchPath)"
        components.queryItems = [URLQueryItem(name: "quickstart", value: "1")]
        return components.url
    }

    static func gitLab(projectURL: String, branch: String) -> URL? {
        var value = projectURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if !value.contains("://") {
            value = value.lowercased().hasPrefix("gitlab.com/")
                ? "https://\(value)"
                : "https://gitlab.com/\(value)"
        }

        guard var components = URLComponents(string: value),
              components.scheme?.lowercased() == "https",
              components.host != nil,
              components.user == nil,
              components.password == nil else {
            return nil
        }

        var rawProjectPath = components.percentEncodedPath
        if let separator = rawProjectPath.range(of: "/-/"), separator.lowerBound != rawProjectPath.startIndex {
            rawProjectPath = String(rawProjectPath[..<separator.lowerBound])
        }
        let rawSegments = rawProjectPath.split(separator: "/", omittingEmptySubsequences: true)
        let projectSegments = rawSegments.compactMap { String($0).removingPercentEncoding }
        guard projectSegments.count == rawSegments.count,
              projectSegments.count >= 2,
              !projectSegments.contains("."),
              !projectSegments.contains("..") else {
            return nil
        }

        var normalizedSegments = projectSegments
        if normalizedSegments[normalizedSegments.count - 1].hasSuffix(".git") {
            normalizedSegments[normalizedSegments.count - 1].removeLast(4)
        }
        guard normalizedSegments.allSatisfy({ !$0.isEmpty }),
              let encodedProject = encodePath(normalizedSegments.joined(separator: "/"), preservingSlashes: true) else {
            return nil
        }

        let trimmedBranch = branch.trimmingCharacters(in: .whitespacesAndNewlines)
        let idePath: String
        if trimmedBranch.isEmpty {
            idePath = "/-/ide/project/\(encodedProject)/edit"
        } else {
            guard let encodedBranch = encodePath(trimmedBranch, preservingSlashes: true) else { return nil }
            idePath = "/-/ide/project/\(encodedProject)/edit/\(encodedBranch)/-/"
        }

        components.percentEncodedPath = idePath
        components.query = nil
        components.fragment = nil
        return components.url
    }

    private static func encodePath(_ value: String, preservingSlashes: Bool) -> String? {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: preservingSlashes ? "?#%" : "/?#%")
        return value.addingPercentEncoding(withAllowedCharacters: allowed)
    }
}
