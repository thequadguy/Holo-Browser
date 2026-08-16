import Foundation
import CryptoKit
import Security

/// Secure Key Lifecycle Architecture for generating, storing, and rotating SymmetricKeys.
/// Interacts directly with the Apple Keychain with in-memory fallback for headless test runners.
@globalActor
public actor KeyManager {
    /// Shared singleton instance of KeyManager.
    public static let shared = KeyManager()

    private var inMemoryFallback: [UUID: SymmetricKey] = [:]

    private init() {}

    private func serviceIdentifier(for profileID: UUID) -> String {
        return "com.holobrowser.encryption.key"
    }

    /// Retrieves the profile's symmetric encryption key, generating and storing a new one if it doesn't exist.
    public func getOrCreateKey(for profileID: UUID) throws -> SymmetricKey {
        let service = serviceIdentifier(for: profileID)
        let account = profileID.uuidString

        // 1. Attempt Retrieval
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let keyData = item as? Data {
            let key = SymmetricKey(data: keyData)
            inMemoryFallback[profileID] = key
            return key
        }

        if let existing = inMemoryFallback[profileID], status == errSecItemNotFound || status == -25303 {
            return existing
        }

        // 2. Generate New Key (256-bit AES)
        let newKey = SymmetricKey(size: .bits256)
        let newKeyData = newKey.withUnsafeBytes { Data(Array($0)) }

        // 3. Store in Keychain with strict accessibility
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: newKeyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // No iCloud Sync
        ]

        SecItemDelete(addQuery as CFDictionary)
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

        if addStatus != errSecSuccess {
            if addStatus == -25303 || addStatus == errSecNotAvailable {
                inMemoryFallback[profileID] = newKey
                return newKey
            }
            print("KeyManager Error: Failed to store new key in Keychain (Status: \(addStatus))")
            throw NSError(domain: "com.holobrowser.keymanager", code: Int(addStatus), userInfo: nil)
        }

        inMemoryFallback[profileID] = newKey
        return newKey
    }

    /// Destroys the encryption key, rendering all underlying encrypted data cryptographically inaccessible.
    public func destroyKey(for profileID: UUID) {
        let service = serviceIdentifier(for: profileID)
        let account = profileID.uuidString
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        inMemoryFallback.removeValue(forKey: profileID)
    }
}
