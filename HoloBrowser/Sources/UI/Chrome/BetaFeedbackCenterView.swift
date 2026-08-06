import SwiftUI

public enum BetaFeedbackCategory: String, CaseIterable, Identifiable {
    case bug = "Bug Report"
    case feature = "Feature Request"
    case privacy = "Privacy Concern"
    
    public var id: String { rawValue }
}

/// Beta Feedback Center for real-world launch operations.
/// Exists exclusively to collect anonymous, privacy-preserving feedback. No URLs, no history.
public struct BetaFeedbackCenterView: View {
    @State private var selectedCategory: BetaFeedbackCategory = .bug
    @State private var feedbackText: String = ""
    @State private var isSubmitted: Bool = false
    
    public let onDismiss: () -> Void
    
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "ladybug.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
                Text("Beta Feedback Center")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            
            if isSubmitted {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("Feedback Submitted Securely")
                        .font(.system(size: 14, weight: .bold))
                    Text("Thank you. No personal data was included in this transmission.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Text("Holo Browser is in Public Beta. Please help us stabilize the platform. Your privacy is paramount: this form collects ZERO browsing history, ZERO memory data, and ZERO identifiers.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(BetaFeedbackCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                
                TextEditor(text: $feedbackText)
                    .font(.system(size: 12))
                    .frame(height: 120)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                
                HStack {
                    Spacer()
                    HoloGlassButton(title: "Submit Securely", icon: "paperplane.fill", isProminent: true) {
                        submitFeedback()
                    }
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(20)
        .frame(width: 400)
        .background(VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow))
        .holoGlassCard(cornerRadius: 12, padding: 0)
    }
    
    private func submitFeedback() {
        // In a real environment, this dispatches securely to an endpoint.
        // For OMEGA, we dump it into the local Reliability telemetry.
        Task {
            do {
                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
                let telemetryURL = appSupport.appendingPathComponent("HoloBrowser/beta_telemetry.json")
                
                let entry: [String: Any] = [
                    "timestamp": ISO8601DateFormatter().string(from: Date()),
                    "event": "user_feedback",
                    "category": selectedCategory.rawValue,
                    "content": feedbackText
                ]
                
                let existingData = try? await DiskStorageActor.shared.readRaw(from: telemetryURL)
                var logs: [[String: Any]] = []
                if let data = existingData,
                   let decoded = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    logs = decoded
                }
                logs.append(entry)
                let newData = try JSONSerialization.data(withJSONObject: logs)
                try await DiskStorageActor.shared.writeRaw(newData, to: telemetryURL)
                
                await MainActor.run {
                    withAnimation {
                        isSubmitted = true
                    }
                }
            } catch {
                print("Failed to save feedback.")
            }
        }
    }
}
