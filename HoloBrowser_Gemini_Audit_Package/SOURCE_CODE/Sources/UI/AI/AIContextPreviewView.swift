import SwiftUI

/// Preview modal displaying extracted page context and estimated token count before transmission to AI endpoints.
public struct AIContextPreviewView: View {
    let pageContext: PageContext
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    public init(pageContext: PageContext, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.pageContext = pageContext
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.purple)
                    Text("AI Context Transmission Preview")
                        .font(.headline)
                }
                Spacer()
            }
            
            Text("Review the webpage content extracted for AI processing:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Title: \(pageContext.title)")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                    let tokens = TokenCounter.estimateTokenCount(for: pageContext.bodyText)
                    Text("~\(tokens) Tokens")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.purple.opacity(0.12)))
                        .foregroundColor(.purple)
                }
                
                Text(pageContext.urlString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
            
            ScrollView {
                Text(pageContext.bodyText)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(8)
            }
            .frame(height: 180)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Send to Holo AI") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 460)
    }
}
