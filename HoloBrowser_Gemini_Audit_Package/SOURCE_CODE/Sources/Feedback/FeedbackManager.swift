import Foundation
import Combine

/// Manages beta feedback reports and bug submissions.
@MainActor
public final class FeedbackManager: ObservableObject {
    public static let shared = FeedbackManager()
    
    @Published public private(set) var submittedReports: [FeedbackReport] = []
    
    private init() {}
    
    public func submitFeedback(type: FeedbackType, summary: String, details: String, includeDiagnostics: Bool) {
        let report = FeedbackReport(
            id: UUID(),
            type: type,
            summary: summary,
            details: details,
            diagnostics: includeDiagnostics ? DiagnosticsExporter.generateSanitizedReport() : nil,
            submittedAt: Date()
        )
        
        submittedReports.append(report)
        PrivacyAnalyticsManager.shared.logEvent("FeedbackSubmitted", metadata: ["type": type.rawValue])
    }
    
    public enum FeedbackType: String, CaseIterable, Identifiable {
        case bugReport = "Bug Report"
        case featureRequest = "Feature Request"
        case usabilityFeedback = "Usability Feedback"
        
        public var id: String { rawValue }
    }
    
    public struct FeedbackReport: Identifiable {
        public let id: UUID
        public let type: FeedbackType
        public let summary: String
        public let details: String
        public let diagnostics: String?
        public let submittedAt: Date
    }
}
