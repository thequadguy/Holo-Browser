import SwiftUI

/// In-app feedback sheet accessible from Help menu or Settings.
/// Allows beta testers to submit bug reports, feature requests, and usability feedback
/// with optional privacy-sanitized diagnostics attachment.
public struct FeedbackSheetView: View {
    @State private var feedbackType: FeedbackManager.FeedbackType = .bugReport
    @State private var summary: String = ""
    @State private var details: String = ""
    @State private var includeDiagnostics: Bool = true
    @State private var showConfirmation: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Send Feedback")
                        .font(.headline)
                    Text("Holo Browser \(BuildConfiguration.appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Feedback Type Picker
            Picker("Type", selection: $feedbackType) {
                ForEach(FeedbackManager.FeedbackType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // Summary Field
            TextField("Brief summary of your feedback", text: $summary)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
            
            // Details Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Details")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $details)
                    .font(.system(size: 12))
                    .frame(minHeight: 100, maxHeight: 160)
                    .border(Color.secondary.opacity(0.2), width: 1)
                    .cornerRadius(4)
            }
            
            // Diagnostics Toggle
            Toggle(isOn: $includeDiagnostics) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Attach diagnostics")
                        .font(.system(size: 12, weight: .medium))
                    Text("System info only — no URLs, passwords, or browsing data")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            Divider()
            
            // Actions
            HStack {
                Button("Export Diagnostics") {
                    let report = DiagnosticsExporter.generateSanitizedReport()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(report, forType: .string)
                }
                .buttonStyle(.bordered)
                .font(.system(size: 12))
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .font(.system(size: 12))
                
                Button("Submit") {
                    FeedbackManager.shared.submitFeedback(
                        type: feedbackType,
                        summary: summary,
                        details: details,
                        includeDiagnostics: includeDiagnostics
                    )
                    showConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .font(.system(size: 12, weight: .semibold))
                .disabled(summary.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480)
        .alert("Feedback Submitted", isPresented: $showConfirmation) {
            Button("Done") { dismiss() }
        } message: {
            Text("Thank you for helping improve Holo Browser!")
        }
    }
}
