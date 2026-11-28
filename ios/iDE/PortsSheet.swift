import SwiftUI

/// S10 · Ports. Reads the host's listening sockets and offers a copyable URL,
/// which is the whole point of forwarding on a phone: the app is where the URL
/// comes from, Safari is where it opens.
struct PortsSheet: View {
    let workspace: Workspace

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var ports: [ListeningPort] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Text("Reading listening sockets…")
                        .font(.system(size: 13))
                        .foregroundStyle(IDETheme.secondary)
                        .frame(minHeight: IDETheme.recommendedHitTarget, alignment: .leading)
                        .listRowBackground(IDETheme.chassis)
                } else if ports.isEmpty {
                    ContentUnavailableView(
                        "No listening ports",
                        systemImage: "network.slash",
                        description: Text("Start a server on the host, then refresh. The app reads `ss -ltn` over the session.")
                    )
                    .listRowBackground(IDETheme.canvas)
                } else {
                    ForEach(ports) { port in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Text("\(port.port)")
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(IDETheme.azure)
                                Text(port.address)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(IDETheme.secondary)
                                Spacer(minLength: 4)
                            }
                            HStack(spacing: IDETheme.minimumGap) {
                                Button {
                                    UIPasteboard.general.string = port.url
                                    Haptics.light()
                                } label: {
                                    Text("Copy URL")
                                        .font(.system(size: 13, weight: .semibold))
                                        .frame(width: 96, height: IDETheme.minimumHitTarget)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(IDETheme.secondary.opacity(0.18), lineWidth: 1)
                                        }
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(IDETheme.secondary)

                                if let url = URL(string: port.url) {
                                    Button {
                                        Haptics.medium()
                                        openURL(url)
                                    } label: {
                                        Text("Open")
                                            .font(.system(size: 13, weight: .semibold))
                                            .frame(width: 88, height: IDETheme.minimumHitTarget)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(IDETheme.secondary.opacity(0.18), lineWidth: 1)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(IDETheme.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            Text(port.url)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(IDETheme.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(IDETheme.chassis)
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
            .navigationTitle("Ports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(minWidth: IDETheme.minimumHitTarget, minHeight: IDETheme.minimumHitTarget)
                    }
                    .accessibilityLabel("Refresh ports")
                }
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

    private func load() async {
        guard let binding = workspace.ssh else {
            error = "Ports are read from an SSH host."
            isLoading = false
            return
        }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            try await WorkspaceSync.shared.ensureSSHSession(workspaceID: workspace.id, binding: binding)
            let result = try await WorkspaceSync.shared.sshRun(
                workspaceID: workspace.id,
                command: "ss -ltnH 2>/dev/null || netstat -ltn 2>/dev/null"
            ) { _, _ in }
            ports = ListeningPort.parse(result.stdout, host: binding.host)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ListeningPort: Identifiable, Hashable {
    let port: Int
    let address: String
    let host: String

    var id: Int { port }

    /// `open in Safari` URL. A wildcard bind is still reachable at the host's
    /// own address from this device.
    var url: String { "http://\(host):\(port)" }

    /// Parses `ss -ltnH` / `netstat -ltn` lines, deduplicating by port.
    static func parse(_ text: String, host: String) -> [ListeningPort] {
        var seen: Set<Int> = []
        var ports: [ListeningPort] = []

        for line in text.components(separatedBy: .newlines) {
            let fields = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            // ss: "LISTEN 0 128 0.0.0.0:3000 0.0.0.0:*"
            // netstat: "tcp4 0 0 127.0.0.1.3000 *.* LISTEN"
            guard let local = fields.first(where: { $0.contains(":") || $0.contains(".") && $0.split(separator: ".").count > 1 }) else {
                continue
            }
            let candidate = local.contains(":")
                ? local.split(separator: ":").last.map(String.init)
                : local.split(separator: ".").last.map(String.init)
            guard let candidate, let number = Int(candidate), number > 0, number < 65_536 else { continue }
            guard !seen.contains(number) else { continue }
            seen.insert(number)
            ports.append(ListeningPort(port: number, address: local, host: host))
        }
        return ports.sorted { $0.port < $1.port }
    }
}
