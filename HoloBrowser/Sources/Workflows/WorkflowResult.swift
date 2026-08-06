import Foundation

/// Output container model capturing workflow execution results.
public struct WorkflowResult: Identifiable, Codable, Equatable {
    public let id: UUID
    public let summary: String
    public let sources: [ResearchSource]
    public let notes: [ResearchNote]
    public let comparisonTable: [String: String]
    
    public init(
        id: UUID = UUID(),
        summary: String,
        sources: [ResearchSource] = [],
        notes: [ResearchNote] = [],
        comparisonTable: [String: String] = [:]
    ) {
        self.id = id
        self.summary = summary
        self.sources = sources
        self.notes = notes
        self.comparisonTable = comparisonTable
    }
}
