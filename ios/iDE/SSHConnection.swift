import Crypto
import Foundation
import NIOCore
import NIOPosix
import NIOSSH

/// A live SSH session. swift-nio-ssh provides the transport; this type exposes
/// the small command surface the app needs: one-shot `exec` (collected), a
/// streaming variant for the terminal sheet, and the host-key fingerprint.
final class SSHConnection: @unchecked Sendable {
    struct CommandResult: Sendable {
        let exitStatus: Int
        let stdout: String
        let stderr: String

        var succeeded: Bool { exitStatus == 0 }
        var combined: String { stderr.isEmpty ? stdout : (stdout.isEmpty ? stderr : stdout + "\n" + stderr) }
    }

    enum Auth: Sendable {
        case password(String)
        /// Unencrypted OpenSSH ed25519 private key.
        case privateKey(String)
    }

    let host: String
    let port: Int
    let username: String
    let fingerprint: String

    private let group: MultiThreadedEventLoopGroup
    private let channel: Channel
    private let handler: NIOSSHHandler

    private init(
        host: String,
        port: Int,
        username: String,
        fingerprint: String,
        group: MultiThreadedEventLoopGroup,
        channel: Channel,
        handler: NIOSSHHandler
    ) {
        self.host = host
        self.port = port
        self.username = username
        self.fingerprint = fingerprint
        self.group = group
        self.channel = channel
        self.handler = handler
    }

    // MARK: Lifecycle

    /// Opens and authenticates a session. `knownFingerprint` pins the host key:
    /// pass nil on first use (the fingerprint is then reported so the caller can
    /// store it) and the stored value afterwards, so a changed key fails loudly.
    static func open(
        host: String,
        port: Int,
        username: String,
        auth: Auth,
        knownFingerprint: String?
    ) async throws -> SSHConnection {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let validator = HostKeyValidator(expected: knownFingerprint)
        let userAuth = UserAuthDelegate(username: username, auth: auth)

        let bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    let ssh = NIOSSHHandler(
                        role: .client(.init(userAuthDelegate: userAuth, serverAuthDelegate: validator)),
                        allocator: channel.allocator,
                        inboundChildChannelInitializer: nil
                    )
                    try channel.pipeline.syncOperations.addHandler(ssh)
                }
            }
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)

        do {
            let channel = try await bootstrap.connect(host: host, port: port).get()
            let sshHandler = try channel.pipeline.syncOperations.handler(type: NIOSSHHandler.self)
            let connection = SSHConnection(
                host: host,
                port: port,
                username: username,
                fingerprint: validator.observed ?? "unknown",
                group: group,
                channel: channel,
                handler: sshHandler
            )
            // Child channels buffer until auth completes, so a ping both proves
            // the credentials and gives the pill something to time.
            let probe = try await connection.run("true")
            guard probe.succeeded else {
                throw SSHError.commandFailed(probe.combined)
            }
            return connection
        } catch {
            try? await group.shutdownGracefully()
            throw SSHError.wrap(error, host: host)
        }
    }

    func close() async {
        try? await channel.close().get()
        try? await group.shutdownGracefully()
    }

    // MARK: Commands

    func run(_ command: String, stdin: String? = nil) async throws -> CommandResult {
        try await runStreaming(command, stdin: stdin) { _, _ in }
    }

    /// Runs `command` through the remote shell and reports output as it arrives.
    /// `onChunk` runs on the main actor so views can append directly.
    func runStreaming(
        _ command: String,
        stdin: String? = nil,
        onChunk: @MainActor @escaping (_ chunk: String, _ isStdErr: Bool) -> Void
    ) async throws -> CommandResult {
        let childPromise = channel.eventLoop.makePromise(of: Channel.self)
        self.handler.createChannel(childPromise) { childChannel, _ in
            childChannel.eventLoop.makeCompletedFuture {
                let exec = ExecHandler(
                    command: command,
                    stdin: stdin,
                    promise: childChannel.eventLoop.makePromise(of: CommandResult.self)
                ) { chunk, isError in
                    Task { @MainActor in onChunk(chunk, isError) }
                }
                try childChannel.pipeline.syncOperations.addHandler(exec)
            }
        }

        let child = try await childPromise.futureResult.get()
        let exec = try child.pipeline.syncOperations.handler(type: ExecHandler.self)
        let outcome = try await exec.result.get()
        try? await child.close().get()
        return outcome
    }

    /// One cheap round trip, for the connection pill.
    func latencyProbe() async throws -> Int {
        let started = Date()
        let result = try await run("true")
        guard result.succeeded else { throw SSHError.commandFailed(result.combined) }
        return max(Int(Date().timeIntervalSince(started) * 1000), 1)
    }

    /// Opens a long-lived `exec` channel that keeps stdin open, which is how a
    /// language server is spoken to. Returns once the channel is active; the
    /// handle closes when the child channel does.
    func openStream(
        _ command: String,
        onOutput: @MainActor @escaping (String, Bool) -> Void
    ) async throws -> StreamHandle {
        let childPromise = channel.eventLoop.makePromise(of: Channel.self)
        self.handler.createChannel(childPromise) { childChannel, _ in
            childChannel.eventLoop.makeCompletedFuture {
                try childChannel.pipeline.syncOperations.addHandler(
                    StreamHandler(command: command, promise: childChannel.eventLoop.makePromise(of: Int.self)) { chunk, isError in
                        Task { @MainActor in onOutput(chunk, isError) }
                    }
                )
            }
        }
        let child = try await childPromise.futureResult.get()
        let handler = try child.pipeline.syncOperations.handler(type: StreamHandler.self)
        return StreamHandle(channel: child, handler: handler)
    }

    final class StreamHandle: @unchecked Sendable {
        private let channel: Channel
        private let handler: StreamHandler

        init(channel: Channel, handler: StreamHandler) {
            self.channel = channel
            self.handler = handler
        }

        func write(_ text: String) async {
            _ = handler.write(text)
        }

        func close() async {
            _ = handler.closeInput()
            try? await channel.close().get()
        }
    }

    final class StreamHandler: ChannelDuplexHandler, @unchecked Sendable {
        typealias InboundIn = SSHChannelData
        typealias InboundOut = ByteBuffer
        typealias OutboundIn = ByteBuffer
        typealias OutboundOut = SSHChannelData

        private let command: String
        private let onChunk: @Sendable (String, Bool) -> Void
        private let exitPromise: EventLoopPromise<Int>

        init(command: String, promise: EventLoopPromise<Int>, onChunk: @escaping @Sendable (String, Bool) -> Void) {
            self.command = command
            self.exitPromise = promise
            self.onChunk = onChunk
        }

        func channelActive(context: ChannelHandlerContext) {
            let request = SSHChannelRequestEvent.ExecRequest(command: command, wantReply: false)
            context.triggerUserOutboundEvent(request).whenFailure { _ in }
        }

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let channelData = self.unwrapInboundIn(data)
            guard case .byteBuffer(let buffer) = channelData.data,
                  let text = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes),
                  !text.isEmpty else { return }
            onChunk(text, channelData.type == .stdErr)
        }

        func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
            if let status = event as? SSHChannelRequestEvent.ExitStatus {
                exitPromise.succeed(status.exitStatus)
            }
            context.fireUserInboundEventTriggered(event)
        }

        func channelInactive(context: ChannelHandlerContext) {
            exitPromise.succeed(0)
            context.fireChannelInactive()
        }

        @discardableResult
        func write(_ text: String) -> Bool {
            guard let context else { return false }
            var buffer = context.channel.allocator.buffer(capacity: text.utf8.count)
            buffer.writeString(text)
            context.write(self.wrapOutboundOut(SSHChannelData(type: .channel, data: .byteBuffer(buffer))), promise: nil)
            context.flush()
            return true
        }

        @discardableResult
        func closeInput() -> Bool {
            guard let context else { return false }
            context.triggerUserOutboundEvent(ChannelEvent.inputClosed).whenFailure { _ in }
            return true
        }

        private var context: ChannelHandlerContext?
        func handlerAdded(context: ChannelHandlerContext) { self.context = context }
        func handlerRemoved(context: ChannelHandlerContext) { self.context = nil }
    }

    // MARK: Delegates

    private final class ExecHandler: ChannelDuplexHandler, @unchecked Sendable {
        typealias InboundIn = SSHChannelData
        typealias InboundOut = ByteBuffer
        typealias OutboundIn = ByteBuffer
        typealias OutboundOut = SSHChannelData

        private let command: String
        private let stdin: String?
        private let onChunk: @Sendable (String, Bool) -> Void
        private let promise: EventLoopPromise<CommandResult>
        private var stdout = ""
        private var stderr = ""
        private var exitStatus: Int?
        private var finished = false

        var result: EventLoopFuture<CommandResult> { promise.futureResult }

        init(
            command: String,
            stdin: String?,
            promise: EventLoopPromise<CommandResult>,
            onChunk: @escaping @Sendable (String, Bool) -> Void
        ) {
            self.command = command
            self.stdin = stdin
            self.promise = promise
            self.onChunk = onChunk
        }

        func handlerAdded(context: ChannelHandlerContext) {
            context.channel.setOption(ChannelOptions.allowRemoteHalfClosure, value: true).whenFailure { _ in }
        }

        func channelActive(context: ChannelHandlerContext) {
            let request = SSHChannelRequestEvent.ExecRequest(command: command, wantReply: false)
            context.triggerUserOutboundEvent(request).whenFailure { error in
                self.finish(error: error)
            }

            if let stdin, !stdin.isEmpty {
                var buffer = context.channel.allocator.buffer(capacity: stdin.utf8.count)
                buffer.writeString(stdin)
                context.write(
                    self.wrapOutboundOut(SSHChannelData(type: .channel, data: .byteBuffer(buffer))),
                    promise: nil
                )
                context.flush()
            }
            if stdin != nil {
                // Half-close, so the remote command sees EOF on stdin.
                context.triggerUserOutboundEvent(ChannelEvent.inputClosed).whenFailure { _ in }
            }
        }

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let channelData = self.unwrapInboundIn(data)
            guard case .byteBuffer(let buffer) = channelData.data,
                  let text = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes),
                  !text.isEmpty else { return }
            let isError = channelData.type == .stdErr
            if isError { stderr += text } else { stdout += text }
            onChunk(text, isError)
        }

        func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
            if let status = event as? SSHChannelRequestEvent.ExitStatus {
                exitStatus = status.exitStatus
            }
            context.fireUserInboundEventTriggered(event)
        }

        func channelInactive(context: ChannelHandlerContext) {
            finish(error: nil)
            context.fireChannelInactive()
        }

        func errorCaught(context: ChannelHandlerContext, error: Error) {
            finish(error: error)
            context.close(promise: nil)
        }

        private func finish(error: Error?) {
            guard !finished else { return }
            finished = true
            if let error {
                promise.fail(error)
            } else {
                promise.succeed(CommandResult(exitStatus: exitStatus ?? 0, stdout: stdout, stderr: stderr))
            }
        }
    }

    private final class UserAuthDelegate: NIOSSHClientUserAuthenticationDelegate, @unchecked Sendable {
        private let username: String
        private let auth: Auth

        init(username: String, auth: Auth) {
            self.username = username
            self.auth = auth
        }

        func nextAuthenticationType(
            availableMethods: NIOSSHAvailableUserAuthenticationMethods,
            nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
        ) {
            switch auth {
            case .password(let password):
                guard availableMethods.contains(.password) else {
                    nextChallengePromise.succeed(nil)
                    return
                }
                nextChallengePromise.succeed(
                    NIOSSHUserAuthenticationOffer(
                        username: username,
                        serviceName: "",
                        offer: .password(.init(password: password))
                    )
                )

            case .privateKey(let pem):
                guard availableMethods.contains(.publicKey),
                      let key = OpenSSHKey.privateKey(from: pem) else {
                    nextChallengePromise.succeed(nil)
                    return
                }
                nextChallengePromise.succeed(
                    NIOSSHUserAuthenticationOffer(
                        username: username,
                        serviceName: "",
                        offer: .privateKey(.init(privateKey: key))
                    )
                )
            }
        }
    }

    private final class HostKeyValidator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
        private let expected: String?
        private(set) var observed: String?

        init(expected: String?) {
            self.expected = expected
        }

        func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
            let publicKeyParts = String(openSSHPublicKey: hostKey).split(separator: " ")
            guard publicKeyParts.count >= 2,
                  let keyBlob = Data(base64Encoded: String(publicKeyParts[1])) else {
                validationCompletePromise.fail(SSHError.transport("The SSH server presented an unreadable host key."))
                return
            }

            let digest = Data(SHA256.hash(data: keyBlob)).base64EncodedString()
                .trimmingCharacters(in: CharacterSet(charactersIn: "="))
            let fingerprint = "SHA256:\(digest)"
            let legacyFingerprint = "SHA256:\(publicKeyParts[1])"
            observed = fingerprint

            if let expected {
                if expected != fingerprint && expected != legacyFingerprint {
                    validationCompletePromise.fail(SSHError.hostKeyChanged(expected: expected, observed: fingerprint))
                } else {
                    validationCompletePromise.succeed(())
                }
            } else {
                validationCompletePromise.fail(SSHError.untrustedHostKey(observed: fingerprint))
            }
        }
    }
}

enum SSHError: LocalizedError {
    case commandFailed(String)
    case untrustedHostKey(observed: String)
    case hostKeyChanged(expected: String, observed: String)
    case invalidPrivateKey
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let output):
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "The remote command failed." : trimmed
        case .untrustedHostKey(let observed):
            return "This host key has not been verified. Compare \(observed) with the server operator, then trust it in Connections."
        case .hostKeyChanged(let expected, let observed):
            return "The SSH host key changed. Saved \(expected), now \(observed). Reconnect in Connections to verify and trust the new key."
        case .invalidPrivateKey:
            return "That private key could not be read. Use an unencrypted OpenSSH ed25519 key, or generate one in the app."
        case .transport(let message):
            return message
        }
    }

    static func wrap(_ error: Error, host: String) -> Error {
        if let error = error as? SSHError { return error }
        return SSHError.transport("SSH to \(host) failed. \(error.localizedDescription)")
    }
}

/// Unencrypted OpenSSH ed25519 key support: read an existing key, or generate one
/// on device so the user can paste the public half into `authorized_keys`.
enum OpenSSHKey {
    static func privateKey(from pem: String) -> NIOSSHPrivateKey? {
        guard let seed = seed(from: pem),
              let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: seed) else { return nil }
        return NIOSSHPrivateKey(ed25519Key: key)
    }

    static func seed(from pem: String) -> Data? {
        let body = pem
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty && !$0.hasPrefix("-----") }
            .joined()
        guard let data = Data(base64Encoded: body) else { return nil }

        guard let magic = "openssh-key-v1".data(using: .utf8),
              data.count > magic.count,
              data.prefix(magic.count) == magic else { return nil }

        var reader = Reader(data: data.dropFirst(magic.count + 1))
        guard let cipher = reader.string(), let kdf = reader.string(),
              cipher == "none", kdf == "none",
              reader.uint32() != nil,
              reader.lengthPrefixed() != nil,                 // public key blob
              let privateBlock = reader.lengthPrefixed() else { return nil }

        var inner = Reader(data: privateBlock)
        guard inner.uint32() != nil, inner.uint32() != nil,
              let type = inner.string(), type == "ssh-ed25519",
              inner.lengthPrefixed() != nil,                  // public key
              let privateBytes = inner.lengthPrefixed(),
              privateBytes.count >= 64 else { return nil }
        // The ed25519 private blob is the 32-byte seed followed by the public key.
        return Data(privateBytes.prefix(32))
    }

    static func generate(comment: String = "ide@ios") -> (privateKey: String, publicKey: String) {
        let key = Curve25519.Signing.PrivateKey()
        let privateKey = NIOSSHPrivateKey(ed25519Key: key)
        let publicLine = String(openSSHPublicKey: privateKey.publicKey) + " " + comment

        var publicBlob = Data()
        publicBlob.append(lengthPrefixed(Data("ssh-ed25519".utf8)))
        publicBlob.append(lengthPrefixed(key.publicKey.rawRepresentation))

        var privateBlob = Data()
        privateBlob.append(uint32(1))
        privateBlob.append(uint32(1))
        privateBlob.append(lengthPrefixed(Data("ssh-ed25519".utf8)))
        privateBlob.append(lengthPrefixed(key.publicKey.rawRepresentation))
        privateBlob.append(lengthPrefixed(key.rawRepresentation + key.publicKey.rawRepresentation))
        privateBlob.append(lengthPrefixed(Data()))

        var envelope = Data("openssh-key-v1".utf8)
        envelope.append(0)
        envelope.append(lengthPrefixed(Data("none".utf8)))
        envelope.append(lengthPrefixed(Data("none".utf8)))
        envelope.append(lengthPrefixed(Data()))
        envelope.append(uint32(1))
        envelope.append(lengthPrefixed(publicBlob))
        envelope.append(lengthPrefixed(privateBlob))

        let base64 = envelope.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
        let pem = "-----BEGIN OPENSSH PRIVATE KEY-----\n\(base64)\n-----END OPENSSH PRIVATE KEY-----\n"
        return (pem, publicLine)
    }

    private static func lengthPrefixed(_ data: Data) -> Data {
        var out = uint32(UInt32(data.count))
        out.append(data)
        return out
    }

    private static func uint32(_ value: UInt32) -> Data {
        withUnsafeBytes(of: value.bigEndian) { Data($0) }
    }

    private struct Reader {
        private let data: Data
        private var offset = 0

        init(data: Data.SubSequence) {
            self.data = Data(data)
        }

        mutating func uint32() -> UInt32? {
            guard offset + 4 <= data.count else { return nil }
            var value: UInt32 = 0
            for index in 0..<4 {
                value = (value << 8) | UInt32(data[offset + index])
            }
            offset += 4
            return value
        }

        mutating func string() -> String? {
            guard let body = lengthPrefixed() else { return nil }
            return String(data: body, encoding: .utf8)
        }

        mutating func lengthPrefixed() -> Data? {
            guard let length = uint32(), offset + Int(length) <= data.count else { return nil }
            let start = offset
            offset += Int(length)
            return data[start..<(start + Int(length))]
        }
    }
}
