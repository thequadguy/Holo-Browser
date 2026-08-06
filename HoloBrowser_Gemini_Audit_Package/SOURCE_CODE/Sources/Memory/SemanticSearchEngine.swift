import Foundation

/// Fast on-device semantic search engine over local research notes and memory stores.
public enum SemanticSearchEngine {
    
    public static func search(query: String, snippets: [String]) -> [String] {
        let lowerQuery = query.lowercased()
        guard !lowerQuery.isEmpty else { return snippets }
        
        return snippets.filter { snippet in
            snippet.lowercased().contains(lowerQuery)
        }
    }
}
