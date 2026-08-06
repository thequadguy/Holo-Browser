import Foundation

public struct InsightScore: Equatable {
    public let relevance: Double
    public let urgency: Double
    public let confidence: Double
    public let userBenefit: Double
    
    public var overallScore: Double {
        return (relevance * 0.4) + (urgency * 0.3) + (confidence * 0.2) + (userBenefit * 0.1)
    }
}

@MainActor
public final class HoloInsightRankingEngine {
    public static let shared = HoloInsightRankingEngine()
    
    // Configurable threshold (governed by Settings "Proactive Intelligence")
    // Maximum: 0.3, Balanced: 0.75, Minimal: 0.90
    public var threshold: Double = 0.75
    
    private init() {}
    
    public func evaluate(insight: HoloInsightCard, relevance: Double, urgency: Double, confidence: Double, userBenefit: Double) -> HoloInsightCard? {
        let score = InsightScore(relevance: relevance, urgency: urgency, confidence: confidence, userBenefit: userBenefit)
        
        if score.overallScore >= threshold {
            return insight
        }
        return nil // Suppress spam
    }
}
