import Foundation

/// Asynchronous workflow execution engine executing approved steps via BrowserActionExecutor.
@MainActor
public final class WorkflowExecutor: ObservableObject {
    private let actionExecutor: BrowserActionExecutor
    
    public init(actionExecutor: BrowserActionExecutor? = nil) {
        self.actionExecutor = actionExecutor ?? BrowserActionExecutor()
    }
    
    public func execute(workflow: Workflow, viewModel: BrowserViewModel) async -> Workflow {
        var updated = workflow
        guard updated.status == .pending || updated.status == .executing else { return updated }
        
        updated.status = .executing
        var stepResults: [String] = []
        
        for idx in updated.steps.indices {
            let step = updated.steps[idx]
            if step.riskLevel == .blocked {
                updated.steps[idx].status = .skipped
                updated.steps[idx].result = "BLOCKED: Prohibited action"
                stepResults.append("Skipped blocked step: \(step.name)")
                continue
            }
            
            updated.steps[idx].status = .executing
            let aiAction = AIAction(
                type: step.actionType,
                name: step.name,
                description: step.description,
                riskLevel: step.riskLevel,
                requiresConfirmation: step.riskLevel == .confirm
            )
            let resultText = await actionExecutor.execute(action: aiAction, viewModel: viewModel)
            updated.steps[idx].status = .completed
            updated.steps[idx].result = resultText
            stepResults.append("\(step.name): \(resultText)")
        }
        
        updated.status = .completed
        let summaryText = "Completed \(updated.steps.count) workflow steps:\n" + stepResults.joined(separator: "\n")
        updated.result = WorkflowResult(summary: summaryText)
        return updated
    }
}
