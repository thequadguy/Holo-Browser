import Foundation

public enum StepStatus: String, Codable {
    case pending = "Pending"
    case executing = "Executing"
    case completed = "Completed"
    case failed = "Failed"
    case skipped = "Skipped/Blocked"
}

/// Representation of an individual step in an AI Workflow.
public struct WorkflowStep: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let description: String
    public let actionType: ActionType
    public let riskLevel: AIActionPermission
    public var status: StepStatus
    public var result: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        actionType: ActionType,
        riskLevel: AIActionPermission,
        status: StepStatus = .pending,
        result: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.actionType = actionType
        self.riskLevel = riskLevel
        self.status = status
        self.result = result
    }
}
