import SwiftUI
import Combine

/// First-run setup step enumeration.
public enum HoloSetupStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case profileSelection = 1
    case privacyPreferences = 2
    case complete = 3
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .welcome: return "Welcome to Holo Browser"
        case .profileSelection: return "Choose Default Profile"
        case .privacyPreferences: return "Privacy & AI Permissions"
        case .complete: return "Setup Complete"
        }
    }
}

/// State coordinator for Holo Browser V1.7 first-run onboarding setup.
@MainActor
public final class HoloSetupCoordinator: ObservableObject {
    public static let shared = HoloSetupCoordinator()
    
    @AppStorage("hasCompletedFirstRunSetup") public var hasCompletedSetup: Bool = false
    @AppStorage("defaultProfileSpace") public var selectedProfileSpace: String = "Personal"
    @AppStorage("enableTrackerBlocking") public var enableTrackerBlocking: Bool = true
    @AppStorage("enableAIMemoryPermissions") public var enableAIMemoryPermissions: Bool = true
    @AppStorage("enableAnonymousDiagnostics") public var enableAnonymousDiagnostics: Bool = false
    
    @Published public var currentStep: HoloSetupStep = .welcome
    
    private init() {}
    
    public func advanceStep() {
        if let nextStep = HoloSetupStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(HoloTheme.Animations.springSmooth) {
                currentStep = nextStep
            }
        } else {
            completeSetup()
        }
    }
    
    public func previousStep() {
        if let prevStep = HoloSetupStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(HoloTheme.Animations.springSmooth) {
                currentStep = prevStep
            }
        }
    }
    
    public func completeSetup() {
        withAnimation(HoloTheme.Animations.springSmooth) {
            hasCompletedSetup = true
            currentStep = .complete
        }
    }
    
    public func resetSetup() {
        hasCompletedSetup = false
        currentStep = .welcome
    }
}
