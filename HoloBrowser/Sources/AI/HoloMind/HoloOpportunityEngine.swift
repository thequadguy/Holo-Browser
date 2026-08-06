import Foundation

public enum InsightKind: String, Codable {
    case priceDrop = "Price Drop Alert"
    case unfinishedTask = "Unfinished Workflow"
    case tabClutter = "Tab Organization"
    case recommendation = "Proactive Advice"
}

public struct HoloInsightCard: Identifiable, Codable, Equatable {
    public let id: UUID
    public let kind: InsightKind
    public let title: String
    public let summary: String
    public let recommendedActionTitle: String?
    public let reason: String
    public let timestamp: Date
    public var isDismissed: Bool
    
    public init(
        id: UUID = UUID(),
        kind: InsightKind,
        title: String,
        summary: String,
        reason: String,
        recommendedActionTitle: String? = nil,
        timestamp: Date = Date(),
        isDismissed: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.summary = summary
        self.reason = reason
        self.recommendedActionTitle = recommendedActionTitle
        self.timestamp = timestamp
        self.isDismissed = isDismissed
    }
}

/// Proactive opportunity engine scanning browser activity to generate timeline insights, price alerts, and workflow suggestions.
@MainActor
public final class HoloOpportunityEngine: ObservableObject {
    @Published public private(set) var insightStream: [HoloInsightCard] = []
    
    public init() {
        populateInitialInsights()
    }
    
    public func scan(tabs: [Tab], contextEngine: HoloContextEngine) {
        var newInsights: [HoloInsightCard] = []
        
        // Tab clutter insight
        if contextEngine.duplicateTabCount > 0 {
            let clutterInsight = HoloInsightCard(
                kind: .tabClutter,
                title: "Duplicate Domain Clutter",
                summary: "You have \(contextEngine.duplicateTabCount) duplicate or closely related tabs open.",
                reason: "Because you've opened multiple tabs from the same domain without closing them.",
                recommendedActionTitle: "Consolidate Tabs"
            )
            
            if let ranked = HoloInsightRankingEngine.shared.evaluate(insight: clutterInsight, relevance: 0.8, urgency: 0.4, confidence: 0.9, userBenefit: 0.6) {
                newInsights.append(ranked)
            }
        }
        
        // Unfinished checkout insight
        for task in contextEngine.detectedUnfinishedTasks {
            let taskInsight = HoloInsightCard(
                kind: .unfinishedTask,
                title: task.title,
                summary: task.detail,
                reason: "Because you spent time researching this but didn't complete a final action.",
                recommendedActionTitle: "Resume Workflow"
            )
            
            if let ranked = HoloInsightRankingEngine.shared.evaluate(insight: taskInsight, relevance: 0.9, urgency: 0.7, confidence: 0.8, userBenefit: 0.9) {
                newInsights.append(ranked)
            }
        }
        
        for insight in newInsights {
            if !insightStream.contains(where: { $0.title == insight.title }) {
                insightStream.insert(insight, at: 0)
            }
        }
    }
    
    public func dismissInsight(id: UUID) {
        insightStream.removeAll(where: { $0.id == id })
    }
    
    private func populateInitialInsights() {
        insightStream = [
            HoloInsightCard(
                kind: .recommendation,
                title: "Welcome to HoloMind Chief of Staff",
                summary: "H is ready to manage your research goals, track price drops, and keep your browser organized.",
                reason: "Initial onboarding suggestion.",
                recommendedActionTitle: "Create Goal"
            ),
            HoloInsightCard(
                kind: .priceDrop,
                title: "Apple M3 MacBook Pro Price Drop",
                summary: "Detected a 12% price reduction on tracked retailer site.",
                reason: "Because you viewed this product 5 times this week.",
                recommendedActionTitle: "View Deal"
            )
        ]
    }
}
