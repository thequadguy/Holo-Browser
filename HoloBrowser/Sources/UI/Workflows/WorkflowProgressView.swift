import SwiftUI

/// Indicator view displaying live execution progress of active workflow steps.
public struct WorkflowProgressView: View {
    let workflow: Workflow
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Executing Workflow: \(workflow.title)")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(workflow.steps) { step in
                    HStack {
                        Image(systemName: iconName(for: step.status))
                            .foregroundColor(iconColor(for: step.status))
                            .font(.system(size: 10))
                        Text(step.name)
                            .font(.system(size: 11))
                        Spacer()
                        Text(step.status.rawValue)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }
    
    private func iconName(for status: StepStatus) -> String {
        switch status {
        case .pending: return "circle"
        case .executing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed, .skipped: return "xmark.circle.fill"
        }
    }
    
    private func iconColor(for status: StepStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .executing: return .accentColor
        case .completed: return .green
        case .failed, .skipped: return .red
        }
    }
}
