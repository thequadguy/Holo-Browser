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

/// Proactive opportunity engine scanning browser activity to generate timeline insights and workflow suggestions.
///
/// Insights are generated exclusively from real-time browser state analysis via `scan(tabs:contextEngine:)`.
/// No seeded, hardcoded, or synthetic insights are ever presented — every card reflects actual user activity.
@MainActor
public final class HoloOpportunityEngine: ObservableObject {
    @Published public private(set) var insightStream: [HoloInsightCard] = []

    /// True when at least one `scan()` pass has been completed, used by the UI to distinguish
    /// "not yet analyzed" from "analyzed and nothing found."
    @Published public private(set) var hasPerformedInitialScan: Bool = false

    public init() {
        // insightStream starts empty. Real insights are produced only by scan().
    }

    /// Analyzes current tab state and appends any newly discovered insights.
    /// Duplicate titles are deduplicated so repeated scans don't stack identical cards.
    public func scan(tabs: [Tab], contextEngine: HoloContextEngine) {
        var newInsights: [HoloInsightCard] = []

        // Tab clutter insight — only fire when meaningful duplicate count is present.
        if contextEngine.duplicateTabCount > 0 {
            let clutterInsight = HoloInsightCard(
                kind: .tabClutter,
                title: "Duplicate Domain Clutter",
                summary: "You have \(contextEngine.duplicateTabCount) duplicate or closely related tabs open.",
                reason: "You've opened multiple tabs from the same domain without closing them.",
                recommendedActionTitle: "Consolidate Tabs"
            )
            if let ranked = HoloInsightRankingEngine.shared.evaluate(
                insight: clutterInsight, relevance: 0.8, urgency: 0.4, confidence: 0.9, userBenefit: 0.6
            ) {
                newInsights.append(ranked)
            }
        }

        // Unfinished workflow insights derived from tab title analysis.
        for task in contextEngine.detectedUnfinishedTasks {
            let taskInsight = HoloInsightCard(
                kind: .unfinishedTask,
                title: task.title,
                summary: task.detail,
                reason: "You spent time on this but didn't complete a final action.",
                recommendedActionTitle: "Resume Workflow"
            )
            if let ranked = HoloInsightRankingEngine.shared.evaluate(
                insight: taskInsight, relevance: 0.9, urgency: 0.7, confidence: 0.8, userBenefit: 0.9
            ) {
                newInsights.append(ranked)
            }
        }

        // Append only genuinely new insights (deduplicate by title).
        for insight in newInsights {
            if !insightStream.contains(where: { $0.title == insight.title }) {
                insightStream.insert(insight, at: 0)
            }
        }

        hasPerformedInitialScan = true
    }

    public func dismissInsight(id: UUID) {
        insightStream.removeAll(where: { $0.id == id })
    }
}
