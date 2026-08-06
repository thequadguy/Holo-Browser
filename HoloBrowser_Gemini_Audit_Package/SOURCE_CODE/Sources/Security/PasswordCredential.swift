import Foundation

/// Data model representing a saved website credential metadata record.
/// Plaintext password values are NEVER stored in this struct permanently.
public struct PasswordCredential: Identifiable, Codable, Equatable {
    public let id: UUID
    public let domain: String
    public let username: String
    public let creationDate: Date
    public var lastUsedDate: Date
    public let profileID: UUID
    
    public init(
        id: UUID = UUID(),
        domain: String,
        username: String,
        creationDate: Date = Date(),
        lastUsedDate: Date = Date(),
        profileID: UUID
    ) {
        self.id = id
        self.domain = domain
        self.username = username
        self.creationDate = creationDate
        self.lastUsedDate = lastUsedDate
        self.profileID = profileID
    }
}
