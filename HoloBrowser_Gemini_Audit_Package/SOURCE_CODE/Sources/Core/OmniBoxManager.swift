import Foundation

public struct OmniSuggestion: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let urlString: String
    public let source: String
    
    public init(id: UUID = UUID(), title: String, urlString: String, source: String) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.source = source
    }
}

/// Smart address bar ranking engine evaluating history matches, bookmarks, and open tab titles.
@MainActor
public enum OmniBoxManager {
    
    public static func rankSuggestions(
        query: String,
        history: [HistoryItem],
        bookmarks: [BookmarkItem],
        tabs: [Tab]
    ) -> [OmniSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        
        var results: [OmniSuggestion] = []
        
        // Open Tab Matches
        for tab in tabs {
            if tab.title.lowercased().contains(trimmed) || (tab.url?.absoluteString.lowercased().contains(trimmed) ?? false) {
                results.append(OmniSuggestion(title: tab.title, urlString: tab.url?.absoluteString ?? "", source: "Open Tab"))
            }
        }
        
        // Bookmark Matches
        for bm in bookmarks {
            if bm.title.lowercased().contains(trimmed) || bm.urlString.lowercased().contains(trimmed) {
                results.append(OmniSuggestion(title: bm.title, urlString: bm.urlString, source: "Bookmark"))
            }
        }
        
        // History Matches
        for h in history {
            if h.title.lowercased().contains(trimmed) || h.urlString.lowercased().contains(trimmed) {
                results.append(OmniSuggestion(title: h.title, urlString: h.urlString, source: "History"))
            }
        }
        
        return Array(results.prefix(5))
    }
}
