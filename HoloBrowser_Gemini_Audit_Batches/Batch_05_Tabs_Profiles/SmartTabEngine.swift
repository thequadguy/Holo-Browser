import Foundation
import Combine

/// Advanced local-first tab intelligence engine supporting 200-500 tabs.
@MainActor
public final class SmartTabEngine: ObservableObject {
    public static let shared = SmartTabEngine()
    
    @Published public private(set) var activeClusters: [String: [Tab]] = [:]
    @Published public private(set) var staleTabs: [Tab] = []
    
    private init() {}
    
    public func processTabPool(_ tabs: [Tab]) {
        var clusters: [String: [Tab]] = [:]
        var stale: [Tab] = []
        
        for tab in tabs {
            let category = TabClassifier.classify(url: tab.url, title: tab.title)
            clusters[category, default: []].append(tab)
            
            // Stale tab detection: inactive in background
            if tab.state == .background {
                stale.append(tab)
            }
        }
        
        self.activeClusters = clusters
        self.staleTabs = stale
    }
}
