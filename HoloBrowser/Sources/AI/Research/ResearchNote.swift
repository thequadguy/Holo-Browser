import Foundation

/// Markdown research note model belonging to a research session.
public struct ResearchNote: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var content: String
    public let dateCreated: Date
    public let isAIGenerated: Bool
    
    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        dateCreated: Date = Date(),
        isAIGenerated: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.dateCreated = dateCreated
        self.isAIGenerated = isAIGenerated
    }
}
