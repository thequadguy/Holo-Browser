import Foundation
import Combine

public struct TabGroupSuggestion: Identifiable, Equatable {
    public let id: UUID
    public let categoryName: String
    public let tabIDs: [UUID]
    
    public init(id: UUID = UUID(), categoryName: String, tabIDs: [UUID]) {
        self.id = id
        self.categoryName = categoryName
        self.tabIDs = tabIDs
    }
}

/// Smart tab intelligence engine performing local-first tab classification, duplicate detection, and undoable grouping recommendations.
@MainActor
public final class SmartTabManager: ObservableObject {
    public static let shared = SmartTabManager()
    
    @Published public private(set) var suggestions: [TabGroupSuggestion] = []
    @Published public private(set) var previousGroupsState: [TabGroupSuggestion] = []
    @Published public private(set) var manualOverrides: [UUID: String] = [:]
    
    public init() {}
    
    /// Analyzes up to 200+ tabs locally under their active profile identity.
    public func analyzeTabs(_ tabs: [Tab], activeProfileID: UUID? = nil) {
        var groups: [String: [UUID]] = [
            "Work & Tech": [],
            "Shopping": [],
            "News & Media": [],
            "Research & Docs": [],
            "Personal": []
        ]
        
        for tab in tabs {
            // Respect manual overrides if present
            if let customGroup = manualOverrides[tab.id] {
                groups[customGroup, default: []].append(tab.id)
                continue
            }
            
            let title = tab.title.lowercased()
            let url = (tab.url?.absoluteString ?? "").lowercased()
            
            if title.contains("github") || title.contains("swift") || title.contains("stack") || title.contains("code") || url.contains("developer") {
                groups["Work & Tech"]?.append(tab.id)
            } else if title.contains("amazon") || title.contains("buy") || title.contains("shop") || url.contains("store") {
                groups["Shopping"]?.append(tab.id)
            } else if title.contains("wikipedia") || title.contains("arxiv") || title.contains("docs") || url.contains("pdf") {
                groups["Research & Docs"]?.append(tab.id)
            } else if title.contains("news") || title.contains("reddit") || title.contains("medium") || title.contains("yt") {
                groups["News & Media"]?.append(tab.id)
            } else {
                groups["Personal"]?.append(tab.id)
            }
        }
        
        self.previousGroupsState = self.suggestions
        self.suggestions = groups.compactMap { key, ids in
            guard !ids.isEmpty else { return nil }
            return TabGroupSuggestion(categoryName: key, tabIDs: ids)
        }
    }
    
    /// Manually assign a tab to a specific category override.
    public func overrideCategory(for tabID: UUID, categoryName: String) {
        manualOverrides[tabID] = categoryName
    }
    
    /// Reverts the previous grouping action (Undo).
    public func undoGrouping() {
        self.suggestions = self.previousGroupsState
    }
    
    /// Detect duplicate tabs across open sessions.
    public func findDuplicateTabs(_ tabs: [Tab]) -> [Tab] {
        var seenURLs = Set<String>()
        var duplicates: [Tab] = []
        
        for tab in tabs {
            if let urlString = tab.url?.absoluteString, !urlString.isEmpty {
                if seenURLs.contains(urlString) {
                    duplicates.append(tab)
                } else {
                    seenURLs.insert(urlString)
                }
            }
        }
        return duplicates
    }
}
