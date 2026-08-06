import SwiftUI

/// Scrollable view rendering active AI conversation message history.
public struct ConversationView: View {
    @ObservedObject var conversationManager: ConversationManager
    
    public init(conversationManager: ConversationManager) {
        self.conversationManager = conversationManager
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    if conversationManager.messages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundColor(.purple)
                            
                            Text("Holo AI Assistant")
                                .font(.headline)
                            
                            Text("Ask questions, summarize articles, or analyze webpage context on-demand.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 220)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(conversationManager.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if conversationManager.isStreaming {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.leading, 12)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: conversationManager.messages.count) {
                if let last = conversationManager.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}
