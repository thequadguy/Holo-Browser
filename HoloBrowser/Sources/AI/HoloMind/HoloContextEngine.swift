import Foundation

public struct BrowserResearchSession: Identifiable, Equatable {
    public let id: UUID
    public let topic: String
    public let tabIDs: [UUID]
    public let domainHosts: [String]
    public let timestamp: Date
    
    public init(id: UUID = UUID(), topic: String, tabIDs: [UUID], domainHosts: [String], timestamp: Date = Date()) {
        self.id = id
        self.topic = topic
        self.tabIDs = tabIDs
        self.domainHosts = domainHosts
        self.timestamp = timestamp
    }
}

public struct UnfinishedTask: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let detail: String
    public let tabID: UUID?
    public let urgency: String
    
    public init(id: UUID = UUID(), title: String, detail: String, tabID: UUID? = nil, urgency: String = "Normal") {
        self.id = id
        self.title = title
        self.detail = detail
        self.tabID = tabID
        self.urgency = urgency
    }
}

/// Real-time analyzer monitoring browser tab topology, identifying research sessions, open task clusters, and duplicate resources.
@MainActor
public final class HoloContextEngine: ObservableObject {
    @Published public private(set) var activeResearchSessions: [BrowserResearchSession] = []
    @Published public private(set) var detectedUnfinishedTasks: [UnfinishedTask] = []
    @Published public private(set) var duplicateTabCount: Int = 0
    
    public init() {}
    
    /// Analyzes current open tabs and groups them into research sessions and unfinished task lists.
    public func analyzeContext(tabs: [Tab]) {
        var sessions: [BrowserResearchSession] = []
        var unfinished: [UnfinishedTask] = []
        var domainMap: [String: [UUID]] = [:]
        
        for tab in tabs {
            if let host = tab.domainHost?.lowercased() {
                domainMap[host, default: []].append(tab.id)
            }
            
            // Identify shopping / form / documentation tasks
            let title = tab.title.lowercased()
            if title.contains("checkout") || title.contains("cart") || title.contains("bag") {
                unfinished.append(UnfinishedTask(title: "Unfinished Shopping Checkout", detail: tab.title, tabID: tab.id, urgency: "High"))
            } else if title.contains("docs") || title.contains("pull request") || title.contains("issue") {
                unfinished.append(UnfinishedTask(title: "Open Developer Task", detail: tab.title, tabID: tab.id, urgency: "Medium"))
            }
        }
        
        // Group domains with >= 2 tabs into research sessions
        for (host, tabIDs) in domainMap where tabIDs.count >= 2 {
            sessions.append(BrowserResearchSession(topic: "\(host.capitalized) Deep Dive", tabIDs: tabIDs, domainHosts: [host]))
        }
        
        let duplicateCount = tabs.count - domainMap.keys.count
        
        self.activeResearchSessions = sessions
        self.detectedUnfinishedTasks = unfinished
        self.duplicateTabCount = max(0, duplicateCount)
    }
}
