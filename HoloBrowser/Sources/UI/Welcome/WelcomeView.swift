import SwiftUI

/// First-launch onboarding view with interactive multi-step setup:
/// Welcome -> Import Bookmarks -> Profile Selection -> Finish
public struct WelcomeView: View {
    let onGetStarted: () -> Void
    
    @State private var currentStep: Int = 0
    @State private var selectedProfileName: String = "Personal"
    @State private var importStatusMessage: String? = nil
    
    public init(onGetStarted: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
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
            
            if currentStep == 0 {
                // Step 0: Overview & Privacy Highlights
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
            } else if currentStep == 1 {
                // Step 1: Import Bookmarks & Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import Existing Data").font(.headline)
                    Text("Select a browser to import bookmarks, history, and preferences:").font(.caption).foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Button("Import HTML Bookmarks") {
                            importStatusMessage = "Bookmark importer ready."
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Import Chrome Data") {
                            importStatusMessage = "Chrome data import prepared."
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let msg = importStatusMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            } else if currentStep == 2 {
                // Step 2: Set Default Browser
                VStack(alignment: .leading, spacing: 12) {
                    Text("Set as Default Browser").font(.headline)
                    Text("Make Holo Browser your primary browser for opening links on macOS.").font(.caption).foregroundColor(.secondary)
                    
                    Button("Set Holo Browser as Default") {
                        MacIntegrationManager.openDefaultBrowserSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Divider()
            
            // Footer Navigation Controls
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        currentStep -= 1
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                
                if currentStep < 2 {
                    Button("Continue") {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started With Holo") {
                        onGetStarted()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(20)
        .frame(width: 520)
    }
}
