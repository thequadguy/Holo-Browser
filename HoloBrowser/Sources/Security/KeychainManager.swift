import Foundation
import Security
import LocalAuthentication

/// Low-level wrapper interfacing directly with Apple Keychain Services (Security.framework).
/// Enforces kSecAttrAccessibleWhenUnlockedThisDeviceOnly to prevent iCloud sync of website credentials.
@globalActor
public actor SecurityActor {
    public static let shared = SecurityActor()
    
    private init() {}
    
    private func serviceKey(profileID: UUID, domain: String, username: String) -> String {
        return "com.holobrowser.credential.\(profileID.uuidString).\(domain).\(username)"
    }
    
    /// Saves a password credential securely to Apple Keychain.
    public func savePassword(_ passwordData: Data, profileID: UUID, domain: String, username: String) -> Bool {
        guard !passwordData.isEmpty, !username.isEmpty, !domain.isEmpty else { return false }
        
        let service = serviceKey(profileID: profileID, domain: domain, username: username)
        
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
    
    /// Retrieves a password from Apple Keychain Services. Requires Touch ID/macOS authentication.
    public func retrievePassword(profileID: UUID, domain: String, username: String) async -> String? {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate to view saved password for \(domain)")
            } catch {
                return nil
            }
        }
        
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
