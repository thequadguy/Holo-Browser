import SwiftUI

/// Settings UI view displaying real-time system health, HoloDoctor diagnostics, and recovery snapshot controls.
public struct SystemHealthView: View {
    @ObservedObject private var healthMonitor = HealthMonitor.shared
    @ObservedObject private var doctor = HoloDoctor.shared
    @ObservedObject private var snapshotManager = SnapshotManager.shared
    @ObservedObject private var repairManager = RepairManager.shared
    
    @State private var statusMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Banner
                HStack(spacing: 12) {
                    Image(systemName: healthMonitor.overallState == .healthy ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(healthMonitor.overallState == .healthy ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Health Status")
                            .font(.headline)
                        Text(healthMonitor.overallState.rawValue)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(healthMonitor.overallState == .healthy ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    Button("Run Diagnostics") {
                        doctor.runDiagnostics()
                        statusMessage = "HoloDoctor diagnostic pass completed."
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(doctor.isRunningDiagnostics)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                if let msg = statusMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 4)
                }
                
                Divider()
                
                // Subsystem Status List
                VStack(alignment: .leading, spacing: 10) {
                    Text("Subsystem Integrity").font(.subheadline).bold()
                    
                    ForEach(healthMonitor.subsystems) { sub in
                        HStack(spacing: 10) {
                            Image(systemName: sub.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(sub.isHealthy ? .green : .red)
                                .font(.system(size: 14))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.name).font(.system(size: 12, weight: .semibold))
                                Text(sub.statusDetails).font(.system(size: 10)).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
                    }
                }
                
                Divider()
                
                // HoloDoctor Latest Diagnostic Report
                if let report = doctor.lastReport {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HoloDoctor Report (\(report.passedCount)/\(report.checks.count) Checks Passed)")
                            .font(.subheadline).bold()
                        
                        ForEach(report.checks) { check in
                            HStack {
                                Text(check.name)
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text(check.isPassed ? "PASS" : "FAIL")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(check.isPassed ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                    .foregroundColor(check.isPassed ? .green : .red)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
                
                Divider()
                
                // Recovery Snapshots & Repair Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Self-Healing & Recovery Actions").font(.subheadline).bold()
                    
                    HStack(spacing: 10) {
                        Button("Create Recovery Snapshot") {
                            let snap = snapshotManager.createSnapshot(label: "Manual Health Snapshot")
                            statusMessage = "Created snapshot '\(snap.label)' (\(snap.historyCount) history items)."
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Quarantine & Reset Storage") {
                            let res = repairManager.repairCorruptedStorage()
                            statusMessage = res.message
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Exit Safe Mode") {
                            let res = repairManager.resetCrashCount()
                            statusMessage = res.message
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(12)
        }
    }
}
