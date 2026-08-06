import Foundation
import CryptoKit
import Security

/// Secure Key Lifecycle Architecture for generating, storing, and rotating SymmetricKeys.
/// Interacts directly with the Secure Enclave / Apple Keychain.
@globalActor
public actor KeyManager {
    public static let shared = KeyManager()
    
    private init() {}
    
    private func serviceIdentifier(for profileID: UUID) -> String {
        return "com.holobrowser.encryption.key.\(profileID.uuidString)"
    }
    
    /// Retrieves the profile's symmetric encryption key, generating and storing a new one if it doesn't exist.
    public func getOrCreateKey(for profileID: UUID) throws -> SymmetricKey {
        let tag = serviceIdentifier(for: profileID).data(using: .utf8)!
        
        // 1. Attempt Retrieval
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeAES,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            // Key exists. Retrieve it as Data.
            let exportQuery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: tag,
                kSecAttrKeyType as String: kSecAttrKeyTypeAES,
                kSecReturnData as String: true
            ]
            var keyDataRef: CFTypeRef?
            let exportStatus = SecItemCopyMatching(exportQuery as CFDictionary, &keyDataRef)
            
            if exportStatus == errSecSuccess, let keyData = keyDataRef as? Data {
                return SymmetricKey(data: keyData)
            }
        }
        
        // 2. Generate New Key (256-bit AES)
        let newKey = SymmetricKey(size: .bits256)
        let newKeyData = newKey.withUnsafeBytes { Data(Array($0)) }
        
        // 3. Store in Keychain with strict accessibility
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeAES,
            kSecValueData as String: newKeyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // No iCloud Sync
        ]
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus != errSecSuccess {
            print("KeyManager Error: Failed to store new key in Keychain (Status: \(addStatus))")
            throw NSError(domain: "com.holobrowser.keymanager", code: Int(addStatus), userInfo: nil)
        }
        
        return newKey
    }
    
    /// Destroys the encryption key, rendering all underlying encrypted data cryptographically inaccessible.
    public func destroyKey(for profileID: UUID) {
        let tag = serviceIdentifier(for: profileID).data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeAES
        ]
        SecItemDelete(query as CFDictionary)
    }
}
