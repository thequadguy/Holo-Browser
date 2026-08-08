import Foundation
import SwiftUI

public enum HoloStartupBehavior: String, CaseIterable, Identifiable {
    case commandCenter = "Command Center (holo://start)"
    case previousSession = "Continue where I left off"
    case custom = "Custom Homepage"
    
    public var id: String { rawValue }
}

public final class HoloStartupSettings: ObservableObject {
    public static let shared = HoloStartupSettings()
    
    @AppStorage("holo_startup_behavior")
    public var startupBehavior: HoloStartupBehavior = .commandCenter
    
    @AppStorage("holo_custom_homepage")
    public var customHomepageURL: String = "https://search.brave.com"
    
    private init() {}
}
