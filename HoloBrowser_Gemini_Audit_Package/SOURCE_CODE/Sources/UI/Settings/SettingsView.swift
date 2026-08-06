import SwiftUI

public enum SettingsTab: String, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case privacy = "Privacy"
    case profiles = "Profiles"
    case passwords = "Passwords"
    case ai = "AI Assistant"
    case extensions = "Extensions"
    case advanced = "Advanced"
}

/// Unified native macOS settings and preferences window.
public struct SettingsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var privacyManager: AIPrivacyManager
    
    @State private var selectedTab: SettingsTab = .general
    
    public init(viewModel: BrowserViewModel, privacyManager: AIPrivacyManager) {
        self.viewModel = viewModel
        self.privacyManager = privacyManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Settings Header & Tab Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                    Text("Holo Browser Preferences")
                        .font(.headline)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            HStack(spacing: 0) {
                // Tab Selection List
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            HStack {
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: selectedTab == tab ? .bold : .regular))
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .frame(width: 140)
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                
                Divider()
                
                // Tab Content View
                VStack(alignment: .leading, spacing: 12) {
                    switch selectedTab {
                    case .general:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("General Settings").font(.subheadline).bold()
                            Text("Homepage URL: https://apple.com").font(.caption).foregroundColor(.secondary)
                            Text("Default Search Engine: DuckDuckGo").font(.caption).foregroundColor(.secondary)
                        }
                    case .appearance:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Appearance & Liquid Glass").font(.subheadline).bold()
                            Text("Theme: Native macOS System Vibrancy").font(.caption).foregroundColor(.secondary)
                            Text("Frame Rate: 120 FPS ProMotion Enabled").font(.caption).foregroundColor(.secondary)
                        }
                    case .privacy:
                        PrivacyDashboardView()
                    case .profiles:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Profile Manager").font(.subheadline).bold()
                            Text("Active Profile: \(viewModel.profileManager.activeProfile.name)").font(.caption).foregroundColor(.secondary)
                        }
                    case .passwords:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Apple Keychain Passwords").font(.subheadline).bold()
                            Text("Credentials stored securely in Security.framework").font(.caption).foregroundColor(.secondary)
                        }
                    case .ai:
                        AISettingsView(aiManager: AIManager(), privacyManager: privacyManager)
                    case .extensions:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WebExtensions Platform").font(.subheadline).bold()
                            Text("Installed Extensions: \(viewModel.extensionManager.extensions.count)").font(.caption).foregroundColor(.secondary)
                        }
                    case .advanced:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Advanced & Developer").font(.subheadline).bold()
                            Button("Open Web Inspector (⌘OptionI)") {
                                viewModel.toggleWebInspector()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 600, height: 400)
    }
}
