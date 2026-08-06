import Foundation

/// Provider conforming to AIProviderProtocol executing AI requests on local Apple Silicon or Ollama hardware.
public final class LocalAIProvider: AIProviderProtocol, @unchecked Sendable {
    public let name: String = "Local AI (CoreML / Ollama)"
    public let isLocal: Bool = true
    
    private let engine = LocalInferenceEngine()
    private let backend: LocalBackendType
    private let modelID: String
    
    public init(backend: LocalBackendType = .coreML, modelID: String = "coreml-phi3-mini") {
        self.backend = backend
        self.modelID = modelID
    }
    
    public func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        let userPrompt = request.messages.last?.content ?? ""
        let context = request.pageContextText
        let fullPrompt = context != nil ? "Context: \(context!)\n\nPrompt: \(userPrompt)" : userPrompt
        return engine.generateStream(prompt: fullPrompt, modelID: modelID, backend: backend)
    }
}
