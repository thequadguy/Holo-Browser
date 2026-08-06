import SwiftUI

/// Native macOS dashboard displaying privacy-safe local performance, usage, and system health metrics.
public struct HoloInsightsView: View {
    @ObservedObject private var insights = HoloInsightsManager.shared
    @ObservedObject private var healthMonitor = HealthMonitor.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Banner
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Holo Insights Dashboard")
                            .font(.headline)
                        Text("100% Privacy-Preserving Local Performance & Usage Telemetry")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Refresh Metrics") {
                        insights.refreshDynamicMetrics()
                        healthMonitor.refreshHealthStatus()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                Divider()
                
                // Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    InsightCard(title: "Launch Count", value: "\(insights.data.launchCount)", icon: "bolt.fill", color: .orange)
                    InsightCard(title: "Avg Launch Time", value: String(format: "%.0f ms", insights.data.averageLaunchTimeMs), icon: "timer", color: .blue)
                    InsightCard(title: "Avg Page Load", value: String(format: "%.0f ms", insights.data.averagePageLoadTimeMs), icon: "gauge.with.dots.needle.67percent", color: .purple)
                    
                    InsightCard(title: "Crash-Free Days", value: "\(insights.crashFreeDays) Days", icon: "shield.checkmark.fill", color: .green)
                    InsightCard(title: "Active RAM", value: String(format: "%.1f MB", insights.currentMemoryMB), icon: "memorychip", color: .indigo)
                    InsightCard(title: "Local Storage", value: formattedStorage(insights.localStorageBytes), icon: "internaldrive.fill", color: .teal)
                    
                    InsightCard(title: "Restored Sessions", value: "\(insights.data.restoredSessionsCount)", icon: "arrow.clockwise.square.fill", color: .pink)
                    InsightCard(title: "Completed Downloads", value: "\(insights.data.totalDownloadsCount)", icon: "arrow.down.circle.fill", color: .cyan)
                    InsightCard(title: "Local vs Cloud AI", value: "\(insights.data.localAIRequestsCount) / \(insights.data.cloudAIRequestsCount)", icon: "sparkles", color: .mint)
                }
                
                Divider()
                
                // Privacy Protection Status
                VStack(alignment: .leading, spacing: 10) {
                    Text("Privacy Protection Status").font(.subheadline).bold()
                    
                    HStack(spacing: 12) {
                        PrivacyStatusItem(title: "Zero Disk History", status: "Active in Private Mode", icon: "lock.slash.fill", color: .purple)
                        PrivacyStatusItem(title: "Regex AI Sanitizer", status: "Scrubbing Tokens & Keys", icon: "shield.fill", color: .green)
                        PrivacyStatusItem(title: "Apple Keychain", status: "Encrypted Credential Store", icon: "key.fill", color: .blue)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(12)
        }
        .onAppear {
            insights.refreshDynamicMetrics()
        }
    }
    
    private func formattedStorage(_ bytes: Int64) -> String {
        let mb = Double(bytes) / (1024.0 * 1024.0)
        return String(format: "%.2f MB", mb)
    }
}

private struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .default))
                .foregroundColor(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }
}

private struct PrivacyStatusItem: View {
    let title: String
    let status: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11, weight: .semibold))
                Text(status).font(.system(size: 9)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
