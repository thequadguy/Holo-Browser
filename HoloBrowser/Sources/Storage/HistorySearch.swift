import Foundation

/// Fast natural language search utility matching browsing history entries.
public enum HistorySearch {
    
    public static func search(_ query: String, in entries: [HistoryItem]) -> [HistoryItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return entries }
        
        let terms = trimmed.split(separator: " ").map { String($0) }
        
        return entries.filter { entry in
            let haystack = (entry.title + " " + entry.urlString).lowercased()
            return terms.allSatisfy { term in haystack.contains(term) }
        }
    }
}
