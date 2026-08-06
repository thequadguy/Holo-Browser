import Foundation

public enum WorkflowStatus: String, Codable {
    case pending = "Pending Approval"
    case executing = "Executing"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case blocked = "Blocked / Rejected"
}

/// Primary data model representing a multi-step AI workflow.
public struct Workflow: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var goal: String
    public let createdDate: Date
    public let profileID: UUID
    public var status: WorkflowStatus
    public var steps: [WorkflowStep]
    public var result: WorkflowResult?
    
    public init(
        id: UUID = UUID(),
        title: String,
        goal: String,
        createdDate: Date = Date(),
        profileID: UUID,
        status: WorkflowStatus = .pending,
        steps: [WorkflowStep] = [],
        result: WorkflowResult? = nil
    ) {
        self.id = id
        self.title = title
        self.goal = goal
        self.createdDate = createdDate
        self.profileID = profileID
        self.status = status
        self.steps = steps
        self.result = result
    }
}
