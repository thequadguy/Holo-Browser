import Foundation

/// Fast natural language indexer over history, notes, bookmarks, research, and memories.
public enum MemoryIndexer {
    
    public static func search(
        query: String,
        memories: [PersonalMemory],
        history: [HistoryItem],
        bookmarks: [BookmarkItem]
    ) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        
        var results: [String] = []
        
        for mem in memories {
            if mem.content.lowercased().contains(trimmed) {
                results.append("Memory (\(mem.category.rawValue)): \(mem.content)")
            }
        }
        
        for item in history {
            if item.title.lowercased().contains(trimmed) || item.urlString.lowercased().contains(trimmed) {
                results.append("History: \(item.title) - \(item.urlString)")
            }
        }
        
        for bm in bookmarks {
            if bm.title.lowercased().contains(trimmed) || bm.urlString.lowercased().contains(trimmed) {
                results.append("Bookmark: \(bm.title) - \(bm.urlString)")
            }
        }
        
        return results
    }
}
