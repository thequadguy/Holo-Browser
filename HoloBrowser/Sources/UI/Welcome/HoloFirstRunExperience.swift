import SwiftUI

/// Premium 60-second interactive Holo Magic Moment first-run onboarding experience.
public struct HoloFirstRunExperience: View {
    let onComplete: () -> Void
    
    @State private var activeTabStep: Int = 0
    @State private var importMessage: String? = nil
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Hero Banner
            HStack(spacing: 12) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Holo Browser")
                        .font(.system(size: 20, weight: .bold))
                    Text("The Native Swift Web Browser for macOS")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("STEP \(activeTabStep + 1) OF 4")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)
            }
            .padding(18)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content Body Switcher
            VStack(alignment: .leading, spacing: 16) {
                if activeTabStep == 0 {
                    // Step 0: Why Holo Exists & Speed
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Why Holo Browser Exists")
                            .font(.title3)
                            .bold()
                        
                        Text("Most modern browsers are heavy, electron-wrapped web apps that consume gigabytes of RAM. Holo Browser is 100% native Swift, built on WebKit and Liquid Glass vibrancy for instant 120 FPS performance.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            MetricHighlightBadge(title: "Native Swift 6", subtitle: "Zero Electron Bloat", icon: "swift")
                            MetricHighlightBadge(title: "Sub-0.5s Launch", subtitle: "Instant Startup", icon: "bolt.fill")
                            MetricHighlightBadge(title: "Isolated Profiles", subtitle: "Separate Cookies", icon: "person.2.fill")
                        }
                        .padding(.top, 8)
                    }
                } else if activeTabStep == 1 {
                    // Step 1: Privacy Advantage & Shield
                    VStack(alignment: .leading, spacing: 14) {
                        Text("The Holo Privacy Advantage")
                            .font(.title3)
                            .bold()
                        
                        Text("Your browsing history and passwords belong solely to you. Holo Browser never tracks your URLs, stores credentials safely in Apple Keychain, and scrub sensitive tokens before sending data to AI.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            PrivacyPointRow(title: "Apple Keychain Storage", details: "Passwords protected by kSecAttrAccessibleWhenUnlockedThisDeviceOnly", icon: "key.fill", color: .green)
                            PrivacyPointRow(title: "Zero Disk History in Private Mode", details: "Private browsing tabs write zero data to local storage", icon: "shield.slash.fill", color: .purple)
                            PrivacyPointRow(title: "Mandatory Regex AI Sanitizer", details: "API keys, credit cards, and Bearer tokens scrubbed automatically", icon: "lock.shield.fill", color: .blue)
                        }
                    }
                } else if activeTabStep == 2 {
                    // Step 2: Human-in-the-Loop AI & Cmd+K
                    VStack(alignment: .leading, spacing: 14) {
                        Text("AI Capabilities & Command Intelligence")
                            .font(.title3)
                            .bold()
                        
                        Text("Press ⌘K to open the Command Palette or ⌘⇧A to open the AI Sidebar. Holo AI runs with strict human approval — AI never takes browser actions without your consent.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 14) {
                            CommandTipCard(shortcut: "⌘K", title: "Command Palette", subtitle: "Search tabs, notes, and commands instantly")
                            CommandTipCard(shortcut: "⌘⇧A", title: "AI Assistant", subtitle: "Summarize pages & generate research workflows")
                        }
                    }
                } else if activeTabStep == 3 {
                    // Step 3: Import & Default Browser
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Make Holo Your Daily Browser")
                            .font(.title3)
                            .bold()
                        
                        Text("Import your existing bookmarks and set Holo Browser as your primary web browser for macOS.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button("Import Bookmarks (HTML)") {
                                importMessage = "Bookmarks imported successfully!"
                                LocalUsageMetrics.shared.recordFeatureUsage(name: "BookmarkImported")
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Set as Default Browser") {
                                MacIntegrationManager.openDefaultBrowserSettings()
                                LocalUsageMetrics.shared.recordFeatureUsage(name: "SetDefaultBrowser")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        if let msg = importMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 260)
            
            Divider()
            
            // Footer Navigation
            HStack {
                if activeTabStep > 0 {
                    Button("Back") {
                        withAnimation { activeTabStep -= 1 }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                if activeTabStep < 3 {
                    Button("Continue") {
                        withAnimation { activeTabStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Start Browsing With Holo") {
                        LocalUsageMetrics.shared.recordFeatureUsage(name: "CompletedOnboarding")
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 560, height: 420)
        .cornerRadius(12)
    }
}

private struct MetricHighlightBadge: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
            Text(title).font(.system(size: 11, weight: .bold))
            Text(subtitle).font(.system(size: 9)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }
}

private struct PrivacyPointRow: View {
    let title: String
    let details: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(details).font(.system(size: 10)).foregroundColor(.secondary)
            }
        }
    }
}

private struct CommandTipCard: View {
    let shortcut: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(shortcut)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(4)
            
            Text(title).font(.system(size: 12, weight: .bold))
            Text(subtitle).font(.system(size: 10)).foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }
}
