import Foundation
import Combine

/// Advanced local-first tab intelligence engine supporting 200-500 tabs.
@MainActor
public final class SmartTabEngine: ObservableObject {
    public static let shared = SmartTabEngine()
    
    @Published public private(set) var activeClusters: [String: [Tab]] = [:]
    @Published public private(set) var staleTabs: [Tab] = []
    @Published public private(set) var duplicateGroups: [String: [Tab]] = [:]
    
    private init() {}
    
    public func processTabPool(_ tabs: [Tab]) {
        var clusters: [String: [Tab]] = [:]
        var stale: [Tab] = []
        var duplicates: [String: [Tab]] = [:]
        
        for tab in tabs {
            let category = TabClassifier.classify(url: tab.url, title: tab.title)
            clusters[category, default: []].append(tab)
            
            // Stale tab detection: inactive in background
            if tab.state == .background {
                stale.append(tab)
            }
            
            if let normalized = normalizeURL(tab.url) {
                duplicates[normalized, default: []].append(tab)
            }
        }
        
        // Keep only actual duplicate groups (2+ tabs)
        let filteredDuplicates = duplicates.filter { $0.value.count > 1 }
        
        self.activeClusters = clusters
        self.staleTabs = stale
        self.duplicateGroups = filteredDuplicates
    }
    
    /// Normalizes URL for duplicate tab detection by stripping query tracking params, trailing slashes, and fragments.
    public func normalizeURL(_ url: URL?) -> String? {
        guard let url = url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        components.fragment = nil
        
        // Strip common tracking parameters
        if let queryItems = components.queryItems {
            let trackingParams: Set<String> = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "fbclid", "gclid", "ref"]
            let filtered = queryItems.filter { !trackingParams.contains($0.name.lowercased()) }
            components.queryItems = filtered.isEmpty ? nil : filtered
        }
        
        var path = components.path
        if path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        components.path = path
        
        return components.string
    }
    
    /// Generates non-destructive Space suggestion based on cluster density.
    public func suggestSpace(from tabs: [Tab]) -> (name: String, category: String, tabIDs: [UUID])? {
        processTabPool(tabs)
        guard let (category, clusterTabs) = activeClusters.max(by: { $0.value.count < $1.value.count }),
              clusterTabs.count >= 3 else { return nil }
        
        let spaceName = "\(category.capitalized) Space"
        return (name: spaceName, category: category, tabIDs: clusterTabs.map { $0.id })
    }
}

