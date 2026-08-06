import SwiftUI

/// Chat bubble rendering user prompts and assistant streaming responses.
public struct ChatBubble: View {
    let message: AIMessage
    
    public init(message: AIMessage) {
        self.message = message
    }
    
    public var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: message.role == .user ? "person.fill" : "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(message.role == .user ? .accentColor : .purple)
                    
                    Text(message.role == .user ? "You" : "Holo AI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                Text(message.content.isEmpty ? "..." : message.content)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.role == .user ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    )
            }
            
            if message.role != .user { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
