import Foundation

/// Natural language workflow planner converting user goals into structured permission-validated steps.
public enum WorkflowPlanner {
    
    @MainActor
    public static func planWorkflow(goal: String, profileID: UUID) -> Workflow {
        let lower = goal.lowercased()
        var steps: [WorkflowStep] = []
        
        if lower.contains("buy") || lower.contains("purchase") || lower.contains("checkout") {
            // Blocked workflow step
            steps.append(WorkflowStep(
                name: "Autonomous Purchase Attempt",
                description: "Prohibited action: AI cannot execute checkouts or enter payment details.",
                actionType: .purchaseProduct,
                riskLevel: .blocked,
                status: .skipped,
                result: "BLOCKED: Safety policy forbids autonomous purchases."
            ))
            return Workflow(
                title: "Blocked Purchase Request",
                goal: goal,
                profileID: profileID,
                status: .blocked,
                steps: steps,
                result: WorkflowResult(summary: "Workflow blocked due to safety policy against autonomous checkouts.")
            )
        }
        
        if lower.contains("shopping") || lower.contains("product") || lower.contains("tv") || lower.contains("headphones") {
            steps = [
                WorkflowStep(name: "Search Sources", description: "Query search engines for product comparisons", actionType: .extractInformation, riskLevel: .safe),
                WorkflowStep(name: "Collect Specifications", description: "Extract visible technical specs and prices", actionType: .collectSource, riskLevel: .confirm),
                WorkflowStep(name: "Compare Products", description: "Analyze price and feature trade-offs", actionType: .summarizePage, riskLevel: .safe),
                WorkflowStep(name: "Create Recommendation", description: "Generate structured product comparison note", actionType: .createNote, riskLevel: .safe)
            ]
        } else if lower.contains("tab") || lower.contains("compare") {
            steps = [
                WorkflowStep(name: "Extract Tab DOM", description: "Extract visible text from active tabs", actionType: .extractInformation, riskLevel: .safe),
                WorkflowStep(name: "Identify Key Differences", description: "Synthesize contrasting features", actionType: .summarizePage, riskLevel: .safe),
                WorkflowStep(name: "Generate Synthesis Note", description: "Save comparison note", actionType: .createNote, riskLevel: .safe)
            ]
        } else {
            steps = [
                WorkflowStep(name: "Extract Readable Page Text", description: "Extract article text from main view", actionType: .extractInformation, riskLevel: .safe),
                WorkflowStep(name: "Synthesize Core Findings", description: "Generate executive summary", actionType: .summarizePage, riskLevel: .safe),
                WorkflowStep(name: "Save Research Takeaway", description: "Add note to active session", actionType: .createNote, riskLevel: .safe)
            ]
        }
        
        return Workflow(
            title: "Workflow: \(String(goal.prefix(30)))",
            goal: goal,
            profileID: profileID,
            status: .pending,
            steps: steps
        )
    }
}
