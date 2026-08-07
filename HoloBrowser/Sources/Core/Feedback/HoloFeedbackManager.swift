import SwiftUI
import AppKit
import WebKit

/// Enum defining feedback report types.
public enum HoloFeedbackType: String, CaseIterable, Identifiable {
    case bugReport = "Bug Report"
    case featureSuggestion = "Feature Suggestion"
    case generalFeedback = "General Feedback"
    
    public var id: String { rawValue }
}

/// Data structure representing a sanitized user feedback report.
public struct HoloFeedbackReport: Codable, Identifiable {
    public let id: UUID
    public let type: String
    public let userComments: String
    public let appVersion: String
    public let osVersion: String
    public let webKitVersion: String
    public let memoryFootprintMB: Double
    public let timestamp: Date
    
    public init(
        type: String,
        userComments: String,
        appVersion: String,
        osVersion: String,
        webKitVersion: String,
        memoryFootprintMB: Double,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.type = type
        self.userComments = userComments
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.webKitVersion = webKitVersion
        self.memoryFootprintMB = memoryFootprintMB
        self.timestamp = timestamp
    }
}

/// In-app feedback submission manager for Holo Browser V1.7.
@MainActor
public final class HoloFeedbackManager: ObservableObject {
    public static let shared = HoloFeedbackManager()
    
    @Published public var isFeedbackSheetPresented: Bool = false
    @Published public var feedbackType: HoloFeedbackType = .bugReport
    @Published public var userComments: String = ""
    @Published var lastSubmittedReport: HoloFeedbackReport? = nil
    
    private init() {}
    
    public var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.7.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "100"
        return "\(version) (\(build))"
    }
    
    public var macOSVersionString: String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
    }
    
    public var webKitVersionString: String {
        return "WebKit 605.1.15 (macOS Sonoma Standard)"
    }
    
    public func submitFeedback() {
        guard !userComments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let report = HoloFeedbackReport(
            type: feedbackType.rawValue,
            userComments: userComments,
            appVersion: appVersionString,
            osVersion: macOSVersionString,
            webKitVersion: webKitVersionString,
            memoryFootprintMB: 98.5
        )
        
        self.lastSubmittedReport = report
        self.userComments = ""
        self.isFeedbackSheetPresented = false
    }
}
