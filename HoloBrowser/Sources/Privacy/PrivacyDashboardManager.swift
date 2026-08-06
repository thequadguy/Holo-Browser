import Foundation
import Combine

/// On-Device Privacy & Security Dashboard Manager.
/// Tracks blocked trackers, AI sanitization events, and private mode protections without telemetry.
@MainActor
public final class PrivacyDashboardManager: ObservableObject {
    public static let shared = PrivacyDashboardManager()
    
    @Published public private(set) var totalBlockedTrackers: Int
    @Published public private(set) var totalAISanitizations: Int
    @Published public private(set) var totalPrivateShieldBlocks: Int
    
    private init() {
        let defaults = UserDefaults.standard
        self.totalBlockedTrackers = defaults.integer(forKey: "Privacy_BlockedTrackers")
        self.totalAISanitizations = defaults.integer(forKey: "Privacy_AISanitizations")
        self.totalPrivateShieldBlocks = defaults.integer(forKey: "Privacy_PrivateShieldBlocks")
    }
    
    public func recordBlockedTracker() {
        totalBlockedTrackers += 1
        UserDefaults.standard.set(totalBlockedTrackers, forKey: "Privacy_BlockedTrackers")
    }
    
    public func recordAISanitization() {
        totalAISanitizations += 1
        UserDefaults.standard.set(totalAISanitizations, forKey: "Privacy_AISanitizations")
    }
    
    public func recordPrivateShieldBlock() {
        totalPrivateShieldBlocks += 1
        UserDefaults.standard.set(totalPrivateShieldBlocks, forKey: "Privacy_PrivateShieldBlocks")
    }
}
