import Foundation

/// Data model representing a multi-source research project binder.
public struct ResearchProject: Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var topic: String
    public var sources: [ResearchSource]
    public var notes: [String]
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        topic: String,
        sources: [ResearchSource] = [],
        notes: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.topic = topic
        self.sources = sources
        self.notes = notes
        self.createdAt = createdAt
    }
}
