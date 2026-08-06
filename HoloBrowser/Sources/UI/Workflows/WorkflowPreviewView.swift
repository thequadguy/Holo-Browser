import SwiftUI

/// Approval modal displaying workflow goals, proposed steps, permissions required, and "Approve Workflow" / "Cancel" controls.
public struct WorkflowPreviewView: View {
    let workflow: Workflow
    let onApprove: () -> Void
    let onCancel: () -> Void
    
    public init(workflow: Workflow, onApprove: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.workflow = workflow
        self.onApprove = onApprove
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundColor(.accentColor)
                    Text("AI Workflow Execution Request")
                        .font(.headline)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Goal: \(workflow.goal)")
                    .font(.system(size: 13, weight: .bold))
                Text("Holo AI wants to execute the following plan:")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(workflow.steps) { step in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.name)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(step.description)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(step.riskLevel.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(badgeColor(for: step.riskLevel).opacity(0.15)))
                                .foregroundColor(badgeColor(for: step.riskLevel))
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                    }
                }
            }
            .frame(height: 180)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Permissions: Read webpages only. Purchases and passwords are blocked.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Approve Workflow") {
                    onApprove()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 480)
    }
    
    private func badgeColor(for risk: AIActionPermission) -> Color {
        switch risk {
        case .safe: return .green
        case .confirm: return .orange
        case .blocked: return .red
        }
    }
}
