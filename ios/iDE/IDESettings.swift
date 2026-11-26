import SwiftUI

/// App-level preferences. Deliberately a small `UserDefaults` facade rather than
/// a settings framework: six keys, no migrations, no surprises.
enum IDESettings {
    private static let hapticsKey = "ide.haptics.enabled"
    private static let codeSizeKey = "ide.editor.codeSize"
    private static let advancedWebKey = "ide.advanced.webview"
    private static let webURLKey = "ide.advanced.webURL"
    private static let onboardingKey = "ide.onboarding.complete"

    static var hapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: hapticsKey) }
    }

    static var codeSize: Double {
        get {
            let stored = UserDefaults.standard.double(forKey: codeSizeKey)
            return stored > 0 ? stored : Double(IDETheme.codeSize)
        }
        set { UserDefaults.standard.set(newValue, forKey: codeSizeKey) }
    }

    /// App Store posture (build plan §5): the webview is never the default
    /// surface, so it stays behind this toggle.
    static var advancedWebEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: advancedWebKey) }
        set { UserDefaults.standard.set(newValue, forKey: advancedWebKey) }
    }

    static var advancedWebURL: String {
        get { UserDefaults.standard.string(forKey: webURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: webURLKey) }
    }

    static var onboardingComplete: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }
}
