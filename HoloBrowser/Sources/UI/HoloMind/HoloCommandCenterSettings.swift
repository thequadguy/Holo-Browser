import Foundation
import SwiftUI

public enum HoloStartupBehavior: String, CaseIterable, Identifiable {
    case commandCenter = "Command Center (holo://start)"
    case previousSession = "Continue where I left off"
    case custom = "Custom Homepage"
    
    public var id: String { rawValue }
}

public final class HoloCommandCenterSettings: ObservableObject {
    public static let shared = HoloCommandCenterSettings()
    
    @AppStorage("holo_startup_behavior")
    public var startupBehavior: HoloStartupBehavior = .commandCenter
    
    @AppStorage("holo_custom_homepage")
    public var customHomepageURL: String = "https://search.brave.com"
    
    @AppStorage("holo_show_active_missions")
    public var showActiveMissions: Bool = true
    
    @AppStorage("holo_show_insights")
    public var showInsights: Bool = true
    
    @AppStorage("holo_show_favorites")
    public var showFavorites: Bool = true
    
    @AppStorage("holo_show_recent_activity")
    public var showRecentActivity: Bool = true
    
    @AppStorage("holo_show_privacy_dashboard")
    public var showPrivacyDashboard: Bool = true
    
    private init() {}
}
