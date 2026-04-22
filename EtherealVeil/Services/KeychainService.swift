// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Keychain wrapper — stores API keys securely, never in source code.

import Foundation
import Security

enum KeychainKey: String {
    case stabilityAIKey  = "wcs.etherealveil.stability_ai_key"
    case openAIKey       = "wcs.etherealveil.openai_key"
    case replicateKey    = "wcs.etherealveil.replicate_key"
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
    case dataConversionFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let s):   "Keychain save failed: \(s)"
        case .readFailed(let s):   "Keychain read failed: \(s)"
        case .deleteFailed(let s): "Keychain delete failed: \(s)"
        case .dataConversionFailed: "Data conversion failed"
        }
    }
}

struct KeychainService {

    // MARK: - Save

    @discardableResult
    static func save(_ value: String, for key: KeychainKey) throws -> Bool {
        guard let data = value.data(using: .utf8) else { throw KeychainError.dataConversionFailed }

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecValueData:   data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
        return true
    }

    // MARK: - Read

    static func read(_ key: KeychainKey) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    // MARK: - Delete

    @discardableResult
    static func delete(_ key: KeychainKey) throws -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        return true
    }

    // MARK: - Convenience

    static func hasKey(_ key: KeychainKey) -> Bool { read(key) != nil }
}
