import Foundation

/// Local inference engine querying local LLM backends (Ollama REST API at `http://127.0.0.1:11434/api/generate`).
public final class LocalInferenceEngine: Sendable {
    public init() {}
    
    public func generateStream(prompt: String, modelID: String, backend: LocalBackendType) -> AsyncThrowingStream<String, Error> {
        let p = prompt
        let m = modelID
        return AsyncThrowingStream { continuation in
            Task {
                await queryOllama(prompt: p, modelID: m, continuation: continuation)
            }
        }
    }
    
    private func queryOllama(prompt: String, modelID: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        guard let url = URL(string: "http://127.0.0.1:11434/api/generate") else {
            continuation.finish(throwing: AIError.invalidResponse("Invalid local Ollama endpoint"))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        let targetModel = modelID.replacingOccurrences(of: "ollama-", with: "").replacingOccurrences(of: "coreml-", with: "")
        let body: [String: Any] = [
            "model": targetModel.isEmpty ? "llama3" : targetModel,
            "prompt": prompt,
            "stream": false
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let responseText = json["response"] as? String {
                    continuation.yield(responseText)
                } else {
                    continuation.finish(throwing: AIError.invalidResponse("Malformed response from local Ollama service"))
                    return
                }
            } else {
                continuation.finish(throwing: AIError.invalidResponse("Local Ollama service unreachable at http://127.0.0.1:11434"))
                return
            }
        } catch {
            continuation.finish(throwing: AIError.networkError("Local AI host connection failed. Ensure Ollama is running locally."))
            return
        }
        continuation.finish()
    }
}
