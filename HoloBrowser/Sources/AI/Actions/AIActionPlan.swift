import Foundation

public enum PlanStatus: String, Codable {
    case pending = "Pending Review"
    case approved = "Approved"
    case executing = "Executing"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case rejected = "Blocked/Rejected"
}

/// Multi-step plan proposed by Holo AI for user approval.
public struct AIActionPlan: Identifiable, Codable, Equatable {
    public let id: UUID
    public let goal: String
    public let actions: [AIAction]
    public let explanation: String
    public var status: PlanStatus
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        goal: String,
        actions: [AIAction],
        explanation: String,
        status: PlanStatus = .pending,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.goal = goal
        self.actions = actions
        self.explanation = explanation
        self.status = status
        self.timestamp = timestamp
    }
}
