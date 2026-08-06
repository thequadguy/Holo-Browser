import SwiftUI

/// First-launch onboarding modal view introducing Holo Browser features, profiles, and AI privacy shield.
public struct WelcomeView: View {
    let onGetStarted: () -> Void
    
    public init(onGetStarted: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 24))
                Text("Welcome to Holo Browser")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            Text("The next-generation native macOS browser built with liquid glass UI, isolated profiles, and human-in-the-loop AI assistants.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "shield.badge.checkmark")
                        .font(.title3)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy-First Architecture").font(.subheadline).bold()
                        Text("Passwords stay in Apple Keychain. Private tabs write zero data.").font(.caption).foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Human-Controlled AI Workflows").font(.subheadline).bold()
                        Text("AI suggestions require approval before taking browser actions.").font(.caption).foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "command")
                        .font(.title3)
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keyboard-First Command Palette (⌘K)").font(.subheadline).bold()
                        Text("Press ⌘K to search commands, tabs, notes, and research instantly.").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Get Started With Holo") {
                    onGetStarted()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 500)
    }
}
