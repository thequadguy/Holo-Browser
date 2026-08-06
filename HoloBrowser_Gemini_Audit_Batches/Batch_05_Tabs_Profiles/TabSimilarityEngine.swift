import Foundation

/// Fast on-device similarity scoring engine for open tabs.
/// Detects topic overlap, duplicate URLs, and stale tabs without network calls.
@MainActor
public enum TabSimilarityEngine {
    
    public static func similarityScore(tabA: Tab, tabB: Tab) -> Double {
        guard let hostA = tabA.url?.host?.lowercased(), let hostB = tabB.url?.host?.lowercased() else {
            return 0.0
        }
        
        if hostA == hostB { return 1.0 }
        
        let titleTokensA = Set(tabA.title.lowercased().split(separator: " ").map(String.init))
        let titleTokensB = Set(tabB.title.lowercased().split(separator: " ").map(String.init))
        
        let intersection = titleTokensA.intersection(titleTokensB)
        let union = titleTokensA.union(titleTokensB)
        
        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }
}
