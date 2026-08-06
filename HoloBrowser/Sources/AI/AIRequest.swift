import Foundation

public enum AIMessageRole: String, Codable {
    case system
    case user
    case assistant
}

public struct AIMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public let role: AIMessageRole
    public let content: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), role: AIMessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public struct AIRequest {
    public let messages: [AIMessage]
    public let pageContextText: String?
    public let systemInstruction: String?
    public let temperature: Double
    
    public init(
        messages: [AIMessage],
        pageContextText: String? = nil,
        systemInstruction: String? = nil,
        temperature: Double = 0.7
    ) {
        self.messages = messages
        self.pageContextText = pageContextText
        self.systemInstruction = systemInstruction
        self.temperature = temperature
    }
}

public struct AIResponse {
    public let text: String
    public let isFinished: Bool
    
    public init(text: String, isFinished: Bool = true) {
        self.text = text
        self.isFinished = isFinished
    }
}
