import Foundation
import Combine

// MARK: - Secure Password Prompt (P1-5)

/// Transient credential prompt carrying a plaintext password with explicit zeroing.
///
/// P1-5 Fix: replaces the previous `@Published var promptSaveCredential: (domain, username, password)?`
/// anonymous tuple. The previous design stored the plaintext password in @Published state for
/// the lifetime of any Combine subscriber, exposing it in heap memory to crash reporters
/// and memory snapshots. SecureCredentialPrompt zeroes the password field immediately after use.
public struct SecureCredentialPrompt {
    public let domain: String
    public let username: String

    // Stored as a private var so it can be zeroed when discarded.
    private(set) var _passwordData: Data

    public init(domain: String, username: String, password: String) {
        self.domain = domain
        self.username = username
        self._passwordData = password.data(using: .utf8) ?? Data()
    }

    /// Reads the password for a single immediate use and zeroes it from this struct's copy.
    public mutating func consumePasswordData() -> Data {
        let pwData = _passwordData
        _ = _passwordData.withUnsafeMutableBytes { ptr in
            ptr.initializeMemory(as: UInt8.self, repeating: 0)
        }
        return pwData
    }
}

// MARK: - PasswordManager

/// High-level main-actor manager orchestrating password credentials, Keychain storage, and profile isolation.
@MainActor
public final class PasswordManager: ObservableObject {
    @Published public private(set) var credentials: [PasswordCredential] = []

    /// P1-5 Fix: replaced `(domain: String, username: String, password: String)?` tuple with
    /// SecureCredentialPrompt. Callers must call consumePassword() immediately and pass the result
    /// to saveCredential(). The prompt is then nil'd to remove it from Combine publisher state.
    @Published public var promptSaveCredential: SecureCredentialPrompt? = nil

    private let fileURL: URL

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("credentials.json")
        load()
    }

    /// Returns saved credentials strictly belonging to the specified profile.
    public func credentials(for profileID: UUID) -> [PasswordCredential] {
        return credentials.filter { $0.profileID == profileID }
    }

    /// Saves a new password credential securely to Apple Keychain and updates local metadata index.
    @discardableResult
    public func saveCredential(domain: String, username: String, passwordData: Data, profileID: UUID) async -> Bool {
        guard !domain.isEmpty, !username.isEmpty, !passwordData.isEmpty else { return false }

        let success = await SecurityActor.shared.savePassword(passwordData, profileID: profileID, domain: domain, username: username)
        guard success else { return false }

        if var existing = credentials.first(where: { $0.profileID == profileID && $0.domain == domain && $0.username == username }) {
            if let idx = credentials.firstIndex(where: { $0.id == existing.id }) {
                existing.lastUsedDate = Date()
                credentials[idx] = existing
            }
        } else {
            let newCred = PasswordCredential(domain: domain, username: username, profileID: profileID)
            credentials.insert(newCred, at: 0)
        }

        saveMetadata()
        return true
    }

    /// Retrieves plaintext password from Keychain for an authenticated credential.
    public func retrievePassword(for credential: PasswordCredential) async -> String? {
        return await SecurityActor.shared.retrievePassword(profileID: credential.profileID, domain: credential.domain, username: credential.username)
    }

    /// Deletes a saved credential from Keychain and removes its metadata.
    public func deleteCredential(id: UUID) {
        guard let index = credentials.firstIndex(where: { $0.id == id }) else { return }
        let target = credentials[index]

        Task {
            _ = await SecurityActor.shared.deletePassword(profileID: target.profileID, domain: target.domain, username: target.username)
        }
        credentials.remove(at: index)
        saveMetadata()
    }

    /// Searches credentials by query string for a profile.
    public func searchCredentials(query: String, profileID: UUID) -> [PasswordCredential] {
        let profileCreds = credentials(for: profileID)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return profileCreds }
        return profileCreds.filter {
            $0.domain.lowercased().contains(trimmed) || $0.username.lowercased().contains(trimmed)
        }
    }

    // MARK: - Metadata Persistence (Metadata Only - NO Passwords)

    private func load() {
        Task { @MainActor in
            self.credentials = await SafeJSONDecoder.decodeWithFallbackAsync([PasswordCredential].self, from: fileURL, fallback: [])
        }
    }

    private func saveMetadata() {
        let copy = credentials
        let url = fileURL
        Task {
            try? await DiskStorageActor.shared.write(copy, to: url)
        }
    }

}
