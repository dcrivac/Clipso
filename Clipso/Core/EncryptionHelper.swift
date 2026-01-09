import Foundation
import CryptoKit

// MARK: - Encryption Helper
class EncryptionHelper {
    private static let keychain = "com.clipboardmanager.encryption.key"

    static func encrypt(_ text: String) -> Data? {
        guard let data = text.data(using: .utf8) else { return nil }
        guard let key = getOrCreateKey() else { return nil }

        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }

    static func decrypt(_ encryptedData: Data) -> String? {
        guard let key = getOrCreateKey() else { return nil }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }

    private static func getOrCreateKey() -> SymmetricKey? {
        if let keyData = loadKeyFromKeychain() {
            return SymmetricKey(data: keyData)
        }

        let key = SymmetricKey(size: .bits256)
        if saveKeyToKeychain(key.withUnsafeBytes { Data($0) }) {
            return key
        }

        return nil
    }

    private static func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychain,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }

    private static func saveKeyToKeychain(_ keyData: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychain,
            kSecValueData as String: keyData
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
