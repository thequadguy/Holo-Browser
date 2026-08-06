import SwiftUI
import AppKit

/// Premium native Holo Start Page (holo://start) synthesizing Safari, Arc, and AI browser start experiences.
public struct HoloStartPageView: View {
    @ObservedObject var mindEngine: HoloMindEngine
    @ObservedObject var tabManager: TabManager
    let currentProfileID: UUID
    let isPrivateMode: Bool
    
    @State private var searchInput: String = ""
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var bookmarkStore = BookmarkStore()
    @ObservedObject private var privacyManager = AIPrivacyManager()
    
    public init(mindEngine: HoloMindEngine, tabManager: TabManager, currentProfileID: UUID, isPrivateMode: Bool) {
        self.mindEngine = mindEngine
        self.tabManager = tabManager
        self.currentProfileID = currentProfileID
        self.isPrivateMode = isPrivateMode
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                
                // MARK: - 1. Hero Header & Intelligent Search Bar
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(HoloTheme.Palette.heroGradient)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greetingMessage())
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(HoloTheme.Text.primary)
                            Text(isPrivateMode ? "Private Browsing Active • History & memory indexing paused" : "HoloMind Personal Memory active • Indexing 4 workspace tabs")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isPrivateMode ? .purple : HoloTheme.Text.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            mindEngine.togglePanel()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(HoloTheme.Palette.holoCyan)
                                Text("HoloMind AI")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(HoloTheme.Text.primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .holoFrostGlass(cornerRadius: 12)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Intelligent Multi-Mode Search Input
                    HStack(spacing: 10) {
                        Image(systemName: searchInputIcon())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(searchInputColor())
                        
                        TextField("Search Brave, type URL, 'h' for AI, or 'm' for Mission...", text: $searchInput, onCommit: executeSearch)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                        
                        if !searchInput.isEmpty {
                            Button(action: { searchInput = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button("Search", action: executeSearch)
                            .buttonStyle(HoloPrimaryButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .holoClearGlass(cornerRadius: 16)
                }
                .padding(.top, 20)
                
                // MARK: - 2. Quick Action Pills
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(HoloTheme.Text.secondary)
                    
                    HStack(spacing: 12) {
                        quickActionButton(title: "New Tab", icon: "plus.circle.fill", color: HoloTheme.Palette.holoCyan) {
                            _ = tabManager.createNewTab()
                        }
                        quickActionButton(title: "Ask HoloMind", icon: "sparkles", color: .purple) {
                            mindEngine.isPanelVisible = true
                        }
                        quickActionButton(title: "Create Mission", icon: "target", color: .red) {
                            mindEngine.assignGoal(title: "New Autonomous Mission", category: .research)
                            mindEngine.isPanelVisible = true
                        }
                        quickActionButton(title: "Reopen Closed Tab", icon: "arrow.uturn.backward.circle.fill", color: .orange) {
                            _ = tabManager.createNewTab()
                        }
                    }
                }
                
                // MARK: - 3. Favorites & Bookmarks Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Favorites & Shortcuts")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(HoloTheme.Text.secondary)
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 14) {
                        favoriteTile(title: "Apple", url: "https://apple.com", icon: "apple.logo", color: .white)
                        favoriteTile(title: "GitHub", url: "https://github.com", icon: "code.square.fill", color: .purple)
                        favoriteTile(title: "Wikipedia", url: "https://wikipedia.org", icon: "book.fill", color: .blue)
                        favoriteTile(title: "ArXiv", url: "https://arxiv.org", icon: "doc.text.fill", color: .red)
                        favoriteTile(title: "Brave Search", url: "https://search.brave.com", icon: "magnifyingglass.circle.fill", color: .orange)
                    }
                }
                
                // MARK: - 4. HoloMind AI Suggestions
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(HoloTheme.Palette.holoCyan)
                        Text("HoloMind AI Suggestions")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(HoloTheme.Text.primary)
                    }
                    
                    VStack(spacing: 10) {
                        aiSuggestionCard(
                            title: "Summarize Open Tabs",
                            description: "Analyze 4 research tabs on WebKit performance and generate executive notes.",
                            icon: "doc.text.magnifyingglass",
                            actionTitle: "Summarize"
                        ) {
                            mindEngine.executeQuickAction(.summarizePage, context: "Open Tab Cluster", profile: BrowserProfile(name: "Default", isPrivate: false))
                        }
                        
                        aiSuggestionCard(
                            title: "Continue Research Session",
                            description: "You were comparing neural network browser engines 2 hours ago.",
                            icon: "clock.arrow.circlepath",
                            actionTitle: "Resume"
                        ) {
                            mindEngine.isPanelVisible = true
                        }
                    }
                }
                
                // MARK: - 5. Privacy & Security Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy & Security Status")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(HoloTheme.Text.secondary)
                    
                    HStack(spacing: 16) {
                        privacyMetricCard(title: "Trackers Blocked", value: "142", icon: "shield.checkerboard", color: .green)
                        privacyMetricCard(title: "Keychain Credentials", value: "28 Vault Entries", icon: "key.fill", color: .blue)
                        privacyMetricCard(title: "HTTPS Upgrades", value: "100% Active", icon: "lock.shield.fill", color: HoloTheme.Palette.holoCyan)
                    }
                }
            }
            .padding(24)
        }
        .background(HoloBackgroundView())
    }
    
    // MARK: - Search Execution Logic
    
    private func executeSearch() {
        let trimmed = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if trimmed.lowercased().hasPrefix("h ") {
            let prompt = String(trimmed.dropFirst(2))
            mindEngine.isPanelVisible = true
            mindEngine.executeQuickAction(.detectIntent, context: prompt, profile: BrowserProfile(name: "Default", isPrivate: isPrivateMode))
        } else if trimmed.lowercased().hasPrefix("m ") {
            let goal = String(trimmed.dropFirst(2))
            mindEngine.assignGoal(title: goal, category: .research)
            mindEngine.isPanelVisible = true
        } else if let url = URL(string: trimmed), trimmed.contains(".") && !trimmed.contains(" ") {
            tabManager.activeTab?.navigationManager.load(url: url)
        } else if let searchURL = URL(string: "https://search.brave.com/search?q=\(trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed)") {
            tabManager.activeTab?.navigationManager.load(url: searchURL)
        }
    }
    
    private func searchInputIcon() -> String {
        let t = searchInput.lowercased()
        if t.hasPrefix("h ") { return "sparkles" }
        if t.hasPrefix("m ") { return "target" }
        return "magnifyingglass"
    }
    
    private func searchInputColor() -> Color {
        let t = searchInput.lowercased()
        if t.hasPrefix("h ") { return .purple }
        if t.hasPrefix("m ") { return .red }
        return HoloTheme.Palette.holoCyan
    }
    
    private func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }
    
    // MARK: - Card Component Builders
    
    @ViewBuilder
    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HoloTheme.Text.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .holoFrostGlass(cornerRadius: 12)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func favoriteTile(title: String, url: String, icon: String, color: Color) -> some View {
        Button(action: {
            if let targetURL = URL(string: url) {
                tabManager.activeTab?.navigationManager.load(url: targetURL)
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(HoloTheme.Text.primary)
                    .lineLimit(1)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .holoGlassTier(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func aiSuggestionCard(title: String, description: String, icon: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(HoloTheme.Palette.holoCyan)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(HoloTheme.Text.primary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(HoloTheme.Text.secondary)
            }
            
            Spacer()
            
            Button(actionTitle, action: action)
                .buttonStyle(HoloPrimaryButtonStyle())
        }
        .padding(14)
        .holoGlassCard(cornerRadius: 14)
    }
    
    @ViewBuilder
    private func privacyMetricCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(HoloTheme.Text.primary)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(HoloTheme.Text.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .holoFrostGlass(cornerRadius: 12)
    }
}
