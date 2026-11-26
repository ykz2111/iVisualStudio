import Foundation

/// One line of a unified diff, before presentation.
struct DiffLine: Identifiable, Hashable {
    enum Kind: Hashable {
        case context
        case added
        case removed
    }

    let id = UUID()
    let kind: Kind
    let text: String

    var glyph: String {
        switch kind {
        case .context: return " "
        case .added: return "+"
        case .removed: return "−"
        }
    }
}

/// A displayed half-open range of changes. Hunk headers keep long files readable
/// on a phone — 40 lines of context is more than a screen can show.
struct DiffHunk: Identifiable, Hashable {
    let id = UUID()
    let header: String
    let lines: [DiffLine]
}

/// Line diff via the standard LCS table. Files are capped at 1 200 lines per side
/// before it runs, which keeps the table at ~1.4 M cells — a few MB on device —
/// and beyond that the caller shows a "too large to diff" state instead.
enum LineDiff {
    static let maximumLines = 1200
    static let contextLines = 3

    static func lines(in text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        var result = text.components(separatedBy: "\n")
        // A trailing newline yields a final empty component that is not a line.
        if result.last == "" { result.removeLast() }
        return result
    }

    static func between(old: String, new: String) -> [DiffLine]? {
        let a = lines(in: old)
        let b = lines(in: new)
        guard a.count <= maximumLines, b.count <= maximumLines else { return nil }
        guard !(a.isEmpty && b.isEmpty) else { return [] }

        // lcs[i][j] = LCS length of a[i...] and b[j...]
        var lcs = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        if !a.isEmpty && !b.isEmpty {
            for i in stride(from: a.count - 1, through: 0, by: -1) {
                for j in stride(from: b.count - 1, through: 0, by: -1) {
                    lcs[i][j] = a[i] == b[j]
                        ? lcs[i + 1][j + 1] + 1
                        : max(lcs[i + 1][j], lcs[i][j + 1])
                }
            }
        }

        var result: [DiffLine] = []
        result.reserveCapacity(max(a.count, b.count))
        var i = 0
        var j = 0
        while i < a.count && j < b.count {
            if a[i] == b[j] {
                result.append(DiffLine(kind: .context, text: a[i]))
                i += 1
                j += 1
            } else if lcs[i + 1][j] >= lcs[i][j + 1] {
                result.append(DiffLine(kind: .removed, text: a[i]))
                i += 1
            } else {
                result.append(DiffLine(kind: .added, text: b[j]))
                j += 1
            }
        }
        while i < a.count {
            result.append(DiffLine(kind: .removed, text: a[i]))
            i += 1
        }
        while j < b.count {
            result.append(DiffLine(kind: .added, text: b[j]))
            j += 1
        }
        return result
    }

    /// Groups a diff into hunks with `contextLines` of surrounding context.
    static func hunks(from diff: [DiffLine]) -> [DiffHunk] {
        let changed = diff.indices.filter { diff[$0].kind != .context }
        guard let first = changed.first, let last = changed.last else { return [] }

        // Merge changed indices that are within 2× context of each other.
        var ranges: [(Int, Int)] = []
        for index in changed {
            if let open = ranges.last, index - open.1 <= contextLines * 2 {
                ranges[ranges.count - 1] = (open.0, index)
            } else {
                ranges.append((index, index))
            }
        }

        var oldLine = 1
        var newLine = 1
        var lineNumbers = [(old: Int, new: Int)](repeating: (0, 0), count: diff.count)
        for index in diff.indices {
            lineNumbers[index] = (oldLine, newLine)
            switch diff[index].kind {
            case .context: oldLine += 1; newLine += 1
            case .removed: oldLine += 1
            case .added: newLine += 1
            }
        }

        return ranges.map { range in
            let start = max(range.0 - contextLines, 0)
            let end = min(range.1 + contextLines, diff.count - 1)
            let slice = Array(diff[start...end])
            let oldCount = slice.filter { $0.kind != .added }.count
            let newCount = slice.filter { $0.kind != .removed }.count
            let header = "@@ -\(lineNumbers[start].old),\(oldCount) +\(lineNumbers[start].new),\(newCount) @@"
            return DiffHunk(header: header, lines: slice)
        }
    }
}

/// A changed path in a workspace, with the two sides loaded for the diff view.
struct FileChange: Identifiable, Hashable {
    enum Status: String, Hashable {
        case added = "A"
        case modified = "M"
        case deleted = "D"

        var label: String { rawValue }

        var colorKey: String {
            switch self {
            case .added: return "emerald"
            case .modified: return "amber"
            case .deleted: return "coral"
            }
        }
    }

    let path: String
    let status: Status
    let original: String
    let current: String

    var id: String { path }
    var name: String { URL(fileURLWithPath: path).lastPathComponent }
    var directory: String {
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        return parent == "." ? "" : parent
    }
}
