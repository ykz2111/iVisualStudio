import SwiftUI

/// Native SwiftUI equivalents of the canonical values in brand/tokens.css.
enum IDETheme {
    static let oledBlack = Color(rgb: 0x000000)
    static let canvas = Color(rgb: 0x05080E)
    static let chassis = Color(rgb: 0x0A0F18)
    static let elevated = Color(rgb: 0x111926)
    static let thumbBar = Color(rgb: 0x131E2E)

    static let primary = Color(rgb: 0xF4F9FD)
    static let secondary = Color(rgb: 0x9BB0C5)
    static let muted = Color(rgb: 0x64748B)

    static let azure = Color(rgb: 0x38BDF8)
    static let vscode = Color(rgb: 0x007ACC)
    static let cyan = Color(rgb: 0x14F1D9)
    static let emerald = Color(rgb: 0x34D399)
    static let violet = Color(rgb: 0xA855F7)
    static let amber = Color(rgb: 0xFBBF24)
    static let coral = Color(rgb: 0xFC6D26)

    static let pageGutter: CGFloat = 16
    static let cardRadius: CGFloat = 12
    static let minimumHitTarget: CGFloat = 44
    static let recommendedHitTarget: CGFloat = 48
    static let minimumGap: CGFloat = 8
    static let codeSize: CGFloat = 13.5
}

private extension Color {
    init(rgb: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: 1
        )
    }
}
