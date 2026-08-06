import Foundation

public enum MemoryCategory: String, Codable, CaseIterable {
    case topic = "Research Topic"
    case sitePreference = "Site Preference"
    case writingStyle = "Writing Style"
    case workflow = "Workflow Pattern"
    case custom = "User Custom"
}

/// Data model representing a user memory item.
public struct PersonalMemory: Identifiable, Codable, Equatable {
    public let id: UUID
    public let category: MemoryCategory
    public let content: String
    public let dateCreated: Date
    public let profileID: UUID
    
    public init(
        id: UUID = UUID(),
        category: MemoryCategory,
        content: String,
        dateCreated: Date = Date(),
        profileID: UUID
    ) {
        self.id = id
        self.category = category
        self.content = content
        self.dateCreated = dateCreated
        self.profileID = profileID
    }
}
