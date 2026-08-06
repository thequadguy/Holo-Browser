import Foundation

/// Data model representing a saved reading list article item.
public struct ReadingItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let title: String
    public let urlString: String
    public let savedDate: Date
    public var isRead: Bool
    public let profileID: UUID
    
    public init(
        id: UUID = UUID(),
        title: String,
        urlString: String,
        savedDate: Date = Date(),
        isRead: Bool = false,
        profileID: UUID
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.savedDate = savedDate
        self.isRead = isRead
        self.profileID = profileID
    }
}
