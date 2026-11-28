import SwiftUI

/// Live connection state for the status pill (design plan S3 / decision 8:
/// text updates at most every 5 s, never a pulsing animation).
@MainActor
final class ConnectionStatus: ObservableObject {
    enum State: Equatable {
        case local
        case connecting(host: String)
        case online(host: String, protocolName: String, latency: Int)
        case offline(host: String, reason: String)

        var host: String {
            switch self {
            case .local: return "LOCAL"
            case .connecting(let host): return host
            case .online(let host, _, _): return host
            case .offline(let host, _): return host
            }
        }

        var protocolName: String {
            switch self {
            case .local: return "Files"
            case .connecting: return "Connecting"
            case .online(_, let name, _): return name
            case .offline: return "Offline"
            }
        }

        var latency: Int? {
            if case .online(_, _, let latency) = self { return latency }
            return nil
        }

        var isLive: Bool {
            if case .online = self { return true }
            return false
        }

        var isFailed: Bool {
            if case .offline = self { return true }
            return false
        }

        var color: Color {
            switch self {
            case .local: return IDETheme.emerald
            case .connecting: return IDETheme.azure
            case .online: return IDETheme.cyan
            case .offline: return IDETheme.coral
            }
        }
    }

    @Published private(set) var state: State = .local
    private var probeTask: Task<Void, Never>?

    func update(_ state: State) {
        self.state = state
    }

    func reset() {
        probeTask?.cancel()
        probeTask = nil
        state = .local
    }

    /// Measures the round trip of a cheap remote call every 5 s and republishes
    /// the pill. One probe at a time; cancelled as soon as the pill changes.
    func startProbing(host: String, protocolName: String, probe: @escaping () async -> Result<Int, Error>) {
        probeTask?.cancel()
        state = .connecting(host: host)
        probeTask = Task { [weak self] in
            while !Task.isCancelled {
                let started = Date()
                do {
                    _ = try await probe().get()
                    let elapsed = Int(Date().timeIntervalSince(started) * 1000)
                    if Task.isCancelled { return }
                    self?.state = .online(host: host, protocolName: protocolName, latency: max(elapsed, 1))
                } catch {
                    if Task.isCancelled { return }
                    self?.state = .offline(host: host, reason: error.localizedDescription)
                    return
                }
                do {
                    try await Task.sleep(for: .seconds(5))
                } catch {
                    return
                }
            }
        }
    }
}
