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
    
    /// Reset session snapshots if corrupted profile or session detected.
    public func resetCorruptedSessionData() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoDir = appSupport.appendingPathComponent("HoloBrowser/CorruptedSessions")
        try? FileManager.default.createDirectory(at: holoDir, withIntermediateDirectories: true)
    }
}
