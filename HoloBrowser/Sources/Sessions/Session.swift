import Foundation

public struct SavedTabItem: Codable, Equatable {
    public let urlString: String
    public let title: String
    public let isPinned: Bool
    
    public init(urlString: String, title: String, isPinned: Bool = false) {
        self.urlString = urlString
        self.title = title
        self.isPinned = isPinned
    }
}

/// Data model representing a saved browser window session.
public struct Session: Identifiable, Codable, Equatable {
    public let id: UUID
    public let profileID: UUID
    public let timestamp: Date
    public let tabs: [SavedTabItem]
    public let activeTabIndex: Int
    public let isPrivate: Bool
    
    public init(
        id: UUID = UUID(),
        profileID: UUID,
        timestamp: Date = Date(),
        tabs: [SavedTabItem],
        activeTabIndex: Int = 0,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.profileID = profileID
        self.timestamp = timestamp
        self.tabs = tabs
        self.activeTabIndex = activeTabIndex
        self.isPrivate = isPrivate
    }
}
