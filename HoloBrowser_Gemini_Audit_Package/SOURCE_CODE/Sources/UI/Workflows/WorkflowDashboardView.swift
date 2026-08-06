import SwiftUI

/// Main AI Workflow Dashboard rendering active/completed workflows and template quick-launches.
public struct WorkflowDashboardView: View {
    @ObservedObject var workflowManager: WorkflowManager
    @ObservedObject var viewModel: BrowserViewModel
    let isPrivate: Bool
    
    @State private var customGoal: String = ""
    
    public init(workflowManager: WorkflowManager, viewModel: BrowserViewModel, isPrivate: Bool) {
        self.workflowManager = workflowManager
        self.viewModel = viewModel
        self.isPrivate = isPrivate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cpu.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                    Text("AI Workflow Engine")
                        .font(.headline)
                }
                Spacer()
            }
            
            Divider()
            
            if isPrivate {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Workflows Disabled in Private Browsing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // Quick Launch Templates
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick Templates").font(.caption).bold().foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(WorkflowTemplate.defaultTemplates) { template in
                                Button(action: {
                                    workflowManager.startWorkflow(
                                        goal: template.goal,
                                        profileID: viewModel.profileManager.activeProfile.id,
                                        isPrivate: isPrivate
                                    )
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: template.iconName)
                                            .foregroundColor(.accentColor)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.title).font(.system(size: 11, weight: .semibold))
                                            Text(template.goal).font(.system(size: 9)).foregroundColor(.secondary).lineLimit(1)
                                        }
                                    }
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Start Custom Workflow Input
                HStack {
                    TextField("Enter custom goal (e.g. Find OLED TV under $1500)...", text: $customGoal)
                        .textFieldStyle(.roundedBorder)
                    Button("Start Workflow") {
                        guard !customGoal.isEmpty else { return }
                        workflowManager.startWorkflow(
                            goal: customGoal,
                            profileID: viewModel.profileManager.activeProfile.id,
                            isPrivate: isPrivate
                        )
                        customGoal = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                
                // Active / Recent Workflows
                if let active = workflowManager.activeWorkflow {
                    if active.status == .executing {
                        WorkflowProgressView(workflow: active)
                    } else if let result = active.result {
                        WorkflowResultView(result: result)
                    }
                }
                
                Text("Saved Workflow History (\(workflowManager.memory.workflows.count)):")
                    .font(.caption)
                    .bold()
                
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(workflowManager.memory.workflows) { wf in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(wf.title)
                                        .font(.system(size: 11, weight: .bold))
                                    Text(wf.goal)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(wf.status.rawValue)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .padding(14)
        .frame(width: 520)
        .sheet(isPresented: $workflowManager.showPreviewModal) {
            if let active = workflowManager.activeWorkflow {
                WorkflowPreviewView(
                    workflow: active,
                    onApprove: {
                        Task { @MainActor in
                            await workflowManager.approveActiveWorkflow(viewModel: viewModel, isPrivate: isPrivate)
                        }
                    },
                    onCancel: {
                        workflowManager.rejectActiveWorkflow(isPrivate: isPrivate)
                    }
                )
            }
        }
    }
}
