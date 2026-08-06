import SwiftUI

/// In-App Public Beta Status & Community View.
public struct BetaStatusView: View {
    @ObservedObject private var analyticsManager = PrivacyAnalyticsManager.shared
    @State private var feedbackSummary = ""
    @State private var feedbackDetails = ""
    @State private var feedbackType: FeedbackManager.FeedbackType = .bugReport
    @State private var includeDiagnostics = true
    @State private var showConfirmation = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Badge
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Holo Browser 1.0 Public Beta")
                            .font(.headline)
                        Text("Build \(BuildConfiguration.appVersion) (Build \(BuildConfiguration.buildNumber)) | macOS Universal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("BETA ACTIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(6)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Analytics Opt-in Toggle
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable Anonymous Privacy-First Analytics", isOn: $analyticsManager.isOptedIn)
                        .toggleStyle(.switch)
                    
                    Text("Holo Browser NEVER collects browsing history, URLs, search terms, passwords, or AI conversations. Analytics only include app crash counts and feature interactions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Submit Beta Feedback Form
                VStack(alignment: .leading, spacing: 14) {
                    Text("Submit Beta Feedback")
                        .font(.title3)
                        .bold()
                    
                    Picker("Type", selection: $feedbackType) {
                        ForEach(FeedbackManager.FeedbackType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("Short Summary", text: $feedbackSummary)
                        .textFieldStyle(.roundedBorder)
                    
                    TextEditor(text: $feedbackDetails)
                        .frame(height: 100)
                        .border(Color.secondary.opacity(0.3), width: 1)
                        .cornerRadius(6)
                    
                    Toggle("Attach Privacy-Sanitized Diagnostic Summary", isOn: $includeDiagnostics)
                        .font(.caption)
                    
                    HStack {
                        Button("Export Diagnostics Text") {
                            let report = DiagnosticsExporter.generateSanitizedReport()
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(report, forType: .string)
                        }
                        
                        Spacer()
                        
                        Button("Submit Feedback") {
                            FeedbackManager.shared.submitFeedback(
                                type: feedbackType,
                                summary: feedbackSummary,
                                details: feedbackDetails,
                                includeDiagnostics: includeDiagnostics
                            )
                            feedbackSummary = ""
                            feedbackDetails = ""
                            showConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(feedbackSummary.isEmpty)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding()
        }
        .alert("Feedback Submitted", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for helping improve Holo Browser!")
        }
    }
}
