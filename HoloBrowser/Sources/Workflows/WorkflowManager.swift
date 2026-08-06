import Foundation

/// Main-actor manager orchestrating workflow planning, approval modals, execution, and memory storage.
@MainActor
public final class WorkflowManager: ObservableObject {
    @Published public private(set) var activeWorkflow: Workflow?
    @Published public var showPreviewModal: Bool = false
    
    public let memory: WorkflowMemory
    public let auditLog: WorkflowAuditLog
    public let executor: WorkflowExecutor
    
    public init(
        memory: WorkflowMemory? = nil,
        auditLog: WorkflowAuditLog? = nil,
        executor: WorkflowExecutor? = nil
    ) {
        self.memory = memory ?? WorkflowMemory()
        self.auditLog = auditLog ?? WorkflowAuditLog()
        self.executor = executor ?? WorkflowExecutor()
    }
    
    public func startWorkflow(goal: String, profileID: UUID, isPrivate: Bool) {
        let workflow = WorkflowPlanner.planWorkflow(goal: goal, profileID: profileID)
        self.activeWorkflow = workflow
        
        if workflow.status == .blocked {
            auditLog.log(workflowID: workflow.id, goal: goal, wasApproved: false, outcome: "Blocked by safety policy", isPrivate: isPrivate)
        } else {
            showPreviewModal = true
        }
    }
    
    public func approveActiveWorkflow(viewModel: BrowserViewModel, isPrivate: Bool) async {
        guard var workflow = activeWorkflow, workflow.status == .pending else { return }
        showPreviewModal = false
        workflow.status = .executing
        self.activeWorkflow = workflow
        
        let completed = await executor.execute(workflow: workflow, viewModel: viewModel)
        self.activeWorkflow = completed
        memory.saveWorkflow(completed, isPrivate: isPrivate)
        auditLog.log(workflowID: completed.id, goal: completed.goal, wasApproved: true, outcome: completed.status.rawValue, isPrivate: isPrivate)
    }
    
    public func rejectActiveWorkflow(isPrivate: Bool) {
        showPreviewModal = false
        if var workflow = activeWorkflow {
            workflow.status = .blocked
            self.activeWorkflow = workflow
            auditLog.log(workflowID: workflow.id, goal: workflow.goal, wasApproved: false, outcome: "User rejected workflow", isPrivate: isPrivate)
        }
    }
}
