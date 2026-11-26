import SwiftUI

/// The connection pill: host, protocol, live round trip. Deliberately a text
/// update only — never a looping animation (design decision 8, OLED discipline).
struct ConnectionPill: View {
    let state: ConnectionStatus.State
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(state.color)
                    .frame(width: 6, height: 6)
                Text(state.host)
                    .lineLimit(1)
                Text("·")
                    .foregroundStyle(IDETheme.muted)
                Text(state.protocolName)
                    .foregroundStyle(IDETheme.secondary)
                if let latency = state.latency {
                    Text("·")
                        .foregroundStyle(IDETheme.muted)
                    Text("\(latency) ms")
                        .foregroundStyle(IDETheme.secondary)
                        .monospacedDigit()
                }
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(IDETheme.primary)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if let latency = state.latency {
            return "Connected to \(state.host), \(state.protocolName), \(latency) milliseconds"
        }
        return "\(state.host), \(state.protocolName)"
    }
}
