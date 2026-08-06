import SwiftUI
import AppKit

/// Premium multi-step onboarding wizard for Holo Browser Commercial Beta.
public struct HoloWelcomeView: View {
    let onComplete: () -> Void
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("preferredAIProvider") private var preferredAIProvider: String = "OpenAI"
    @AppStorage("enableLocalMetrics") private var enableLocalMetrics: Bool = true
    
    @AppStorage("holoMemoryEnabled") private var holoMemoryEnabled: Bool = true
    @AppStorage("holoAskBeforeRemembering") private var holoAskBeforeRemembering: Bool = false
    
    @State private var currentStep: Int = 0
    @State private var selectedBrowserSource: String = "Chrome"
    @State private var importedBookmarkCount: Int = 0
    @State private var importStatus: String? = nil
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 14) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(HoloTheme.Palette.heroGradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Holo Browser")
                        .font(.system(size: 22, weight: .bold))
                    Text("Liquid Glass Web Engine for macOS")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HoloBadge("Step \(currentStep + 1) of 5", color: .accentColor)
            }
            .padding(20)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
            
            Divider()
            
            // Step Body Canvas
            VStack(alignment: .leading, spacing: 18) {
                switch currentStep {
                case 0:
                    welcomeStepView
                case 1:
                    capabilitiesStepView
                case 2:
                    memoryTransparencyStepView
                case 3:
                    importStepView
                case 4:
                    finishStepView
                default:
                    EmptyView()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 340, maxHeight: 380, alignment: .topLeading)
            
            Divider()
            
            // Footer Controls
            HStack {
                if currentStep > 0 {
                    HoloGlassButton(title: "Back", icon: "chevron.left") {
                        withAnimation(HoloTheme.Animations.springSnappy) {
                            currentStep -= 1
                        }
                    }
                }
                
                Spacer()
                
                if currentStep < 4 {
                    HoloGlassButton(title: "Continue", icon: "chevron.right", isProminent: true) {
                        withAnimation(HoloTheme.Animations.springSnappy) {
                            currentStep += 1
                        }
                    }
                } else {
                    HoloGlassButton(title: "Start Browsing", icon: "sparkles", isProminent: true) {
                        hasCompletedOnboarding = true
                        LocalUsageMetrics.shared.recordFeatureUsage(name: "OnboardingCompleted")
                        onComplete()
                    }
                }
            }
            .padding(16)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
        }
        .frame(width: 620, height: 540)
        .holoGlassCard(cornerRadius: 14, padding: 0)
    }
    
    // MARK: - Step Views
    
    private var welcomeStepView: some View {
        VStack(alignment: .center, spacing: 18) {
            HStack {
                Spacer()
                HoloAssistantPresenceView(state: .analyzing)
                    .scaleEffect(2.0)
                Spacer()
            }
            .padding(.bottom, 10)
            
            Text("Hello. I'm H.")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("I'll help you browse, research, organize information, and accomplish goals.\nYour data stays under your control.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("What makes Holo different:")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.top, 10)
                
                HStack(spacing: 12) {
                    FeatureBadgeCard(title: "Native Speed", subtitle: "macOS WebKit Engine", icon: "bolt.fill")
                    FeatureBadgeCard(title: "Liquid Glass", subtitle: "Premium UI Design", icon: "sparkles")
                }
                HStack(spacing: 12) {
                    FeatureBadgeCard(title: "Privacy First", subtitle: "On-device architecture", icon: "shield.fill")
                    FeatureBadgeCard(title: "HoloMind", subtitle: "Intelligence Layer", icon: "brain.head.profile")
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var capabilitiesStepView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("What H can do for you")
                .font(.title2)
                .bold()
            
            Text("Holo Browser isn't just a browser with a chatbot. It's a proactive digital chief of staff that understands your context and helps you get things done.")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 14) {
                ExampleRow(quote: "I noticed you are comparing products. I can help.", icon: "cart.fill", color: .blue)
                ExampleRow(quote: "You started research and didn't finish. I can continue.", icon: "books.vertical.fill", color: .purple)
                ExampleRow(quote: "I found a better option based on your preferences.", icon: "star.fill", color: .orange)
            }
            .padding(.top, 8)
        }
    }
    
    private var memoryTransparencyStepView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your Memory, Your Rules")
                .font(.title2)
                .bold()
            
            Text("H remembers your workflow and preferences to provide personalized help. Everything is stored locally. You are always in control.")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                PrivacyRow(title: "What is remembered?", description: "Preferences, active research topics, and goals.", icon: "brain", color: .purple)
                PrivacyRow(title: "Why is it remembered?", description: "To save you time and avoid repeating instructions.", icon: "timer", color: .blue)
                PrivacyRow(title: "How to manage it?", description: "View, edit, or delete any memory instantly in Settings.", icon: "trash.fill", color: .red)
            }
            
            Divider().padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable H Memory Engine", isOn: $holoMemoryEnabled)
                    .font(.system(size: 13, weight: .medium))
                
                Toggle("Ask me before remembering new information", isOn: $holoAskBeforeRemembering)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(!holoMemoryEnabled)
                    .opacity(holoMemoryEnabled ? 1.0 : 0.5)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var importStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import Bookmarks & Favorites")
                .font(.title2)
                .bold()
            
            Text("Import your bookmarks directly from an exported HTML file (Chrome, Safari, Firefox):")
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Picker("Browser", selection: $selectedBrowserSource) {
                    Text("Google Chrome").tag("Chrome")
                    Text("Apple Safari").tag("Safari")
                    Text("Mozilla Firefox").tag("Firefox")
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                
                HoloGlassButton(title: "Select HTML File", icon: "square.and.arrow.down") {
                    selectAndImportBookmarks()
                }
            }
            .padding(.top, 4)
            
            if let status = importStatus {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(status)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.top, 6)
            }
        }
    }
    
    private var finishStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("You're All Set!")
                .font(.title2)
                .bold()
            
            Text("Holo Browser is ready to act as your primary Mac daily driver.")
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                HoloGlassButton(title: "Set Holo as Default Browser", icon: "macwindow", isProminent: true) {
                    MacIntegrationManager.openDefaultBrowserSettings()
                    LocalUsageMetrics.shared.recordFeatureUsage(name: "SetDefaultBrowserOnboarding")
                }
            }
            .padding(.top, 8)
            
            Toggle("Help improve Holo Browser with anonymous local performance metrics", isOn: $enableLocalMetrics)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Actions
    
    private func selectAndImportBookmarks() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.html]
        panel.title = "Select Exported Bookmarks HTML File"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let imported = BrowserImportManager.importHTMLBookmarks(from: url)
                self.importedBookmarkCount = imported.count
                self.importStatus = "Successfully imported \(imported.count) bookmarks from \(url.lastPathComponent)!"
                LocalUsageMetrics.shared.recordFeatureUsage(name: "BookmarksImportedOnboarding")
            }
        }
    }
}

// MARK: - Supporting Onboarding Cards & Rows

private struct FeatureBadgeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .bold))
                Text(subtitle).font(.system(size: 10)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(VisualEffectViewWrapper(material: .contentBackground, blendingMode: .withinWindow))
        .cornerRadius(10)
    }
}

private struct PrivacyRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(description).font(.system(size: 11)).foregroundColor(.secondary)
            }
        }
    }
}

private struct ExampleRow: View {
    let quote: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text("\"\(quote)\"")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .italic()
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VisualEffectViewWrapper(material: .contentBackground, blendingMode: .withinWindow))
        .cornerRadius(10)
    }
}
