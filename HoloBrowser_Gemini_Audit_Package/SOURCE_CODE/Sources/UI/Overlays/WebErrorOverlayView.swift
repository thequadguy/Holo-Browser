import SwiftUI

/// Overlay banner displayed when a webpage navigation error occurs.
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
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(.orange)
            
            Text("Navigation Failed")
                .font(.title2)
                .bold()
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button(action: onRetry) {
                    Text("Retry")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 10)
        )
        .padding(24)
    }
}
