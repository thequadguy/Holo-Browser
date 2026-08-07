import SwiftUI

/// Onboarding Welcome View for Holo Browser V1.7 Closed Beta Testers.
/// Explains native macOS architecture, privacy-first guarantees, HoloMind AI assistant capabilities, and keyboard shortcuts.
public struct HoloBetaWelcomeView: View {
    @ObservedObject private var setupCoordinator = HoloSetupCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header Logo & Title
            VStack(spacing: 8) {
                HoloAssistantPresenceView(state: .idle)
                    .scaleEffect(1.2)
                
                Text("Holo Browser")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(HoloTheme.Text.primary)
                
                Text("Version 1.7 Closed Beta • Native macOS Architecture")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(HoloTheme.Text.secondary)
            }
            .padding(.top, 16)
            
            // Dynamic Setup Step Content
            switch setupCoordinator.currentStep {
            case .welcome:
                welcomeStepView
            case .profileSelection:
                profileSelectionStepView
            case .privacyPreferences:
                privacyPreferencesStepView
            case .complete:
                completeStepView
            }
            
            Spacer()
            
            // Navigation Controls
            HStack {
                if setupCoordinator.currentStep != .welcome && setupCoordinator.currentStep != .complete {
                    Button("Back") {
                        setupCoordinator.previousStep()
                    }
                    .buttonStyle(HoloSecondaryButtonStyle())
                }
                
                Spacer()
                
                if setupCoordinator.currentStep == .complete {
                    Button("Start Browsing") {
                        dismiss()
                    }
                    .buttonStyle(HoloPrimaryButtonStyle())
                } else {
                    Button(setupCoordinator.currentStep == .welcome ? "Get Started" : "Continue") {
                        setupCoordinator.advanceStep()
                    }
                    .buttonStyle(HoloPrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 520, height: 480)
        .holoFrostGlass(cornerRadius: 18)
    }
    
    // MARK: - Step 1: Welcome & Keyboard Shortcuts
    private var welcomeStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Key Spotlight Commands")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(HoloTheme.Text.primary)
            
            VStack(spacing: 8) {
                shortcutRow(key: "Cmd+L", label: "Focus OmniBox Address Bar")
                shortcutRow(key: "Cmd+K", label: "Open Command Palette & Quick Search")
                shortcutRow(key: "Cmd+Shift+A", label: "Toggle HoloMind AI Intelligence Sidebar")
                shortcutRow(key: "h <query>", label: "AI Query Intent Routing")
                shortcutRow(key: "mission <task>", label: "Trigger Autonomous Workflow Engine")
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Step 2: Profile Selection
    private var profileSelectionStepView: some View {
        VStack(spacing: 16) {
            Text("Select your primary space profile:")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(HoloTheme.Text.secondary)
            
            HStack(spacing: 14) {
                profileCard(title: "Personal", icon: "person.crop.circle.fill", color: HoloTheme.Palette.appleBlue)
                profileCard(title: "Work", icon: "briefcase.fill", color: HoloTheme.Palette.holoViolet)
                profileCard(title: "Private", icon: "shield.fill", color: .orange)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Step 3: Privacy Preferences
    private var privacyPreferencesStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $setupCoordinator.enableTrackerBlocking) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Strict Tracker Blocking")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Block known third-party trackers & privacy fingerprinting.")
                        .font(.system(size: 11))
                        .foregroundColor(HoloTheme.Text.secondary)
                }
            }
            
            Toggle(isOn: $setupCoordinator.enableAIMemoryPermissions) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HoloMind On-Device Context Memory")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Allow HoloMind to remember context strictly stored on your local disk.")
                        .font(.system(size: 11))
                        .foregroundColor(HoloTheme.Text.secondary)
                }
            }
            
            Toggle(isOn: $setupCoordinator.enableAnonymousDiagnostics) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share Anonymous Crash & Performance Data")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Help improve Holo Browser without transmitting URLs or personal data.")
                        .font(.system(size: 11))
                        .foregroundColor(HoloTheme.Text.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Step 4: Setup Complete
    private var completeStepView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(HoloTheme.Palette.holoEmerald)
            
            Text("You're All Set!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HoloTheme.Text.primary)
            
            Text("Holo Browser is calibrated and ready. Enjoy native macOS performance and privacy-first intelligence.")
                .font(.system(size: 12))
                .foregroundColor(HoloTheme.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, 24)
    }
    
    private func shortcutRow(key: String, label: String) -> some View {
        HStack {
            HoloShortcutBadge(key)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(HoloTheme.Text.primary)
            Spacer()
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.20)))
    }
    
    private func profileCard(title: String, icon: String, color: Color) -> some View {
        let isSelected = setupCoordinator.selectedProfileSpace == title
        return Button(action: {
            setupCoordinator.selectedProfileSpace = title
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(HoloTheme.Text.primary)
            }
            .frame(width: 120, height: 90)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? color.opacity(0.18) : Color.white.opacity(0.15)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? color : Color.white.opacity(0.30), lineWidth: isSelected ? 1.5 : 0.8))
        }
        .buttonStyle(.plain)
    }
}
