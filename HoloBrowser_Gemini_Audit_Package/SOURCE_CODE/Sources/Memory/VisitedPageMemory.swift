import Foundation

public struct VisitedPageMemory: Identifiable, Codable, Equatable {
    public let id: UUID
    public let title: String
    public let urlString: String
    public let summary: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), title: String, urlString: String, summary: String, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.summary = summary
        self.timestamp = timestamp
    }
}
