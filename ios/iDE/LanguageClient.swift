import Foundation
import SwiftUI

/// A minimal LSP client over the existing SSH session (build plan Phase 5).
/// It reuses the *remote* language server — no language stack is built here —
/// and it is deliberately small: initialize, didOpen, completions, definition,
/// publishDiagnostics. Anything more waits until these four are boring.
@MainActor
final class LanguageClient: ObservableObject {
    enum Status: Equatable {
        case stopped
        case starting
        case ready(String)
        case failed(String)
    }

    struct Diagnostic: Identifiable, Hashable {
        enum Severity: Int, Hashable {
            case error = 1
            case warning = 2
            case information = 3
            case hint = 4
        }

        let id = UUID()
        let message: String
        let severity: Severity
        let line: Int
        let path: String

        var color: Color {
            switch severity {
            case .error: return IDETheme.coral
            case .warning: return IDETheme.amber
            case .information, .hint: return IDETheme.muted
            }
        }
    }

    struct Completion: Identifiable, Hashable {
        let id = UUID()
        let label: String
        let detail: String
        let insertText: String
    }

    @Published private(set) var status: Status = .stopped
    @Published private(set) var diagnostics: [Diagnostic] = []

    private var stream: SSHConnection.StreamHandle?
    private var buffer = Data()
    private var nextID = 1
    private var pending: [Int: (Result<Any, Error>) -> Void] = [:]
    private var openPath: String?
    private var openVersion = 0
    private var rootPath = ""
    private var workspaceID = ""

    static let commandKey = "ide.lsp.command"

    // MARK: Lifecycle

    func start(workspace: Workspace, relativePath: String) async {
        guard let ssh = workspace.ssh else {
            status = .failed("The language server needs an SSH workspace in v1.")
            return
        }
        let languageID = LanguageClient.languageID(for: relativePath)
        let command = LanguageClient.command(for: languageID)
        guard let command else {
            status = .failed("No remote language server is configured for .\(URL(fileURLWithPath: relativePath).pathExtension). Set one in Settings.")
            return
        }
        if case .ready = status, workspaceID == workspace.id { return }

        status = .starting
        workspaceID = workspace.id
        rootPath = ssh.remotePath
        do {
            let handle = try await WorkspaceSync.shared.sshStream(
                workspaceID: workspace.id,
                binding: ssh,
                command: "cd \(WorkspaceSync.quote(ssh.remotePath)) && \(command)"
            ) { [weak self] chunk, isError in
                self?.ingest(chunk, isError: isError)
            }
            stream = handle
            try await request("initialize", params: [
                "processId": NSNull(),
                "rootUri": Self.uri(rootPath),
                "capabilities": [
                    "textDocument": [
                        "completion": ["completionItem": ["snippetSupport": false]],
                        "publishDiagnostics": ["relatedInformation": false]
                    ]
                ]
            ])
            try await notify("initialized", params: [:])
            status = .ready(command)
        } catch {
            status = .failed(error.localizedDescription)
            await stop()
        }
    }

    func stop() async {
        guard let stream else {
            status = .stopped
            return
        }
        self.stream = nil
        await stream.close()
        status = .stopped
        diagnostics = []
        pending.values.forEach { $0(.failure(LanguageClientError.stopped)) }
        pending.removeAll()
    }

    // MARK: Document sync

    func openDocument(path: String, text: String) async {
        guard stream != nil else { return }
        if openPath == path {
            openVersion += 1
            try? await notify("textDocument/didChange", params: [
                "textDocument": ["uri": Self.uri(absolute(path)), "version": openVersion],
                "contentChanges": [["text": text]]
            ])
            return
        }
        openPath = path
        openVersion = 1
        try? await notify("textDocument/didOpen", params: [
            "textDocument": [
                "uri": Self.uri(absolute(path)),
                "languageId": Self.languageID(for: path),
                "version": openVersion,
                "text": text
            ]
        ])
    }

    func closeDocument() async {
        guard let openPath, stream != nil else { return }
        self.openPath = nil
        try? await notify("textDocument/didClose", params: [
            "textDocument": ["uri": Self.uri(absolute(openPath))]
        ])
    }

    // MARK: Requests

    func completions(line: Int, character: Int) async throws -> [Completion] {
        guard let openPath, stream != nil else { return [] }
        let result = try await request("textDocument/completion", params: [
            "textDocument": ["uri": Self.uri(absolute(openPath))],
            "position": ["line": line, "character": character]
        ])

        let items: [Any]
        if let dictionary = result as? [String: Any], let list = dictionary["items"] as? [Any] {
            items = list
        } else if let list = result as? [Any] {
            items = list
        } else {
            items = []
        }

        return items.compactMap { raw in
            guard let item = raw as? [String: Any], let label = item["label"] as? String else { return nil }
            let insert = (item["insertText"] as? String) ?? (item["textEdit"] as? [String: Any])?["newText"] as? String ?? label
            let detail = (item["detail"] as? String) ?? (item["kind"].map { Self.completionKind($0) } ?? "")
            return Completion(label: label, detail: detail, insertText: insert)
        }
    }

    func definition(line: Int, character: Int) async throws -> (path: String, line: Int)? {
        guard let openPath, stream != nil else { return nil }
        let result = try await request("textDocument/definition", params: [
            "textDocument": ["uri": Self.uri(absolute(openPath))],
            "position": ["line": line, "character": character]
        ])
        let location: [String: Any]?
        if let list = result as? [Any] {
            location = list.first as? [String: Any]
        } else {
            location = result as? [String: Any]
        }
        guard let location,
              let uri = location["uri"] as? String,
              let range = location["range"] as? [String: Any],
              let start = range["start"] as? [String: Any],
              let lineNumber = start["line"] as? Int,
              let path = Self.path(fromURI: uri) else { return nil }
        return (path, lineNumber + 1)
    }

    // MARK: JSON-RPC

    private func request(_ method: String, params: Any) async throws -> Any {
        guard let stream else { throw LanguageClientError.stopped }
        let id = nextID
        nextID += 1

        let payload = try Self.encode(["jsonrpc": "2.0", "id": id, "method": method, "params": params])
        let result: Any = try await withCheckedThrowingContinuation { continuation in
            pending[id] = { continuation.resume(with: $0) }
            Task { [weak self] in
                await self?.stream?.write(payload)
            }
            // Watchdog: a server that dies mid-request must not hang the sheet.
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(25))
                guard let resume = self?.pending.removeValue(forKey: id) else { return }
                resume(.failure(LanguageClientError.server("The language server did not answer within 25 seconds.")))
            }
        }
        return result
    }

    private func notify(_ method: String, params: Any) async throws {
        guard let stream else { throw LanguageClientError.stopped }
        let payload = try Self.encode(["jsonrpc": "2.0", "method": method, "params": params])
        await stream.write(payload)
    }

    private func ingest(_ chunk: String, isError: Bool) {
        guard !isError else {
            if case .starting = status {
                status = .failed(chunk.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return
        }
        buffer.append(Data(chunk.utf8))
        while let message = Self.nextMessage(from: &buffer) {
            handle(message)
        }
    }

    private func handle(_ data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let id = object["id"] as? Int, let resume = pending.removeValue(forKey: id) {
            if let error = object["error"] as? [String: Any] {
                resume(.failure(LanguageClientError.server(error["message"] as? String ?? "The language server rejected the request.")))
            } else {
                resume(.success(object["result"] ?? NSNull()))
            }
            return
        }

        guard let method = object["method"] as? String else { return }
        if method == "textDocument/publishDiagnostics",
           let params = object["params"] as? [String: Any],
           let uri = params["uri"] as? String,
           let path = Self.path(fromURI: uri) {
            let rawDiagnostics = params["diagnostics"] as? [[String: Any]] ?? []
            diagnostics = rawDiagnostics.compactMap { entry in
                guard let message = entry["message"] as? String,
                      let range = entry["range"] as? [String: Any],
                      let start = range["start"] as? [String: Any] else { return nil }
                let severity = Diagnostic.Severity(rawValue: entry["severity"] as? Int ?? 3) ?? .information
                return Diagnostic(
                    message: message,
                    severity: severity,
                    line: (start["line"] as? Int ?? 0) + 1,
                    path: path
                )
            }
        }

        // Answer server → client requests with an empty result rather than
        // leaving them hanging, which stalls some servers.
        if let id = object["id"] as? Int {
            let reply = "{\"jsonrpc\":\"2.0\",\"id\":\(id),\"result\":null}"
            Task { await stream?.write(reply) }
        }
    }

    private func absolute(_ relative: String) -> String {
        rootPath.hasSuffix("/") ? rootPath + relative : rootPath + "/" + relative
    }

    // MARK: Static helpers

    static func languageID(for path: String) -> String {
        switch URL(fileURLWithPath: path).pathExtension.lowercased() {
        case "swift": return "swift"
        case "ts", "tsx": return "typescript"
        case "js", "jsx", "mjs", "cjs": return "javascript"
        case "py": return "python"
        case "rs": return "rust"
        case "go": return "go"
        case "c", "h": return "c"
        case "cpp", "cc", "hpp", "mm": return "cpp"
        case "kt": return "kotlin"
        case "rb": return "ruby"
        case "java": return "java"
        default: return "plaintext"
        }
    }

    static func command(for languageID: String) -> String? {
        let override = UserDefaults.standard.string(forKey: commandKey) ?? ""
        if !override.trimmingCharacters(in: .whitespaces).isEmpty { return override }

        switch languageID {
        case "swift": return "sourcekit-lsp"
        case "typescript", "javascript": return "typescript-language-server --stdio"
        case "python": return "pyright-langserver --stdio"
        case "rust": return "rust-analyzer"
        case "go": return "gopls serve"
        case "kotlin": return "kotlin-language-server"
        case "ruby": return "solargraph stdio"
        default: return nil
        }
    }

    private static func completionKind(_ raw: Any) -> String {
        switch raw as? Int ?? 0 {
        case 2, 3: return "function"
        case 4: return "field"
        case 5: return "variable"
        case 6: return "class"
        case 7: return "interface"
        case 8: return "module"
        case 9: return "property"
        case 13: return "enum"
        case 14: return "keyword"
        case 15: return "snippet"
        default: return ""
        }
    }

    static func uri(_ path: String) -> String {
        "file://" + path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "#?")))!
    }

    static func path(fromURI uri: String) -> String? {
        guard uri.hasPrefix("file://") else { return nil }
        return String(uri.dropFirst("file://".count)).removingPercentEncoding
    }

    private static func encode(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object)
        return "Content-Length: \(data.count)\r\n\r\n" + (String(data: data, encoding: .utf8) ?? "")
    }

    /// Pulls one `Content-Length` framed message out of the buffer.
    private static func nextMessage(from buffer: inout Data) -> Data? {
        let headerEnd = Data("\r\n\r\n".utf8)
        guard let range = buffer.range(of: headerEnd) else { return nil }
        let header = String(data: buffer[buffer.startIndex..<range.lowerBound], encoding: .utf8) ?? ""
        var length = 0
        for line in header.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, parts[0].lowercased() == "content-length" {
                length = Int(parts[1]) ?? 0
            }
        }
        guard length > 0 else {
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            return nil
        }
        let bodyStart = range.upperBound
        guard buffer.distance(from: bodyStart, to: buffer.endIndex) >= length else { return nil }
        let bodyEnd = buffer.index(bodyStart, offsetBy: length)
        let body = Data(buffer[bodyStart..<bodyEnd])
        buffer.removeSubrange(buffer.startIndex..<bodyEnd)
        return body
    }
}

enum LanguageClientError: LocalizedError {
    case stopped
    case server(String)

    var errorDescription: String? {
        switch self {
        case .stopped:
            return "The language server is not running."
        case .server(let message):
            return message
        }
    }
}

/// S11 · Diagnostics and completions, in one sheet. No popover over the caret:
/// it would occlude the line being edited (design plan §5).
struct LanguageSheet: View {
    @ObservedObject var client: LanguageClient
    let fileName: String
    let onInsert: (String) -> Void
    let onJump: (Int) -> Void
    let line: Int
    let column: Int

    @Environment(\.dismiss) private var dismiss
    @State private var completions: [LanguageClient.Completion] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 7, height: 7)
                        Text(statusText)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                            .lineLimit(2)
                    }
                    .listRowBackground(IDETheme.chassis)
                }

                if !completions.isEmpty {
                    Section {
                        ForEach(completions) { completion in
                            Button {
                                onInsert(completion.insertText)
                                Haptics.light()
                                dismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "text.insert")
                                        .font(.system(size: 13))
                                        .foregroundStyle(IDETheme.cyan)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(completion.label)
                                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                                            .foregroundStyle(IDETheme.primary)
                                        if !completion.detail.isEmpty {
                                            Text(completion.detail)
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
                            .buttonStyle(.plain)
                            .listRowBackground(IDETheme.chassis)
                        }
                    } header: {
                        eyebrow("COMPLETIONS · \(completions.count)")
                    }
                }

                if client.diagnostics.isEmpty {
                    Section {
                        Text("No diagnostics reported for this file.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(IDETheme.secondary)
                            .listRowBackground(IDETheme.chassis)
                    } header: {
                        eyebrow("DIAGNOSTICS")
                    }
                } else {
                    Section {
                        ForEach(client.diagnostics) { diagnostic in
                            Button {
                                onJump(diagnostic.line)
                                Haptics.light()
                                dismiss()
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Rectangle()
                                        .fill(diagnostic.color)
                                        .frame(width: 2)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(diagnostic.message)
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundStyle(IDETheme.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("line \(diagnostic.line)")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(IDETheme.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .frame(minHeight: IDETheme.recommendedHitTarget)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(IDETheme.chassis)
                        }
                    } header: {
                        eyebrow("DIAGNOSTICS · \(client.diagnostics.count)")
                    }
                }

                if let error {
                    Section {
                        Text(error)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(IDETheme.coral)
                            .listRowBackground(IDETheme.chassis)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(IDETheme.canvas)
            .navigationTitle(fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .frame(minHeight: IDETheme.minimumHitTarget)
                }
            }
            .task { await load() }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .tracking(0.7)
            .foregroundStyle(IDETheme.secondary)
            .textCase(nil)
    }

    private var statusText: String {
        switch client.status {
        case .stopped: return "SERVER STOPPED"
        case .starting: return "STARTING REMOTE LANGUAGE SERVER…"
        case .ready(let command): return "READY · \(command)"
        case .failed(let message): return message
        }
    }

    private var statusColor: Color {
        switch client.status {
        case .stopped: return IDETheme.muted
        case .starting: return IDETheme.azure
        case .ready: return IDETheme.emerald
        case .failed: return IDETheme.coral
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            completions = try await client.completions(line: max(line - 1, 0), character: max(column - 1, 0))
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// S12 · lpBOT. Selection-scoped only: it proposes, the user applies. No model
/// endpoint is bundled, so the assistant stays off until a key is configured.
struct AssistSheet: View {
    let selection: String
    let fileName: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("ide.assist.endpoint") private var endpoint = ""
    @AppStorage("ide.assist.model") private var model = ""

    @State private var instruction = "Explain this selection."
    @State private var proposal = ""
    @State private var isThinking = false
    @State private var error: String?

    private var configured: Bool { !endpoint.isEmpty && !model.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: IDETheme.minimumGap * 2) {
                    Text(selection.isEmpty ? "Select some code first." : selection)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(IDETheme.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(IDETheme.chassis, in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10).strokeBorder(IDETheme.elevated, lineWidth: 1)
                        }

                    TextField("Instruction", text: $instruction, axis: .vertical)
                        .font(.system(size: 14, design: .monospaced))
                        .lineLimit(1...3)
                        .autocorrectionDisabled()
                        .padding(10)
                        .background(IDETheme.chassis, in: RoundedRectangle(cornerRadius: 10))

                    if !proposal.isEmpty {
                        Text(proposal)
                            .font(.system(size: 14))
                            .foregroundStyle(IDETheme.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(IDETheme.elevated, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .leading) {
                                Rectangle().fill(IDETheme.violet).frame(width: 2)
                            }
                    }

                    if let error {
                        Text(error)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(IDETheme.coral)
                    }

                    if !configured {
                        Text("Set a model endpoint and model name in Settings. The assistant only ever sees the selection.")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(IDETheme.muted)
                    }
                }
                .padding(IDETheme.pageGutter)
            }
            .background(IDETheme.canvas)
            .navigationTitle("lpBOT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .frame(minHeight: IDETheme.minimumHitTarget)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack(spacing: IDETheme.minimumGap) {
                    Button {
                        Task { await ask() }
                    } label: {
                        Text(isThinking ? "Thinking…" : "Ask")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: IDETheme.recommendedHitTarget)
                            .background(
                                proposal.isEmpty && canAsk ? IDETheme.emerald : IDETheme.elevated,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay {
                                if !proposal.isEmpty {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(IDETheme.secondary.opacity(0.18), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(proposal.isEmpty && canAsk ? IDETheme.oledBlack : IDETheme.primary)
                    .disabled(!canAsk)

                    Button {
                        onApply(proposal)
                        Haptics.success()
                        dismiss()
                    } label: {
                        Text("Apply")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 96, height: IDETheme.recommendedHitTarget)
                            .background(
                                proposal.isEmpty ? IDETheme.elevated : IDETheme.emerald,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(proposal.isEmpty ? IDETheme.muted : IDETheme.oledBlack)
                    .disabled(proposal.isEmpty)
                }
                .padding(.horizontal, IDETheme.pageGutter)
                .padding(.vertical, 8)
                .background(IDETheme.canvas)
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var canAsk: Bool {
        configured && !isThinking && !selection.isEmpty
            && !instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// OpenAI-compatible chat completions, because every host and every local
    /// runner speaks it. The selection is the only thing sent.
    private func ask() async {
        isThinking = true
        error = nil
        proposal = ""
        defer { isThinking = false }
        do {
            var base = endpoint.trimmingCharacters(in: .whitespaces)
            if !base.hasSuffix("/chat/completions") {
                if base.hasSuffix("/v1") { base += "/chat/completions" }
                else if base.hasSuffix("/") { base += "chat/completions" }
                else { base += "/v1/chat/completions" }
            }
            guard let url = URL(string: base) else {
                throw LanguageClientError.server("The model endpoint in Settings is not a valid URL.")
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let key = KeychainStore.read("assist.key"), !key.isEmpty {
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            }
            request.timeoutInterval = 90
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "model": model,
                "messages": [
                    ["role": "system", "content": "You are a code assistant inside a phone IDE. Answer in at most four sentences. Never rewrite the whole file; work only on the selection you are given."],
                    ["role": "user", "content": "File: \(fileName)\n\nSelection:\n\(selection)\n\n\(instruction)"]
                ],
                "temperature": 0.2
            ])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw LanguageClientError.server("The model endpoint returned an error.")
            }
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw LanguageClientError.server("The model reply could not be read.")
            }
            let message = (object["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any]
            guard let content = message?["content"] as? String else {
                throw LanguageClientError.server("The model returned no text.")
            }
            proposal = content.trimmingCharacters(in: .whitespacesAndNewlines)
            Haptics.success()
        } catch let failure {
            self.error = failure.localizedDescription
            Haptics.error()
        }
    }
}
