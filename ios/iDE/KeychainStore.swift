import Foundation
import Security

/// Minimal Keychain wrapper for the only two secrets the app keeps on device:
/// the GitHub token and SSH key material. Nothing else is persisted.
enum KeychainStore {
    private static let service = "com.groovelabs.ide.credentials"

    static func save(_ value: String, for account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encoding
        }
        remove(account)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        query[kSecAttrSynchronizable as String] = false
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
    }

    static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func remove(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static let githubTokenAccount = "github.token"
    static let sshPasswordAccount = "ssh.password"
    static let sshKeyAccount = "ssh.privatekey"

    enum KeychainError: LocalizedError {
        case encoding
        case status(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encoding:
                return "The credential could not be encoded for the Keychain."
            case .status(let status):
                return "The Keychain rejected the credential (OSStatus \(status))."
            }
        }
    }
}
