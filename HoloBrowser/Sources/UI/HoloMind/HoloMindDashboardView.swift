import SwiftUI

public enum HoloMindTab: String, CaseIterable, Identifiable {
    case assistant = "H Chief of Staff"
    case insights = "Timeline of Insights"
    case missions = "Mission Dashboard"
    case memories = "Memory Controls"
    case transparency = "AI Audit Log"
    
    public var id: String { rawValue }
}

/// Unified HoloMind Digital Chief of Staff interface panel.
public struct HoloMindDashboardView: View {
    @ObservedObject var mindEngine: HoloMindEngine
    let currentProfileID: UUID
    let isPrivateMode: Bool
    let onDismiss: () -> Void
    
    @State private var selectedTab: HoloMindTab = .assistant
    @State private var newGoalTitle: String = ""
    @State private var selectedMissionCategory: HoloMissionCategory = .research
    
    // Memory creation state
    @State private var newMemoryKey: String = ""
    @State private var newMemoryValue: String = ""
    @State private var newMemoryCategory: HoloMemoryCategory = .preference
    
    public init(
        mindEngine: HoloMindEngine,
        currentProfileID: UUID,
        isPrivateMode: Bool = false,
        onDismiss: @escaping () -> Void
    ) {
        self.mindEngine = mindEngine
        self.currentProfileID = currentProfileID
        self.isPrivateMode = isPrivateMode
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "h.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HoloMind Chief of Staff")
                            .font(.system(size: 14, weight: .bold))
                        Text("Status: \(mindEngine.currentState.rawValue)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
            
            Divider()
            
            // Tab Selector Strip
            HStack(spacing: 8) {
                ForEach(HoloMindTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: selectedTab == tab ? .bold : .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(selectedTab == tab ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                            .foregroundColor(selectedTab == tab ? .purple : .primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(10)
            
            Divider()
            
            // Main Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch selectedTab {
                    case .assistant:
                        assistantPanelView
                    case .insights:
                        insightsTimelineView
                    case .missions:
                        missionDashboardView
                    case .memories:
                        memoryControlsView
                    case .transparency:
                        AITransparencyPanelView()
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 480, height: 520)
        .background(VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow))
        .holoGlassCard(cornerRadius: 12, padding: 0)
    }
    
    // MARK: - Subviews
    
    private var assistantPanelView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // H Persona Executive Card
            HStack(spacing: 12) {
                HoloAssistantPresenceView(state: mapState(mindEngine.currentState))
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Executive Assistant Persona")
                        .font(.system(size: 13, weight: .bold))
                    Text("Calm, structured briefings with explicit human approval gates.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.08)))

            // Page Summary Result Area
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.purple)
                    Text("Page Summary")
                        .font(.system(size: 12, weight: .bold))
                }

                if mindEngine.isSummarizing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Extracting and summarizing page content…")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.purple.opacity(0.06)))
                } else if let error = mindEngine.summaryError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.08)))
                } else if let summary = mindEngine.lastSummaryText {
                    ScrollView {
                        Text(summary)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 140)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.06)))
                } else {
                    Text("Summarize the active page using the toolbar AI button or right-click → \"H: Summarize Selection\".")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.04)))
                }
            }

            // Assign New Goal Bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Assign Mission / Goal").font(.system(size: 12, weight: .bold))
                
                TextField("e.g. Research AI browser engines, Compare M3 MacBook prices", text: $newGoalTitle)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Picker("Category", selection: $selectedMissionCategory) {
                        ForEach(HoloMissionCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                    
                    HoloGlassButton(title: "Assign Goal", icon: "plus", isProminent: true) {
                        guard !newGoalTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        mindEngine.assignGoal(title: newGoalTitle, category: selectedMissionCategory)
                        newGoalTitle = ""
                        selectedTab = .missions
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.06)))
            
            // Context Overview
            VStack(alignment: .leading, spacing: 6) {
                Text("Active Browser Context").font(.system(size: 12, weight: .bold))
                
                Text("Research Sessions Detected: \(mindEngine.contextEngine.activeResearchSessions.count)")
                    .font(.system(size: 11)).foregroundColor(.secondary)
                Text("Unfinished Workflow Tasks: \(mindEngine.contextEngine.detectedUnfinishedTasks.count)")
                    .font(.system(size: 11)).foregroundColor(.secondary)
                Text("Duplicate Tab Clutter: \(mindEngine.contextEngine.duplicateTabCount) tabs")
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }
        }
    }
    
    private var insightsTimelineView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timeline of Proactive Insights").font(.system(size: 13, weight: .bold))
            
            if mindEngine.opportunityEngine.insightStream.isEmpty {
                Text("No insights generated yet.").font(.system(size: 11)).foregroundColor(.secondary)
            } else {
                ForEach(mindEngine.opportunityEngine.insightStream) { card in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                HoloBadge(card.kind.rawValue, color: .purple)
                                Spacer()
                                Text(card.timestamp, style: .time)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(card.title)
                                .font(.system(size: 12, weight: .bold))
                            Text(card.summary)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            
                            if let actionTitle = card.recommendedActionTitle {
                                Button(action: {}) {
                                    Text("Action: \(actionTitle)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.purple)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Button(action: {
                            mindEngine.opportunityEngine.dismissInsight(id: card.id)
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.06)))
                }
            }
        }
    }
    
    private var missionDashboardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Missions & Human Approval Gateways").font(.system(size: 13, weight: .bold))
            
            if mindEngine.missionSystem.activeMissions.isEmpty {
                Text("No active missions. Use the H Chief of Staff tab to assign a goal.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                ForEach(mindEngine.missionSystem.activeMissions) { mission in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: mission.category.icon)
                                .foregroundColor(.purple)
                            Text(mission.goalTitle)
                                .font(.system(size: 12, weight: .bold))
                            Spacer()
                            HoloBadge(mission.isCompleted ? "Completed" : "In Progress", color: mission.isCompleted ? .green : .orange)
                        }
                        
                        ProgressView(value: mission.progressFraction)
                            .progressViewStyle(.linear)
                            .tint(.purple)
                        
                        // Steps
                        ForEach(mission.steps) { step in
                            HStack {
                                Text("\(step.stepNumber). \(step.title)")
                                    .font(.system(size: 11, weight: .semibold))
                                Spacer()
                                if step.status == .awaitingApproval {
                                    HoloGlassButton(title: "Approve Action", icon: "checkmark", isProminent: true) {
                                        mindEngine.missionSystem.approveStep(missionID: mission.id, stepID: step.id)
                                    }
                                } else {
                                    Text(step.status.rawValue)
                                        .font(.system(size: 10))
                                        .foregroundColor(step.status == .completed ? .green : .secondary)
                                }
                            }
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.05)))
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.05)))
                }
            }
        }
    }
    
    private var memoryControlsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User-Controlled Memory Engine").font(.system(size: 13, weight: .bold))
            
            if isPrivateMode {
                Text("⚠️ Private Profile Active: Memory reads and writes are paused for privacy.")
                    .font(.system(size: 11))
                    .foregroundColor(.purple)
            }
            
            // Add New Memory Bar
            VStack(alignment: .leading, spacing: 6) {
                Text("Add Stored Memory").font(.system(size: 11, weight: .semibold))
                HStack {
                    TextField("Key (e.g. Preferred Language)", text: $newMemoryKey)
                        .textFieldStyle(.roundedBorder)
                    TextField("Value (e.g. Swift)", text: $newMemoryValue)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("", selection: $newMemoryCategory) {
                        ForEach(HoloMemoryCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button(action: {
                        guard !newMemoryKey.isEmpty && !newMemoryValue.isEmpty else { return }
                        Task {
                            try? await mindEngine.memoryEngine.addMemory(
                                category: newMemoryCategory,
                                key: newMemoryKey,
                                value: newMemoryValue,
                                profileID: currentProfileID,
                                isPrivate: isPrivateMode
                            )
                        }
                        
                        newMemoryKey = ""
                        newMemoryValue = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.06)))
            
            Divider()
            
            // Memory List
            let profileMemories = mindEngine.memoryEngine.memories(for: currentProfileID)
            if profileMemories.isEmpty {
                Text("No memories stored for this profile.").font(.system(size: 11)).foregroundColor(.secondary)
            } else {
                ForEach(profileMemories) { mem in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(mem.key).font(.system(size: 12, weight: .bold))
                                HoloBadge(mem.category.rawValue, color: .purple)
                            }
                            Text(mem.value).font(.system(size: 11)).foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            mindEngine.memoryEngine.deleteMemory(id: mem.id, profileID: currentProfileID)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.05)))
                }
            }
        }
    }
    
    private func mapState(_ state: HAssistantState) -> HoloAssistantPresenceView.PresenceState {
        switch state {
        case .idle: return .idle
        case .analyzing: return .analyzing
        case .planning: return .planning
        case .awaitingApproval: return .awaitingApproval
        case .executing: return .executing
        }
    }
}
