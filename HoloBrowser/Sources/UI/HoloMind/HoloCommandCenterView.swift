import SwiftUI

/// Holo Command Center - The default start page (holo://start).
/// Displays H briefing, timeline insights, active missions, and privacy status.
public struct HoloCommandCenterView: View {
    @ObservedObject var mindEngine: HoloMindEngine
    @ObservedObject var tabManager: TabManager
    let currentProfileID: UUID
    let isPrivateMode: Bool
    
    @State private var searchInput: String = ""
    @StateObject private var bookmarkStore = BookmarkStore()
    @ObservedObject private var settings = HoloCommandCenterSettings.shared
    
    public init(mindEngine: HoloMindEngine, tabManager: TabManager, currentProfileID: UUID, isPrivateMode: Bool) {
        self.mindEngine = mindEngine
        self.tabManager = tabManager
        self.currentProfileID = currentProfileID
        self.isPrivateMode = isPrivateMode
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header Briefing
                HStack(alignment: .top, spacing: 16) {
                    Button(action: {
                        mindEngine.togglePanel()
                    }) {
                        HoloAssistantPresenceView(state: mindEngine.isPanelVisible ? .analyzing : .idle)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greetingMessage())
                            .font(.system(size: 28, weight: .bold))
                        
                        let attentionCount = (mindEngine.contextEngine.activeResearchSessions.isEmpty ? 0 : 1) + (mindEngine.missionSystem.activeMissions.isEmpty ? 0 : 1) + 1
                        Text("\(attentionCount) things may need your attention.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        HStack(spacing: 12) {
                            if !mindEngine.contextEngine.activeResearchSessions.isEmpty {
                                briefingCard(title: "Unfinished Research", count: mindEngine.contextEngine.activeResearchSessions.count, icon: "books.vertical.fill", color: .purple)
                            }
                            if !mindEngine.missionSystem.activeMissions.isEmpty {
                                briefingCard(title: "Active Missions", count: mindEngine.missionSystem.activeMissions.count, icon: "target", color: .red)
                            }
                            briefingCard(title: "Opportunities", count: mindEngine.opportunityEngine.insightStream.count, icon: "lightbulb.fill", color: .orange)
                            briefingCard(title: "Reminders", count: 1, icon: "bell.fill", color: .blue)
                        }
                        
                        if isPrivateMode {
                            HStack(spacing: 6) {
                                Image(systemName: "shield.slash.fill")
                                    .foregroundColor(.purple)
                                Text("Private Browsing Active - Memory writes paused.")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.purple)
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        mindEngine.togglePanel()
                    }) {
                        HStack {
                            Image(systemName: "h.circle.fill")
                            Text("Open Dashboard")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(VisualEffectViewWrapper(material: .hudWindow, blendingMode: .withinWindow).cornerRadius(16))
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                // Unified Search & AI Input
                VStack(alignment: .center, spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .bold))
                        
                        TextField("Search the web, or ask H by typing 'h ...' or 'm ...'", text: $searchInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18))
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchInput.isEmpty {
                            Button(action: { searchInput = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .holoFloatingGlass(cornerRadius: 12)
                    .auroraEdge(isActive: !searchInput.isEmpty)
                }
                
                // Dashboard Grid
                HStack(alignment: .top, spacing: 24) {
                    
                    // Left Column: Active Missions & Insights
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Active Missions
                        if settings.showActiveMissions {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "target")
                                        .foregroundColor(.purple)
                                    Text("Active Missions")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                
                                if mindEngine.missionSystem.activeMissions.isEmpty {
                                    Text("No active missions.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(mindEngine.missionSystem.activeMissions) { mission in
                                        missionCard(mission)
                                    }
                                }
                            }
                        }
                        
                        // Timeline of Insights
                        if settings.showInsights {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                    Text("Timeline of Insights")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                
                                if mindEngine.opportunityEngine.insightStream.isEmpty {
                                    Text("No insights available. H is observing your workflow.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(mindEngine.opportunityEngine.insightStream.prefix(3)) { insight in
                                        insightCard(insight)
                                    }
                                }
                            }
                        }
                        
                        // Favorites Grid
                        if settings.showFavorites {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("Favorites")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                
                                if bookmarkStore.bookmarks.isEmpty {
                                    Text("No favorites saved yet.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                } else {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                                        ForEach(bookmarkStore.bookmarks.prefix(8)) { bookmark in
                                            Button(action: {
                                                if let url = URL(string: bookmark.urlString) {
                                                    tabManager.activeTab?.navigationManager.load(url: url)
                                                }
                                            }) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: "globe")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.accentColor)
                                                    Text(bookmark.title)
                                                        .font(.system(size: 11, weight: .medium))
                                                        .lineLimit(1)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .holoFloatingGlass(cornerRadius: 10, isHovered: false)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    // Right Column: Recent Activity & Privacy
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Recent Tabs
                        if settings.showRecentActivity {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                    Text("Recently Closed")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                
                                if tabManager.recentlyClosedTabs.isEmpty {
                                    Text("No recently closed tabs.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(tabManager.recentlyClosedTabs.prefix(5), id: \.url.absoluteString) { record in
                                        HStack {
                                            Text(record.url.host ?? record.url.absoluteString)
                                                .font(.system(size: 12))
                                                .lineLimit(1)
                                            Spacer()
                                            Button("Restore") {
                                                tabManager.restoreRecentlyClosedTab()
                                            }
                                            .buttonStyle(.plain)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.accentColor)
                                        }
                                        .padding(8)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.06)))
                                    }
                                }
                            }
                        }
                        
                        // Privacy Dashboard
                        if settings.showPrivacyDashboard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(.green)
                                    Text("Privacy Dashboard")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Private Memory")
                                            .font(.system(size: 12))
                                        Spacer()
                                        Text(isPrivateMode ? "Protected" : "Standard")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(isPrivateMode ? .purple : .green)
                                    }
                                    HStack {
                                        Text("AI Dispatch")
                                            .font(.system(size: 12))
                                        Spacer()
                                        Text("Regex Sanitized")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(12)
                                .holoFloatingGlass(cornerRadius: 10)
                            }
                        }
                    }
                    .frame(maxWidth: 300, alignment: .topLeading)
                }
                
                Spacer(minLength: 40)
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HoloBackgroundView())
    }
    
    // MARK: - Subviews
    
    private func briefingCard(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .holoFloatingGlass(cornerRadius: 10)
    }
    
    private func missionCard(_ mission: HoloMission) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mission.goalTitle)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                HoloBadge(mission.isCompleted ? "Completed" : "In Progress", color: mission.isCompleted ? .green : .orange)
            }
            
            ProgressView(value: mission.progressFraction)
                .progressViewStyle(.linear)
                .tint(.purple)
            
            if let nextStep = mission.steps.first(where: { $0.status == .awaitingApproval }) {
                HStack {
                    Text("Requires Approval: \(nextStep.title)")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                    Spacer()
                    Button("Approve") {
                        mindEngine.missionSystem.approveStep(missionID: mission.id, stepID: nextStep.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.small)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.purple.opacity(0.1)))
            }
        }
        .padding(12)
        .holoFloatingGlass(cornerRadius: 10)
        .auroraEdge(isActive: !mission.isCompleted)
    }
    
    private func insightCard(_ insight: HoloInsightCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HoloBadge(insight.kind.rawValue, color: .orange)
                Spacer()
                Text(insight.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Text(insight.title)
                .font(.system(size: 13, weight: .bold))
            Text(insight.summary)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .holoFloatingGlass(cornerRadius: 10)
    }
    
    private func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning."
        case 12..<17: return "Good Afternoon."
        default: return "Good Evening."
        }
    }
    
    private func performSearch() {
        let route = HoloSmartSearchRouter.route(for: searchInput)
        
        switch route {
        case .web(let url):
            tabManager.activeTab?.navigationManager.load(url: url)
        case .ai(let query):
            NotificationCenter.default.post(name: NSNotification.Name("HoloSmartSearchAI"), object: query)
        case .mission(let query):
            NotificationCenter.default.post(name: NSNotification.Name("HoloSmartSearchMission"), object: query)
        }
        
        searchInput = ""
    }
}
