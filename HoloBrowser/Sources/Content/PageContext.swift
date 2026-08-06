import Foundation

/// Data model encapsulating extracted webpage content and metadata.
public struct PageContext: Codable, Equatable {
    public let title: String
    public let urlString: String
    public let bodyText: String
    public let selectedText: String?
    public let headings: [String]
    public let timestamp: Date
    
    public init(
        title: String,
        urlString: String,
        bodyText: String,
        selectedText: String? = nil,
        headings: [String] = [],
        timestamp: Date = Date()
    ) {
        self.title = title
        self.urlString = urlString
        self.bodyText = bodyText
        self.selectedText = selectedText
        self.headings = headings
        self.timestamp = timestamp
    }
}
