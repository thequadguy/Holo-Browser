import Foundation

public struct BookmarkFolder: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var parentID: UUID?
    public var bookmarkIDs: [UUID]
    
    public init(id: UUID = UUID(), name: String, parentID: UUID? = nil, bookmarkIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.parentID = parentID
        self.bookmarkIDs = bookmarkIDs
    }
}
