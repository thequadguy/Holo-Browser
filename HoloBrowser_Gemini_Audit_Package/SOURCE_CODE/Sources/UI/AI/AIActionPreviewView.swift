import SwiftUI

/// Action plan preview modal showing proposed steps, affected URLs, data access details, and risk levels before execution.
public struct AIActionPreviewView: View {
    let plan: AIActionPlan
    let onApprove: () -> Void
    let onCancel: () -> Void
    
    public init(plan: AIActionPlan, onApprove: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.plan = plan
        self.onApprove = onApprove
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                    Text("What Holo AI Wants To Do")
                        .font(.headline)
                }
                Spacer()
            }
            
            Text("Goal: \(plan.goal)")
                .font(.subheadline)
                .bold()
            
            Text(plan.explanation)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Proposed Action Steps (\(plan.actions.count)):")
                .font(.system(size: 11, weight: .bold))
            
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(plan.actions) { action in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.name)
                                    .font(.system(size: 12, weight: .bold))
                                Text(action.description)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(action.riskLevel.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(badgeColor(for: action.riskLevel).opacity(0.15)))
                                .foregroundColor(badgeColor(for: action.riskLevel))
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                    }
                }
            }
            .frame(height: 180)
            
            Divider()
            
            HStack {
                Button("Cancel Action") {
                    onCancel()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Approve & Execute") {
                    onApprove()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 460)
    }
    
    private func badgeColor(for risk: AIActionPermission) -> Color {
        switch risk {
        case .safe: return .green
        case .confirm: return .orange
        case .blocked: return .red
        }
    }
}
