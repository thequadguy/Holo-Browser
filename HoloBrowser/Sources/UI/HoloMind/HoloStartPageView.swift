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
            
            VStack(spacing: 32) {
                Spacer()
                
                // 2. Glowing Orb Icon (Inspired by reference design)
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "38BDF8").opacity(0.35), Color(hex: "2563EB").opacity(0.15), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "60A5FA").opacity(0.30), Color(hex: "2563EB").opacity(0.20)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(HoloTheme.Palette.crystalSpecularGradient, lineWidth: 1)
                        )
                        .shadow(color: Color(hex: "38BDF8").opacity(0.4), radius: 16)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(HoloTheme.Palette.holoBlueTextGradient)
                }
                
                // 3. Welcome State with Iridescent Blue Typography
                VStack(spacing: 8) {
                    Text("Holo Browser")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(HoloTheme.Palette.holoBlueTextGradient)
                        .shadow(color: Color(hex: "38BDF8").opacity(0.4), radius: 12, x: 0, y: 2)
                    
                    Text("Browse into the FUTURE, with AI powered browsing")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.70))
                }
                
                // 4. Feature Badges (Matching iBrowsy screenshot)
                HStack(spacing: 20) {
                    featureBadge(icon: "sparkles", label: "AI Powered", color: Color(hex: "A855F7"))
                    featureBadge(icon: "shield.fill", label: "AI Ad Blocker", color: Color(hex: "38BDF8"))
                    featureBadge(icon: "scribble.variable", label: "Sketch Mode", color: Color(hex: "60A5FA"))
                    featureBadge(icon: "square.split.2x1", label: "Split View", color: Color(hex: "34D399"))
                }
                .padding(.top, 4)
                
                // 5. Action Buttons (New Tab glowing blue button & AI Assistant glass button)
                HStack(spacing: 16) {
                    Button(action: {
                        _ = tabManager.createNewTab()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("New Tab")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "2563EB"), Color(hex: "3B82F6"), Color(hex: "38BDF8")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                            }
                        )
                        .shadow(color: Color(hex: "3B82F6").opacity(0.5), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        HoloEventBus.shared.post(.smartSearchAI(query: ""))
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 14, weight: .semibold))
                            Text("AI Assistant")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.10))
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.20), lineWidth: 0.5)
                            }
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
                
                // 6. Central Search / Command Field
                HStack(spacing: 12) {
                    Image(systemName: searchInputIcon())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(searchInputColor())
                    
                    TextField("Search the web, or type 'h' to ask HoloMind", text: $searchInput, onCommit: executeSearch)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular))
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
                            .foregroundColor(Color(hex: "38BDF8"))
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                            .overlay(Circle().stroke(Color(hex: "38BDF8").opacity(0.35), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Ask HoloMind")
                }
                .padding(.leading, 20)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: 620)
                .background(
                    ZStack {
                        VisualEffectViewWrapper(material: .headerView, blendingMode: .behindWindow)
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(HoloTheme.Palette.crystalSpecularGradient, lineWidth: 0.8)
                    }
                )
                .shadow(color: isSearchFocused ? Color(hex: "38BDF8").opacity(0.3) : Color.black.opacity(0.15), radius: isSearchFocused ? 16 : 8, y: isSearchFocused ? 8 : 4)
                .scaleEffect(isSearchFocused ? 1.01 : 1.0)
                .animation(HoloDesign.Animations.springFast, value: isSearchFocused)
                
                // 7. Frequent / Recent Sites
                HStack(spacing: 20) {
                    favoriteTile(title: "Apple", url: "https://apple.com", icon: "apple.logo", color: .white)
                    favoriteTile(title: "YouTube", url: "https://youtube.com", icon: "play.rectangle.fill", color: .red)
                    favoriteTile(title: "GitHub", url: "https://github.com", icon: "chevron.left.forwardslash.chevron.right", color: .white)
                    favoriteTile(title: "Reddit", url: "https://reddit.com", icon: "bubble.left.fill", color: .orange)
                    favoriteTile(title: "Wikipedia", url: "https://wikipedia.org", icon: "book.fill", color: .white)
                }
                .padding(.top, 4)
                
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
    private func featureBadge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            ZStack {
                VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                Capsule()
                    .fill(Color.white.opacity(0.06))
                Capsule()
                    .stroke(color.opacity(0.4), lineWidth: 0.8)
            }
        )
        .shadow(color: color.opacity(0.2), radius: 6, y: 2)
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

/// Atmospheric blue slate background specific to the start page matching the reference design
private struct StartPageBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "0F172A"),
                    Color(hex: "1E293B"),
                    Color(hex: "0F172A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(hex: "38BDF8").opacity(0.18),
                    Color(hex: "2563EB").opacity(0.08),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0,
                endRadius: 500
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
