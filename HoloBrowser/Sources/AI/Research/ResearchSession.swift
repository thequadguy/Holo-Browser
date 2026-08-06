import Foundation

/// Primary data model representing a user research session with collected sources and notes.
public struct ResearchSession: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var topic: String
    public let creationDate: Date
    public var sources: [ResearchSource]
    public var notes: [ResearchNote]
    public let profileID: UUID
    
    public init(
        id: UUID = UUID(),
        title: String,
        topic: String,
        creationDate: Date = Date(),
        sources: [ResearchSource] = [],
        notes: [ResearchNote] = [],
        profileID: UUID
    ) {
        self.id = id
        self.title = title
        self.topic = topic
        self.creationDate = creationDate
        self.sources = sources
        self.notes = notes
        self.profileID = profileID
    }
}
