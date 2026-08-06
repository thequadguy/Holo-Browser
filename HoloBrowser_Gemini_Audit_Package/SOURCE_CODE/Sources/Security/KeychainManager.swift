import Foundation
import Security

/// Low-level wrapper interfacing directly with Apple Keychain Services (Security.framework).
/// Enforces kSecAttrAccessibleWhenUnlockedThisDeviceOnly to prevent iCloud sync of website credentials.
@MainActor
public final class KeychainManager {
    
    public init() {}
    
    private func serviceKey(profileID: UUID, domain: String, username: String) -> String {
        return "com.holobrowser.credential.\(profileID.uuidString).\(domain).\(username)"
    }
    
    /// Saves a password credential securely to Apple Keychain.
    public func savePassword(_ password: String, profileID: UUID, domain: String, username: String) -> Bool {
        guard !password.isEmpty, !username.isEmpty, !domain.isEmpty else { return false }
        
        let service = serviceKey(profileID: profileID, domain: domain, username: username)
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item before adding
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves a password from Apple Keychain Services.
    public func retrievePassword(profileID: UUID, domain: String, username: String) -> String? {
        let service = serviceKey(profileID: profileID, domain: domain, username: username)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// Deletes a password from Apple Keychain.
    public func deletePassword(profileID: UUID, domain: String, username: String) -> Bool {
        let service = serviceKey(profileID: profileID, domain: domain, username: username)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
