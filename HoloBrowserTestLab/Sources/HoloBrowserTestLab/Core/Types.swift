import Foundation

public enum TestCategory: String, CaseIterable, Codable {
    case launch = "1. Launch"
    case navigation = "2. Navigation"
    case search = "3. Search"
    case bookmarks = "4. Bookmarks"
    case downloads = "5. Downloads"
    case history = "6. History"
    case settings = "7. Settings"
    case holoMind = "8. HoloMind"
    case keyboardShortcuts = "9. Keyboard Shortcuts"
    case contextMenus = "10. Context Menus"
    case stress = "11. Stress"
    case crashRecovery = "12. Crash Recovery"
    case visual = "13. Visual"
    case performance = "14. Performance"
    case accessibility = "15. Accessibility"
}

public enum Severity: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

public struct TestCaseResult: Codable {
    public let id: String
    public let name: String
    public let category: TestCategory
    public let passed: Bool
    public let durationSeconds: Double
    public let details: String
    public let warning: String?
    public let screenshotPath: String?
    public let failureReason: String?

    public init(id: String, name: String, category: TestCategory, passed: Bool, durationSeconds: Double, details: String, warning: String? = nil, screenshotPath: String? = nil, failureReason: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.passed = passed
        self.durationSeconds = durationSeconds
        self.details = details
        self.warning = warning
        self.screenshotPath = screenshotPath
        self.failureReason = failureReason
    }
}

public struct BugReport: Codable {
    public let testName: String
    public let expected: String
    public let actual: String
    public let screenshot: String
    public let likelyCause: String
    public let possibleFiles: [String]
    public let severity: Severity
}

public struct PerformanceMetrics: Codable {
    public var launchTimeMs: Double
    public var pageLoadMs: Double
    public var tabSwitchMs: Double
    public var ramUsageMB: Double
    public var cpuUsagePercent: Double
    public var estimatedFPS: Double
}

public struct FinalScorecard: Codable {
    public let testsPassed: Int
    public let testsFailed: Int
    public let warnings: Int
    public let totalTests: Int
    public let coveragePercent: Double
    public let criticalBugs: Int
    public let betaReady: Bool
    public let performanceSummary: PerformanceMetrics
}
