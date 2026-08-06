import Foundation

/// Data model representing an individual saved bookmark.
public struct BookmarkItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var urlString: String
    public var folderID: UUID?
    public var isFavorite: Bool
    public let dateAdded: Date

    public init(
        id: UUID = UUID(),
        title: String,
        urlString: String,
        folderID: UUID? = nil,
        isFavorite: Bool = false,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.folderID = folderID
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
    }
}
