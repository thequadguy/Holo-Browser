import SwiftUI
import AppKit

/// Premium native macOS onboarding spotlight view for Holo Browser V1.2.
/// Highlights key platform capabilities with skippable liquid glass cards.
public struct HoloOnboardingView: View {
    let onComplete: () -> Void
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var activeCardIndex: Int = 0
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(HoloTheme.Palette.heroGradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to Holo Browser")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(HoloTheme.Text.primary)
                    Text("Native Swift • Liquid Glass • HoloMind AI Layer")
                        .font(.system(size: 11))
                        .foregroundColor(HoloTheme.Text.secondary)
                }
                
                Spacer()
                
                Button("Skip Spotlight") {
                    finishOnboarding()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(HoloTheme.Text.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.gray.opacity(0.15)))
            }
            .padding(18)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
            
            Divider()
            
            // Interactive Spotlight Step Canvas
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("SPOTLIGHT \(activeCardIndex + 1) OF \(spotlightCards.count)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HoloTheme.Palette.holoCyan.opacity(0.15))
                        .foregroundColor(HoloTheme.Palette.holoCyan)
                        .cornerRadius(6)
                    Spacer()
                }
                
                let current = spotlightCards[activeCardIndex]
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        Image(systemName: current.icon)
                            .font(.system(size: 28))
                            .foregroundColor(current.color)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(current.color.opacity(0.12)))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(current.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(HoloTheme.Text.primary)
                            Text(current.subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(HoloTheme.Text.secondary)
                        }
                    }
                    
                    Text(current.description)
                        .font(.system(size: 12))
                        .foregroundColor(HoloTheme.Text.secondary)
                        .lineSpacing(4)
                    
                    if let tip = current.shortcutTip {
                        HStack(spacing: 8) {
                            Text("PRO TIP")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(4)
                            
                            Text(tip)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(HoloTheme.Text.primary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .holoFrostGlass(cornerRadius: 10)
                    }
                }
                .padding(20)
                .holoGlassCard(cornerRadius: 16)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
            
            Divider()
            
            // Navigation Controls
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<spotlightCards.count, id: \.self) { idx in
                        Circle()
                            .fill(idx == activeCardIndex ? HoloTheme.Palette.holoCyan : Color.gray.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }
                
                Spacer()
                
                if activeCardIndex > 0 {
                    Button("Previous") {
                        withAnimation(HoloDesign.Animations.springFast) {
                            activeCardIndex -= 1
                        }
                    }
                    .buttonStyle(HoloSecondaryButtonStyle())
                }
                
                if activeCardIndex < spotlightCards.count - 1 {
                    Button("Next Spotlight") {
                        withAnimation(HoloDesign.Animations.springFast) {
                            activeCardIndex += 1
                        }
                    }
                    .buttonStyle(HoloPrimaryButtonStyle())
                } else {
                    Button("Get Started", action: finishOnboarding)
                        .buttonStyle(HoloPrimaryButtonStyle())
                }
            }
            .padding(16)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
        }
        .frame(width: 540, height: 440)
    }
    
    private func finishOnboarding() {
        hasCompletedOnboarding = true
        onComplete()
    }
    
    private struct SpotlightCard {
        let title: String
        let subtitle: String
        let description: String
        let icon: String
        let color: Color
        let shortcutTip: String?
    }
    
    private var spotlightCards: [SpotlightCard] {
        [
            SpotlightCard(
                title: "OmniBox & Direct AI Search",
                subtitle: "Press ⌘L to focus the address bar anytime",
                description: "Type any web URL directly, prefix queries with 'h ' to prompt HoloMind AI directly, or prefix with 'm ' to initialize autonomous research missions.",
                icon: "magnifyingglass.circle.fill",
                color: HoloTheme.Palette.holoCyan,
                shortcutTip: "Press ⌘L then type 'h summarize this article' to analyze current page."
            ),
            SpotlightCard(
                title: "Command Palette",
                subtitle: "Press ⌘K for instant browser shortcuts",
                description: "Quickly open closed tabs, search bookmarks and browsing history, switch profile spaces, or trigger AI workflows without touching the mouse.",
                icon: "command.square.fill",
                color: .purple,
                shortcutTip: "Press ⌘K to open instant launcher."
            ),
            SpotlightCard(
                title: "HoloMind Intelligence Layer",
                subtitle: "On-device page context & proactive insights",
                description: "HoloMind scans active tab content locally, extracts key research concepts, and provides transparent summary cards without leaking private telemetry.",
                icon: "brain.head.profile",
                color: .blue,
                shortcutTip: "Press ⌘⇧A to toggle the native HoloMind AI Sidebar."
            ),
            SpotlightCard(
                title: "Isolated Profile Spaces",
                subtitle: "Keep Work, Personal & Private sessions separated",
                description: "Each profile space maintains its own isolated cookies, local storage, and history. Easily isolate work logins from personal browsing.",
                icon: "person.2.circle.fill",
                color: .green,
                shortcutTip: "Use the profile switcher in the top-right toolbar to toggle spaces."
            ),
            SpotlightCard(
                title: "Strict On-Device Privacy Shields",
                subtitle: "Keychain security & regex token sanitizer",
                description: "Your passwords stay locked in macOS Keychain. Bearer tokens, API keys, and sensitive fields are scrubbed before sending queries to AI engines.",
                icon: "shield.checkered",
                color: .orange,
                shortcutTip: "Toggle tracking shield status anytime on the Holo Start Page."
            )
        ]
    }
}
