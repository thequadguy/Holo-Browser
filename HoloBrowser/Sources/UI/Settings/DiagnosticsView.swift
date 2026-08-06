import SwiftUI

/// Settings UI view allowing users to inspect, export, or disable diagnostic crash logs.
public struct DiagnosticsView: View {
    @ObservedObject var crashReporter: CrashReporter
    
    public init(crashReporter: CrashReporter) {
        self.crashReporter = crashReporter
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.blue)
                    Text("Privacy-Preserving Diagnostics")
                        .font(.headline)
                }
                Spacer()
                Button("Clear Diagnostics") {
                    crashReporter.clearReports()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Divider()
            
            Toggle("Enable Anonymous Crash Telemetry", isOn: $crashReporter.isTelemetryEnabled)
                .font(.system(size: 12, weight: .semibold))
            
            Text("Diagnostic logs capture ONLY system version and stack traces. History, URLs, passwords, and AI conversations are NEVER collected.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            if crashReporter.reports.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text("No diagnostic events recorded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(crashReporter.reports) { report in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(report.appVersion)
                                        .font(.system(size: 10, weight: .bold))
                                    Spacer()
                                    Text(report.timestamp.formatted(date: .numeric, time: .shortened))
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                Text(report.stackTrace)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                        }
                    }
                }
                .frame(minHeight: 160, maxHeight: 260)
            }
        }
        .padding(12)
        .frame(width: 440)
    }
}
