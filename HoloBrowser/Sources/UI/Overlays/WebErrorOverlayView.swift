import SwiftUI

/// Enhanced overlay banner displayed when a webpage navigation error occurs.
/// Structures error feedback around 3 explicit user questions:
/// 1. What happened?
/// 2. Why did it happen?
/// 3. What can you do?
public struct WebErrorOverlayView: View {
    let errorMessage: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    public init(errorMessage: String, onRetry: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.errorMessage = errorMessage
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header Warning Icon & Title
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Page Navigation Error")
                        .font(.title3)
                        .bold()
                    Text("Holo Browser encountered an issue while loading this page.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            // 3-Question Structured Error Explanation
            VStack(alignment: .leading, spacing: 14) {
                // 1. What happened?
                ErrorQuestionRow(
                    question: "1. What happened?",
                    answer: errorMessage.isEmpty ? "The webpage failed to load or stopped responding." : errorMessage,
                    icon: "info.circle.fill",
                    color: .blue
                )
                
                // 2. Why did it happen?
                ErrorQuestionRow(
                    question: "2. Why did it happen?",
                    answer: inferWhyReason(from: errorMessage),
                    icon: "questionmark.circle.fill",
                    color: .purple
                )
                
                // 3. What can you do?
                ErrorQuestionRow(
                    question: "3. What can you do?",
                    answer: inferWhatToDo(from: errorMessage),
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button(action: onRetry) {
                    Text("Retry Page Load")
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(24)
        .frame(width: 480)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 16)
        )
    }
    
    private func inferWhyReason(from msg: String) -> String {
        let lower = msg.lowercased()
        if lower.contains("offline") || lower.contains("internet") || lower.contains("network") {
            return "Your device appears to be offline or disconnected from Wi-Fi."
        } else if lower.contains("ssl") || lower.contains("certificate") || lower.contains("security") {
            return "The website server's security certificate could not be verified."
        } else if lower.contains("timeout") || lower.contains("timed out") {
            return "The destination server took too long to respond."
        } else {
            return "The server or web host may be temporarily unavailable or domain name lookup failed."
        }
    }
    
    private func inferWhatToDo(from msg: String) -> String {
        let lower = msg.lowercased()
        if lower.contains("offline") || lower.contains("network") {
            return "Check your Wi-Fi or Ethernet connection, then click Retry."
        } else if lower.contains("ssl") || lower.contains("certificate") {
            return "Verify the web address spelling or try visiting again later."
        } else {
            return "Click 'Retry Page Load' or verify the web URL address in the bar."
        }
    }
}

private struct ErrorQuestionRow: View {
    let question: String
    let answer: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(question)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text(answer)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}
