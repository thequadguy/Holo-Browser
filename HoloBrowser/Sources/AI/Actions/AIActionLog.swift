import Foundation

/// Audit log record documenting executed or rejected AI actions.
public struct AIActionLog: Identifiable, Codable, Equatable {
    public let id: UUID
    public let actionName: String
    public let timestamp: Date
    public let wasApproved: Bool
    public let result: String
    
    public init(
        id: UUID = UUID(),
        actionName: String,
        timestamp: Date = Date(),
        wasApproved: Bool,
        result: String
    ) {
        self.id = id
        self.actionName = actionName
        self.timestamp = timestamp
        self.wasApproved = wasApproved
        self.result = result
    }
}
