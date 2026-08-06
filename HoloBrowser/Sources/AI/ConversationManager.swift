import Foundation
import Combine

/// Session manager maintaining user & assistant conversation messages.
@MainActor
public final class ConversationManager: ObservableObject {
    @Published public private(set) var messages: [AIMessage] = []
    @Published public private(set) var isStreaming: Bool = false
    
    public init() {}
    
    public func appendUserMessage(_ text: String) -> AIMessage {
        let msg = AIMessage(role: .user, content: text)
        messages.append(msg)
        return msg
    }
    
    public func appendAssistantPlaceholder() -> UUID {
        let msg = AIMessage(role: .assistant, content: "")
        messages.append(msg)
        isStreaming = true
        return msg.id
    }
    
    public func updateStreamingMessage(id: UUID, text: String) {
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            let existing = messages[idx]
            messages[idx] = AIMessage(id: existing.id, role: .assistant, content: text, timestamp: existing.timestamp)
        }
    }
    
    public func finishStreaming() {
        isStreaming = false
    }
    
    public func clearConversation() {
        messages.removeAll()
        isStreaming = false
    }
}
