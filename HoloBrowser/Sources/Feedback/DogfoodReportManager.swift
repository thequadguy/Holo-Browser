import Foundation
import Combine

public enum DogfoodCategory: String, Codable, CaseIterable, Identifiable {
    case bug = "Bug"
    case uxAnnoyance = "UX Annoyance"
    case performanceIssue = "Performance Issue"
    case missingFeature = "Missing Feature"
    case confusingBehavior = "Confusing Behavior"
    
    public var id: String { rawValue }
}

public struct DogfoodReport: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let category: DogfoodCategory
    public let title: String
    public let details: String
    
    // Auto-captured System Metadata
    public let appVersion: String
    public let buildNumber: String
    public let osVersion: String
    public let activeProfileName: String
    public let openTabCount: Int
    public let memoryUsageMB: Double
    public let uptimeSeconds: TimeInterval
    public let crashCount: Int
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: DogfoodCategory,
        title: String,
        details: String,
        appVersion: String = BuildConfiguration.appVersion,
        buildNumber: String = BuildConfiguration.buildNumber,
        osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
        activeProfileName: String,
        openTabCount: Int,
        memoryUsageMB: Double,
        uptimeSeconds: TimeInterval,
        crashCount: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.title = title
        self.details = details
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.osVersion = osVersion
        self.activeProfileName = activeProfileName
        self.openTabCount = openTabCount
        self.memoryUsageMB = memoryUsageMB
        self.uptimeSeconds = uptimeSeconds
        self.crashCount = crashCount
    }
}

/// `@MainActor` founder and QA dogfooding feedback manager.
///
/// **PRIVACY GUARANTEE**:
/// - Strictly local storage in `~/Library/Application Support/HoloBrowser/dogfood_reports.json`.
/// - NEVER uploads data to cloud or external analytics endpoints.
@MainActor
public final class DogfoodReportManager: ObservableObject {
    public static let shared = DogfoodReportManager()
    
    @Published public private(set) var reports: [DogfoodReport] = []
    
    private let startTime = Date()
    private let fileURL: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("dogfood_reports.json")
        loadReports()
    }
    
    /// Submits a founder dogfooding feedback report with auto-captured system metadata context.
    public func submitReport(
        category: DogfoodCategory,
        title: String,
        details: String,
        activeProfileName: String,
        openTabCount: Int
    ) {
        let uptime = Date().timeIntervalSince(startTime)
        let memoryMB = currentMemoryUsageMB()
        let crashes = RecoveryManager.shared.consecutiveCrashCount
        
        let report = DogfoodReport(
            category: category,
            title: title,
            details: details,
            activeProfileName: activeProfileName,
            openTabCount: openTabCount,
            memoryUsageMB: memoryMB,
            uptimeSeconds: uptime,
            crashCount: crashes
        )
        
        reports.insert(report, at: 0)
        saveReportsAsync()
        LocalUsageMetrics.shared.recordFeatureUsage(name: "DogfoodReportSubmitted")
    }
    
    /// Purges all local dogfooding reports.
    public func clearReports() {
        reports.removeAll()
        let url = fileURL
        Task {
            await DiskStorageActor.shared.delete(at: url)
        }
    }
    
    private func currentMemoryUsageMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024.0 * 1024.0)
        }
        return 0.0
    }
    
    private func loadReports() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let list = try? JSONDecoder().decode([DogfoodReport].self, from: data) else {
            return
        }
        self.reports = list
    }
    
    private func saveReportsAsync() {
        let listCopy = self.reports
        let url = self.fileURL
        Task {
            try? await DiskStorageActor.shared.write(listCopy, to: url)
        }
    }
}
