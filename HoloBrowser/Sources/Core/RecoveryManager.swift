import Foundation
import Combine

/// Production crash recovery and safe mode engine for Holo Browser.
/// Prevents crash loops, corrupted preferences, and failed session restores.
@MainActor
public final class RecoveryManager: ObservableObject {
    public static let shared = RecoveryManager()
    
    @Published public private(set) var isSafeModeActive: Bool = false
    @Published public private(set) var consecutiveCrashCount: Int = 0
    
    private let crashCountKey = "Holo_ConsecutiveCrashCount"
    private let maxCrashThreshold = 3
    
    private init() {
        let count = UserDefaults.standard.integer(forKey: crashCountKey)
        self.consecutiveCrashCount = count
        if count >= maxCrashThreshold {
            self.isSafeModeActive = true
            resetCorruptedSessionData()
        }
    }
    
    /// Call on app startup to register launch. Increments crash counter.
    public func registerAppLaunch() {
        consecutiveCrashCount += 1
        UserDefaults.standard.set(consecutiveCrashCount, forKey: crashCountKey)
    }
    
    /// Call after 10 seconds of stable execution to clear crash counter.
    public func registerStableExecution() {
        consecutiveCrashCount = 0
        UserDefaults.standard.set(0, forKey: crashCountKey)
    }
    
    /// Quarantines and resets session snapshots if corrupted profile or session detected.
    public func resetCorruptedSessionData() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoDir = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        let archiveDir = holoDir.appendingPathComponent("CorruptedSessions", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)
        
        let filesToQuarantine = ["session.json", "history.json", "bookmarks.json"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let dateStr = formatter.string(from: Date())
        
        for file in filesToQuarantine {
            let sourceURL = holoDir.appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: sourceURL.path) {
                let nameWithoutExt = (file as NSString).deletingPathExtension
                let ext = (file as NSString).pathExtension
                let destName = "\(nameWithoutExt).corrupt.\(dateStr).\(ext)"
                let destURL = archiveDir.appendingPathComponent(destName)
                try? FileManager.default.moveItem(at: sourceURL, to: destURL)
            }
        }
    }
}
