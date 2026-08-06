import Foundation

/// Data model representing a collected web source in a research project.
public struct ResearchSource: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var urlString: String
    public var faviconURLString: String?
    public var summary: String
    public var dateCollected: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        urlString: String,
        faviconURLString: String? = nil,
        summary: String,
        dateCollected: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.faviconURLString = faviconURLString
        self.summary = summary
        self.dateCollected = dateCollected
    }
}
