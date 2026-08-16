import Foundation
import Combine
import SwiftUI

@MainActor
public final class OmniboxViewModel: ObservableObject {
    @Published public var query: String = ""
    @Published public var suggestions: [OmniboxSuggestion] = []
    @Published public var selectedIndex: Int = -1
    
    private let historyStore = HistoryStore()
    private let bookmarkStore = BookmarkStore()
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Provide initial empty state suggestions
        setupEmptyState()
        
        $query
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] newQuery in
                self?.updateSuggestions(for: newQuery)
            }
            .store(in: &cancellables)
    }
    
    public func resetState() {
        query = ""
        selectedIndex = -1
        setupEmptyState()
    }
    
    public func selectCurrentURL(_ urlString: String) {
        query = urlString
        selectedIndex = -1
        updateSuggestions(for: urlString)
    }
    
    private func setupEmptyState() {
        self.suggestions = [
            OmniboxSuggestion(type: .search(query: ""), title: "Search the web", subtitle: nil, icon: "magnifyingglass", iconColor: .secondary),
            OmniboxSuggestion(type: .navigation(url: URL(string: "https://")!), title: "Open a website", subtitle: nil, icon: "globe", iconColor: .secondary),
            OmniboxSuggestion(type: .holomind(prompt: ""), title: "Ask HoloMind", subtitle: "h <prompt>", icon: "sparkles", iconColor: HoloTheme.Palette.holoCyan),
            OmniboxSuggestion(type: .mission(goal: ""), title: "Start a Mission", subtitle: "m <goal>", icon: "target", iconColor: HoloTheme.Palette.holoEmerald)
        ]
        self.selectedIndex = -1
    }
    
    public func updateSuggestions(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            setupEmptyState()
            return
        }
        
        var newSuggestions: [OmniboxSuggestion] = []
        
        // 1. Primary Intent via HoloSmartSearchRouter
        let route = HoloSmartSearchRouter.route(for: query)
        switch route {
        case .web(let url):
            if url.host?.contains("search.brave.com") == true && !trimmed.hasPrefix("http") && !trimmed.contains(".") {
                newSuggestions.append(OmniboxSuggestion(
                    type: .search(query: trimmed),
                    title: "Search the web for \"\(trimmed)\"",
                    subtitle: nil,
                    icon: "magnifyingglass",
                    iconColor: .secondary
                ))
            } else {
                newSuggestions.append(OmniboxSuggestion(
                    type: .navigation(url: url),
                    title: "Open \(url.host ?? trimmed)",
                    subtitle: url.absoluteString,
                    icon: "globe",
                    iconColor: .secondary
                ))
            }
        case .ai(let aiQuery, _):
            newSuggestions.append(OmniboxSuggestion(
                type: .holomind(prompt: aiQuery),
                title: "Ask HoloMind",
                subtitle: aiQuery.isEmpty ? "Type a prompt..." : aiQuery,
                icon: "sparkles",
                iconColor: HoloTheme.Palette.holoCyan
            ))
        case .mission(let missionGoal):
            newSuggestions.append(OmniboxSuggestion(
                type: .mission(goal: missionGoal),
                title: "Start Mission",
                subtitle: missionGoal.isEmpty ? "Type a goal..." : missionGoal,
                icon: "target",
                iconColor: HoloTheme.Palette.holoEmerald
            ))
        }
        
        // 2. History & Bookmarks (Synchronous for now, but fast array filter)
        // Only if it's not a direct HoloMind/Mission intent
        if !trimmed.hasPrefix("h ") && !trimmed.hasPrefix("H ") && !trimmed.hasPrefix("m ") && !trimmed.hasPrefix("M ") {
            let lowerQuery = trimmed.lowercased()
            
            // Bookmarks
            let matchingBookmarks = bookmarkStore.bookmarks.filter {
                $0.title.lowercased().contains(lowerQuery) || $0.urlString.lowercased().contains(lowerQuery)
            }.prefix(2)
            
            for bookmarkItem in matchingBookmarks {
                if let url = URL(string: bookmarkItem.urlString) {
                    newSuggestions.append(OmniboxSuggestion(
                        type: .bookmark(url: url),
                        title: bookmarkItem.title,
                        subtitle: bookmarkItem.urlString,
                        icon: "bookmark.fill",
                        iconColor: .yellow
                    ))
                }
            }
            
            // History
            let matchingHistory = historyStore.historyItems.filter {
                $0.title.lowercased().contains(lowerQuery) || $0.urlString.lowercased().contains(lowerQuery)
            }.prefix(3)
            
            for historyItem in matchingHistory where !newSuggestions.contains(where: {
                if case .navigation(let existingURL) = $0.type { return existingURL.absoluteString == historyItem.urlString }
                if case .bookmark(let existingURL) = $0.type { return existingURL.absoluteString == historyItem.urlString }
                return false
            }) {
                if let url = URL(string: historyItem.urlString) {
                    newSuggestions.append(OmniboxSuggestion(
                        type: .history(url: url),
                        title: historyItem.title,
                        subtitle: historyItem.urlString,
                        icon: "clock",
                        iconColor: .secondary
                    ))
                }
            }
        }
        
        self.suggestions = newSuggestions
        
        // Clamp selected index
        if selectedIndex >= self.suggestions.count {
            selectedIndex = self.suggestions.count - 1
        }
    }
    
    // MARK: - Keyboard Navigation
    
    public func moveSelectionUp() {
        guard !suggestions.isEmpty else { return }
        if selectedIndex > -1 { // If -1, we loop to bottom
            selectedIndex -= 1
        } else {
            selectedIndex = suggestions.count - 1
        }
    }
    
    public func moveSelectionDown() {
        guard !suggestions.isEmpty else { return }
        if selectedIndex < suggestions.count - 1 {
            selectedIndex += 1
        } else {
            selectedIndex = -1 // Reset to top typing state
        }
    }
    
    public func executeSelected(browserViewModel: BrowserViewModel) -> Bool {
        // If nothing is selected via keyboard, execute the top suggestion or current query
        let itemToExecute: OmniboxSuggestion
        if selectedIndex >= 0 && selectedIndex < suggestions.count {
            itemToExecute = suggestions[selectedIndex]
        } else if !suggestions.isEmpty {
            itemToExecute = suggestions[0]
        } else {
            return false // No action possible
        }
        
        switch itemToExecute.type {
        case .navigation(let url), .history(let url), .bookmark(let url):
            browserViewModel.tabManager.activeTab?.navigationManager.load(url: url)
        case .search(let searchQuery):
            if let searchURL = URL(string: "https://search.brave.com/search?q=\(searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery)") {
                browserViewModel.tabManager.activeTab?.navigationManager.load(url: searchURL)
            }
        case .holomind(let prompt):
            if prompt.isEmpty {
                HoloEventBus.shared.post(.smartSearchAI(query: ""))
            } else {
                HoloEventBus.shared.post(.smartSearchAI(query: prompt))
                // Note: The UI layer in ContentView catches this and opens the AI sidebar.
                // We also need to send the prompt. AIManager or ContextManager typically handles the prompt.
                // But HoloSmartSearchRouter already has logic that ContentView uses for intent handling.
            }
        case .mission(let goal):
            HoloEventBus.shared.post(.smartSearchMission(query: goal))
        }
        
        return true
    }
}
