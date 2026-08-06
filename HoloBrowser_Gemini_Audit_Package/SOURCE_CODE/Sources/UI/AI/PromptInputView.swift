import SwiftUI

/// Input bar featuring quick action buttons and custom text prompt entry.
public struct PromptInputView: View {
    @ObservedObject var aiManager: AIManager
    let onSummarize: () -> Void
    let onAsk: (String) -> Void
    let onExplain: () -> Void
    let onRewrite: () -> Void
    
    @State private var promptText: String = ""
    @FocusState private var isInputFocused: Bool
    
    public init(
        aiManager: AIManager,
        onSummarize: @escaping () -> Void,
        onAsk: @escaping (String) -> Void,
        onExplain: @escaping () -> Void,
        onRewrite: @escaping () -> Void
    ) {
        self.aiManager = aiManager
        self.onSummarize = onSummarize
        self.onAsk = onAsk
        self.onExplain = onExplain
        self.onRewrite = onRewrite
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Quick Action Buttons Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    QuickActionButton(title: "Summarize", icon: "doc.plaintext") {
                        onSummarize()
                    }
                    QuickActionButton(title: "Explain Selection", icon: "text.magnifyingglass") {
                        onExplain()
                    }
                    QuickActionButton(title: "Rewrite Selection", icon: "pencil") {
                        onRewrite()
                    }
                }
                .padding(.horizontal, 8)
            }
            
            // Text Input Box
            HStack(spacing: 8) {
                TextField("Ask Holo AI about this page...", text: $promptText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isInputFocused)
                    .onSubmit {
                        submitPrompt()
                    }
                
                Button(action: submitPrompt) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(promptText.isEmpty ? .secondary : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(promptText.isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isInputFocused ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(8)
    }
    
    private func submitPrompt() {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAsk(trimmed)
        promptText = ""
    }
}

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.purple.opacity(0.12)))
            .foregroundColor(.purple)
        }
        .buttonStyle(.plain)
    }
}
