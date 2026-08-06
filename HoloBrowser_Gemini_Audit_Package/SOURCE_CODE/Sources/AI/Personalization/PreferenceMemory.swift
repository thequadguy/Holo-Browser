import Foundation

/// Key-value preference memory item for user AI personalization.
public struct PreferenceMemory: Identifiable, Codable, Equatable {
    public let id: UUID
    public let key: String
    public let value: String
    public let profileID: UUID
    
    public init(id: UUID = UUID(), key: String, value: String, profileID: UUID) {
        self.id = id
        self.key = key
        self.value = value
        self.profileID = profileID
    }
}
