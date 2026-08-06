import Foundation
import Combine

public struct LocalInsightsData: Codable {
    public var launchCount: Int = 1
    public var averageLaunchTimeMs: Double = 440.0
    public var averagePageLoadTimeMs: Double = 320.0
    public var lastCrashTimestamp: Date? = nil
    public var restoredSessionsCount: Int = 0
    public var totalDownloadsCount: Int = 0
    public var localAIRequestsCount: Int = 0
    public var cloudAIRequestsCount: Int = 0
    public var trackersBlockedCount: Int = 0
}

/// `@MainActor` local insights data manager tracking performance, resource, and privacy metrics locally.
///
/// **STRICT PRIVACY GUARANTEE**:
/// - NEVER collects URLs, search terms, page content, passwords, or personal identity.
/// - Data remains strictly local on the user's Mac.
@MainActor
public final class HoloInsightsManager: ObservableObject {
    public static let shared = HoloInsightsManager()
    
    @Published public private(set) var data = LocalInsightsData()
    @Published public private(set) var currentMemoryMB: Double = 0.0
    @Published public private(set) var localStorageBytes: Int64 = 0
    
    private let fileURL: URL
    private let launchStartTime = Date()
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("local_insights.json")
        loadData()
        recordLaunch()
        refreshDynamicMetrics()
    }
    
    public var crashFreeDays: Int {
        let lastCrash = data.lastCrashTimestamp ?? Date.distantPast
        let days = Calendar.current.dateComponents([.day], from: lastCrash, to: Date()).day ?? 0
        return max(days, 0)
    }
    
    public func recordPageLoad(durationMs: Double) {
        let currentAvg = data.averagePageLoadTimeMs
        data.averagePageLoadTimeMs = (currentAvg * 0.8) + (durationMs * 0.2)
        saveDataAsync()
    }
    
    public func recordDownload() {
        data.totalDownloadsCount += 1
        saveDataAsync()
    }
    
    public func recordAIRequest(isLocal: Bool) {
        if isLocal {
            data.localAIRequestsCount += 1
        } else {
            data.cloudAIRequestsCount += 1
        }
        saveDataAsync()
    }
    
    public func recordRestoredSession() {
        data.restoredSessionsCount += 1
        saveDataAsync()
    }
    
    public func refreshDynamicMetrics() {
        // Memory Usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            self.currentMemoryMB = Double(info.resident_size)/(1024.0*1024.0)
        }
        
        // Storage Usage
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        self.localStorageBytes = folderSize(url: holoFolder)
    }
    
    private func recordLaunch() {
        data.launchCount += 1
        let launchDuration = Date().timeIntervalSince(launchStartTime) * 1000.0
        data.averageLaunchTimeMs = (data.averageLaunchTimeMs * 0.9) + (launchDuration * 0.1)
        saveDataAsync()
    }
    
    private func folderSize(url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                total += Int64(size)
            }
        }
        return total
    }
    
    private func loadData() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let raw = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(LocalInsightsData.self, from: raw) else {
            return
        }
        self.data = decoded
    }
    
    private func saveDataAsync() {
        let copy = self.data
        let url = self.fileURL
        Task {
            try? await DiskStorageActor.shared.write(copy, to: url)
        }
    }
}
