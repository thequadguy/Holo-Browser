import Foundation

/// Protocol interface for AI service providers (Anthropic, OpenAI, Gemini, Local models).
public protocol AIProviderProtocol: Sendable {
    var name: String { get }
    var isLocal: Bool { get }
    func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error>
}

public extension AIProviderProtocol {
    var isLocal: Bool { false }
}
