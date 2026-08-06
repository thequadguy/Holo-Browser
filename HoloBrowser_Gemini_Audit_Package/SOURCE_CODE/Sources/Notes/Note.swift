import Foundation

public struct Annotation: Identifiable, Codable, Equatable {
    public let id: UUID
    public let highlightedText: String
    public let comment: String
    
    public init(id: UUID = UUID(), highlightedText: String, comment: String) {
        self.id = id
        self.highlightedText = highlightedText
        self.comment = comment
    }
}

public struct Note: Identifiable, Codable, Equatable {
    public let id: UUID
    public let pageTitle: String
    public let urlString: String
    public let content: String
    public let annotations: [Annotation]
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        pageTitle: String,
        urlString: String,
        content: String,
        annotations: [Annotation] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.pageTitle = pageTitle
        self.urlString = urlString
        self.content = content
        self.annotations = annotations
        self.timestamp = timestamp
    }
}
