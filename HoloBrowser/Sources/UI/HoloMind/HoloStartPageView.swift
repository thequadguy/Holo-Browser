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
    @FocusState private var isSearchFocused: Bool
    
    public init(mindEngine: HoloMindEngine, tabManager: TabManager, currentProfileID: UUID, isPrivateMode: Bool) {
        self.mindEngine = mindEngine
        self.tabManager = tabManager
        self.currentProfileID = currentProfileID
        self.isPrivateMode = isPrivateMode
    }
    
    public var body: some View {
        ZStack {
            // 1. Dark Atmospheric Background
            StartPageBackgroundView()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 2. Welcome State
                VStack(spacing: 8) {
                    Text("Holo Browser")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.9))
                    
                    Text("The web, intelligently connected.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                // 3. Central Search / Command Field
                HStack(spacing: 12) {
                    Image(systemName: searchInputIcon())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(searchInputColor())
                    
                    TextField("Search the web, or type 'h' to ask HoloMind", text: $searchInput, onCommit: executeSearch)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                        .focused($isSearchFocused)
                    
                    if !searchInput.isEmpty {
                        Button(action: { searchInput = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // HoloMind Sparkle Toggle
                    Button(action: {
                        HoloEventBus.shared.post(.smartSearchAI(query: ""))
                    }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.purple)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Ask HoloMind")
                }
                .padding(.leading, 20)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: 640)
                .holoDeepGlass(cornerRadius: 24)
                .shadow(color: isSearchFocused ? Color.black.opacity(0.4) : Color.black.opacity(0.15), radius: isSearchFocused ? 16 : 8, y: isSearchFocused ? 8 : 4)
                .scaleEffect(isSearchFocused ? 1.01 : 1.0)
                .animation(HoloDesign.Animations.springFast, value: isSearchFocused)
                
                // 4. Frequent / Recent Sites
                HStack(spacing: 20) {
                    favoriteTile(title: "Apple", url: "https://apple.com", icon: "apple.logo", color: .white)
                    favoriteTile(title: "YouTube", url: "https://youtube.com", icon: "play.rectangle.fill", color: .red)
                    favoriteTile(title: "GitHub", url: "https://github.com", icon: "chevron.left.forwardslash.chevron.right", color: .white)
                    favoriteTile(title: "Reddit", url: "https://reddit.com", icon: "bubble.left.fill", color: .orange)
                    favoriteTile(title: "Wikipedia", url: "https://wikipedia.org", icon: "book.fill", color: .white)
                }
                .padding(.top, 10)
                
                // 5. Quick Actions
                HStack(spacing: 24) {
                    quickActionTextButton(title: "New Workspace") {
                        _ = tabManager.createNewTab()
                    }
                    quickActionTextButton(title: "Open Bookmarks") {
                        // Hook into bookmark manager when implemented
                    }
                    quickActionTextButton(title: "Continue Browsing") {
                        // Future implementation
                    }
                    quickActionTextButton(title: "Ask HoloMind") {
                        HoloEventBus.shared.post(.smartSearchAI(query: ""))
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                Spacer()
            }
        }
    }
    
    // MARK: - Search Execution Logic
    
    private func executeSearch() {
        let trimmed = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if trimmed.lowercased().hasPrefix("h ") {
            let prompt = String(trimmed.dropFirst(2))
            HoloEventBus.shared.post(.smartSearchAI(query: ""))
            mindEngine.executeQuickAction(.detectIntent, context: prompt, profile: BrowserProfile(name: "Default", isPrivate: isPrivateMode))
        } else if trimmed.lowercased().hasPrefix("m ") {
            let goal = String(trimmed.dropFirst(2))
            mindEngine.assignGoal(title: goal, category: .research)
            HoloEventBus.shared.post(.smartSearchAI(query: ""))
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
        return Color.white.opacity(0.6)
    }
    
    // MARK: - Component Builders
    
    @ViewBuilder
    private func favoriteTile(title: String, url: String, icon: String, color: Color) -> some View {
        Button(action: {
            if let targetURL = URL(string: url) {
                tabManager.activeTab?.navigationManager.load(url: targetURL)
            }
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
            }
        }
        .buttonStyle(CrystalTileButtonStyle())
    }
    
    @ViewBuilder
    private func quickActionTextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.5))
        }
        .buttonStyle(QuickActionButtonStyle())
    }
}

/// Atmospheric dark background specific to the start page
private struct StartPageBackgroundView: View {
    var body: some View {
        ZStack {
            // Base dark tone
            Color(red: 0.05, green: 0.05, blue: 0.06)
                .ignoresSafeArea()
            
            // Subtle ambient violet/blue dispersion in the center
            RadialGradient(
                colors: [Color.purple.opacity(0.08), Color.blue.opacity(0.04), .clear],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .blendMode(.screen)
            .ignoresSafeArea()
        }
    }
}

private struct CrystalTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(configuration.isPressed ? 0.2 : 0)
            .animation(HoloDesign.Animations.springFast, value: configuration.isPressed)
    }
}

private struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(HoloDesign.Animations.springFast, value: configuration.isPressed)
    }
}
