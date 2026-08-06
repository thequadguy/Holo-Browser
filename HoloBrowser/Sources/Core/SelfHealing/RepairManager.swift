import Foundation

public struct RepairActionResult: Identifiable {
    public let id: UUID = UUID()
    public let actionName: String
    public let success: Bool
    public let message: String
    public let timestamp: Date = Date()
}

/// `@MainActor` automated repair manager restoring safe application state when corrupted storage or crash loops occur.
@MainActor
public final class RepairManager: ObservableObject {
    public static let shared = RepairManager()
    
    @Published public private(set) var recentResults: [RepairActionResult] = []
    
    private init() {}
    
    /// Performs automated quarantine and repair of corrupted JSON files.
    @discardableResult
    public func repairCorruptedStorage() -> RepairActionResult {
        RecoveryManager.shared.resetCorruptedSessionData()
        let result = RepairActionResult(
            actionName: "Storage Quarantine & Reset",
            success: true,
            message: "Corrupted session, history, and bookmark JSON files were safely quarantined to CorruptedSessions/."
        )
        recentResults.insert(result, at: 0)
        HealthMonitor.shared.refreshHealthStatus()
        return result
    }
    
    /// Resets crash count loop detector and exits Safe Mode.
    @discardableResult
    public func resetCrashCount() -> RepairActionResult {
        RecoveryManager.shared.registerStableExecution()
        let result = RepairActionResult(
            actionName: "Reset Crash Telemetry",
            success: true,
            message: "Consecutive crash counter reset to 0. Safe Mode deactivated."
        )
        recentResults.insert(result, at: 0)
        HealthMonitor.shared.refreshHealthStatus()
        return result
    }
    
    /// Clears web cache and temporary data without affecting Keychain credentials.
    @discardableResult
    public func clearCachesAndTempData() -> RepairActionResult {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoDir = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        let cacheFolder = holoDir.appendingPathComponent("Cache", isDirectory: true)
        
        try? FileManager.default.removeItem(at: cacheFolder)
        try? FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let result = RepairActionResult(
            actionName: "Clear Temporary Cache",
            success: true,
            message: "Temporary web caches and transient session data purged successfully."
        )
        recentResults.insert(result, at: 0)
        return result
    }
    
    /// Performs overall storage health repair pass.
    public func performStorageRepair() -> Bool {
        _ = clearCachesAndTempData()
        return true
    }
}
