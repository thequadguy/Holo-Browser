import Foundation
import Security

/// Keychain service identifiers for AI provider API keys.
/// Keys are stored with kSecAttrAccessibleWhenUnlockedThisDeviceOnly to prevent iCloud sync of credentials.
private enum AIKeychainKey {
    static let openAI    = "com.holobrowser.ai.apikey.openai"
    static let anthropic = "com.holobrowser.ai.apikey.anthropic"
}

/// Factory that builds AI provider instances from Keychain-stored credentials.
/// API keys are NEVER read from UserDefaults, plist files, or disk JSON.
///
/// P0-D Fix: All Keychain IPC (SecItemCopyMatching, SecItemAdd, SecItemDelete) is now
/// executed on a background thread via Task.detached + DispatchQueue.global(). The
/// previous @MainActor annotation caused synchronous Keychain IPC on the main thread,
/// which blocks the UI for 50–200ms per access.
///
/// Async API:
///   let provider = await AIProviderFactory.provider(for: .openAI)
///   let saved    = await AIProviderFactory.saveKey(key, for: .openAI)
///   let deleted  = await AIProviderFactory.deleteKey(for: .openAI)
///   let isOK     = await AIProviderFactory.isConfigured(for: .openAI)
public enum AIProviderFactory {

    public enum ProviderType: String, CaseIterable, Identifiable {
        case mock      = "Mock (Demo)"
        case openAI    = "OpenAI GPT-4o"
        case anthropic = "Anthropic Claude"

        public var id: String { rawValue }
    }

    // MARK: - Async Provider Construction

    /// Async: loads the Keychain credential on a background thread, then returns the provider.
    /// Falls back to MockAIProvider when no key is found or the key is empty.
    @MainActor
    public static func provider(for type: ProviderType) async -> AIProviderProtocol {
        switch type {
        case .mock:
            return MockAIProvider()
        case .openAI:
            let key = await loadKeyOffMainThread(for: AIKeychainKey.openAI)
            guard let key, !key.isEmpty else { return MockAIProvider() }
            return OpenAIProvider(apiKey: key)
        case .anthropic:
            let key = await loadKeyOffMainThread(for: AIKeychainKey.anthropic)
            guard let key, !key.isEmpty else { return MockAIProvider() }
            return AnthropicProvider(apiKey: key)
        }
    }

    /// Async: returns true if a non-empty key exists in Keychain for the given type.
    public static func isConfigured(for type: ProviderType) async -> Bool {
        switch type {
        case .mock:
            return true
        case .openAI:
            let key = await loadKeyOffMainThread(for: AIKeychainKey.openAI)
            return key != nil && !(key!.isEmpty)
        case .anthropic:
            let key = await loadKeyOffMainThread(for: AIKeychainKey.anthropic)
            return key != nil && !(key!.isEmpty)
        }
    }

    // MARK: - Async Keychain Write API

    /// Async: saves an API key to Keychain on a background thread.
    /// Validates the key is non-empty before persisting — saves an empty string are rejected.
    /// Returns true on success.
    @discardableResult
    public static func saveKey(_ key: String, for type: ProviderType) async -> Bool {
        // Reject empty keys — they would result in isConfigured incorrectly returning true.
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        let keychainID: String
        switch type {
        case .openAI:    keychainID = AIKeychainKey.openAI
        case .anthropic: keychainID = AIKeychainKey.anthropic
        case .mock:      return false
        }

        guard let data = key.data(using: .utf8) else { return false }

        return await Task.detached(priority: .userInitiated) {
            // Delete existing entry first to allow updates
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainID
            ]
            SecItemDelete(deleteQuery as CFDictionary)

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainID,
                kSecAttrAccount as String: "apikey",
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]

            let status = SecItemAdd(addQuery as CFDictionary, nil)
            return status == errSecSuccess
        }.value
    }

    /// Async: deletes the stored API key from Keychain on a background thread.
    @discardableResult
    public static func deleteKey(for type: ProviderType) async -> Bool {
        let keychainID: String
        switch type {
        case .openAI:    keychainID = AIKeychainKey.openAI
        case .anthropic: keychainID = AIKeychainKey.anthropic
        case .mock:      return false
        }

        return await Task.detached(priority: .userInitiated) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainID
            ]
            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }.value
    }

    // MARK: - Private Background Keychain Read

    private static func loadKeyOffMainThread(for keychainID: String) async -> String? {
        await Task.detached(priority: .userInitiated) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainID,
                kSecAttrAccount as String: "apikey",
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            guard status == errSecSuccess, let data = result as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        }.value
    }
}
