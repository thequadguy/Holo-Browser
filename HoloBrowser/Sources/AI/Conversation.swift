import Foundation

/// Persistent model representing a saved AI conversation session for a specific page and profile.
public struct Conversation: Identifiable, Codable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let pageURLString: String
    public let pageTitle: String
    public var messages: [AIMessage]
    public let providerName: String
    public let profileID: UUID
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        pageURLString: String = "",
        pageTitle: String = "",
        messages: [AIMessage] = [],
        providerName: String = "Holo AI",
        profileID: UUID
    ) {
        self.id = id
        self.timestamp = timestamp
        self.pageURLString = pageURLString
        self.pageTitle = pageTitle
        self.messages = messages
        self.providerName = providerName
        self.profileID = profileID
    }
}
