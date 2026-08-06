import Foundation
import Combine

/// Onboarding and Feature Usage Journey Tracker.
/// Operates strictly locally to record user feature adoption without network transmissions.
@MainActor
public final class UserJourneyTracker: ObservableObject {
    public static let shared = UserJourneyTracker()
    
    @Published public private(set) var firstLaunchCompleted: Bool
    @Published public private(set) var profileCreated: Bool
    @Published public private(set) var firstTabOpened: Bool
    @Published public private(set) var commandPaletteUsed: Bool
    @Published public private(set) var aiFeatureActivated: Bool
    @Published public private(set) var privateModeUsed: Bool
    
    private init() {
        let defaults = UserDefaults.standard
        self.firstLaunchCompleted = defaults.bool(forKey: "Journey_FirstLaunch")
        self.profileCreated = defaults.bool(forKey: "Journey_ProfileCreated")
        self.firstTabOpened = defaults.bool(forKey: "Journey_FirstTab")
        self.commandPaletteUsed = defaults.bool(forKey: "Journey_CommandPalette")
        self.aiFeatureActivated = defaults.bool(forKey: "Journey_AIActivated")
        self.privateModeUsed = defaults.bool(forKey: "Journey_PrivateMode")
    }
    
    public func markMilestone(_ milestone: Milestone) {
        let defaults = UserDefaults.standard
        switch milestone {
        case .firstLaunch:
            firstLaunchCompleted = true
            defaults.set(true, forKey: "Journey_FirstLaunch")
        case .profileCreated:
            profileCreated = true
            defaults.set(true, forKey: "Journey_ProfileCreated")
        case .firstTabOpened:
            firstTabOpened = true
            defaults.set(true, forKey: "Journey_FirstTab")
        case .commandPaletteUsed:
            commandPaletteUsed = true
            defaults.set(true, forKey: "Journey_CommandPalette")
        case .aiFeatureActivated:
            aiFeatureActivated = true
            defaults.set(true, forKey: "Journey_AIActivated")
        case .privateModeUsed:
            privateModeUsed = true
            defaults.set(true, forKey: "Journey_PrivateMode")
        }
        
        PrivacyAnalyticsManager.shared.logEvent("Milestone_\(milestone.rawValue)")
    }
    
    public enum Milestone: String {
        case firstLaunch = "FirstLaunch"
        case profileCreated = "ProfileCreated"
        case firstTabOpened = "FirstTabOpened"
        case commandPaletteUsed = "CommandPaletteUsed"
        case aiFeatureActivated = "AIFeatureActivated"
        case privateModeUsed = "PrivateModeUsed"
    }
}
