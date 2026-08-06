import SwiftUI

/// On-Device Visual Privacy Dashboard View for Holo Browser.
/// Displays blocked trackers, AI regex context sanitizations, private browsing shield events, and cookie isolation status without telemetry.
public struct PrivacyDashboardView: View {
    @ObservedObject private var dashboardManager = PrivacyDashboardManager.shared
    @ObservedObject private var privacyManager = AIPrivacyManager()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title Banner
                HStack {
                    Image(systemName: "shield.border.checkered.mititer.shield.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Privacy & Security Dashboard")
                            .font(.title2)
                            .bold()
                        Text("All metrics operate strictly locally on your Mac without telemetry dispatches.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Privacy Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(
                        title: "Trackers Blocked",
                        value: "\(dashboardManager.totalBlockedTrackers)",
                        icon: "hand.raised.fill",
                        color: .green
                    )
                    MetricCard(
                        title: "AI Sanitizations",
                        value: "\(dashboardManager.totalAISanitizations)",
                        icon: "lock.shield.fill",
                        color: .blue
                    )
                    MetricCard(
                        title: "Private Shield Blocks",
                        value: "\(dashboardManager.totalPrivateShieldBlocks)",
                        icon: "eye.slash.fill",
                        color: .purple
                    )
                }
                
                // Privacy Controls Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("Active Privacy Guarantees")
                        .font(.headline)
                    
                    PrivacyFeatureRow(
                        title: "Keychain Security",
                        subtitle: "Passwords and API keys use kSecAttrAccessibleWhenUnlockedThisDeviceOnly",
                        status: "Active",
                        icon: "key.fill"
                    )
                    
                    PrivacyFeatureRow(
                        title: "AI Context Redaction",
                        subtitle: "Mandatory regex pipeline scrubs JWTs, passwords, API keys, & CCs",
                        status: "Active",
                        icon: "wand.and.stars"
                    )
                    
                    PrivacyFeatureRow(
                        title: "Profile Data Isolation",
                        subtitle: "Per-profile WKWebsiteDataStore containers isolate cookies & cache",
                        status: "Active",
                        icon: "person.2.fill"
                    )
                    
                    PrivacyFeatureRow(
                        title: "Private Browsing Cloud Shield",
                        subtitle: "External cloud AI requests are strictly blocked in private windows",
                        status: privacyManager.privateAIBehavior == .blockExternalAI ? "Enforced" : "Configured",
                        icon: "shield.slash.fill"
                    )
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

fileprivate struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

fileprivate struct PrivacyFeatureRow: View {
    let title: String
    let subtitle: String
    let status: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(status)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(6)
        }
    }
}
