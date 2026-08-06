import Foundation

/// Data model representing a browser profile (Personal, Work, Private, etc.).
public struct BrowserProfile: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let colorHex: String
    public let creationDate: Date
    public var lastUsedDate: Date
    public let storageIdentifier: String
    public let isPrivate: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        creationDate: Date = Date(),
        lastUsedDate: Date = Date(),
        storageIdentifier: String? = nil,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.creationDate = creationDate
        self.lastUsedDate = lastUsedDate
        self.storageIdentifier = storageIdentifier ?? id.uuidString
        self.isPrivate = isPrivate
    }
}
