import Foundation

/// Fast natural language search over local browser memory records.
public enum MemorySearch {
    
    public static func search(_ query: String, in memories: [VisitedPageMemory]) -> [VisitedPageMemory] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return memories }
        
        let terms = trimmed.split(separator: " ").map { String($0) }
        
        return memories.filter { memory in
            let haystack = (memory.title + " " + memory.urlString + " " + memory.summary).lowercased()
            return terms.allSatisfy { term in haystack.contains(term) }
        }
    }
}
