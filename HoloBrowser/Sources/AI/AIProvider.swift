import Foundation

// MARK: - Shared Streaming Session Configuration

/// Custom URLSession replacing URLSession.shared for all AI provider streaming.
///
/// URLSession.shared uses timeoutIntervalForResource = 7 days, which means a stalled
/// SSE stream hangs indefinitely. This session enforces:
///   - timeoutIntervalForRequest  = 30s  (server must respond within 30 seconds)
///   - timeoutIntervalForResource = 120s (stream must complete within 2 minutes)
///
/// Additionally, Task.cancel() properly cancels the underlying URLSession data task
/// via AsyncThrowingStream's onTermination → session.invalidateAndCancel().
private func makeStreamingSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest  = 30
    config.timeoutIntervalForResource = 120
    return URLSession(configuration: config)
}

// MARK: - Mock Provider

/// Mock provider for testing and fallback without external API network latency.
/// ⚠️  PLACEHOLDER — returns canned responses only. Not suitable for production use.
/// Use AIProviderFactory.provider(for:) to build a real provider backed by Keychain credentials.
public final class MockAIProvider: AIProviderProtocol, @unchecked Sendable {
    public let name: String = "Mock Local Provider (Demo)"
    public var isLocal: Bool { true }

    public init() {}

    public func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let userPrompt = request.messages.last?.content ?? ""
                let contextLength = request.pageContextText?.count ?? 0

                var responseText = "Here is an AI synthesis of the page content (\(contextLength) characters analyzed):\n\n"

                if let visual = request.visualContext {
                    responseText = "Mock: received screenshot (\(visual.width)×\(visual.height) px).\n"
                } else if userPrompt.lowercased().contains("summarize") {
                    responseText += "• Main Concept: High performance macOS engineering.\n"
                    responseText += "• Technology Stack: Swift, SwiftUI, AppKit, and WKWebView."
                } else if userPrompt.lowercased().contains("explain") {
                    responseText += "Explanation: The text emphasizes strict memory isolation and concurrency."
                } else {
                    responseText += "Holo AI Demo: Configure a real AI provider in Settings → AI."
                }

                let words = responseText.split(separator: " ")
                for word in words {
                    try? await Task.sleep(nanoseconds: 30_000_000)
                    continuation.yield(String(word) + " ")
                }

                continuation.finish()
            }
        }
    }
}

// MARK: - Real OpenAI Provider

/// OpenAI GPT-4o streaming provider using Chat Completions API with SSE.
/// API key is read from Keychain via AIProviderFactory — never from UserDefaults or disk.
public final class OpenAIProvider: AIProviderProtocol, @unchecked Sendable {
    public let name: String = "OpenAI GPT-4o"
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard !self.apiKey.isEmpty else {
                continuation.finish(throwing: AIError.missingAPIKey("OpenAI"))
                return
            }

            let session = makeStreamingSession()
            continuation.onTermination = { _ in session.invalidateAndCancel() }

            Task {
                do {
                    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                        continuation.finish(throwing: AIError.invalidResponse("Invalid endpoint"))
                        return
                    }

                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let messages = self.buildOpenAIMessages(from: request)
                    let body: [String: Any] = [
                        "model": "gpt-4o",
                        "messages": messages,
                        "temperature": request.temperature,
                        "stream": true
                    ]
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await session.bytes(for: urlRequest)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIError.invalidResponse("No HTTP response"))
                        return
                    }
                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: AIError.httpError(httpResponse.statusCode))
                        return
                    }

                    var receivedAny = false
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else { break }
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        guard jsonString != "[DONE]" else { break }

                        if let chunk = self.extractOpenAIContent(from: jsonString) {
                            receivedAny = true
                            continuation.yield(chunk)
                        }
                    }

                    if !receivedAny {
                        continuation.finish(throwing: AIError.invalidResponse("Empty response"))
                        return
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func buildOpenAIMessages(from request: AIRequest) -> [[String: Any]] {
        var messages: [[String: Any]] = []
        if let systemPrompt = request.systemInstruction {
            messages.append(["role": "system", "content": systemPrompt])
        }
        if let pageCtx = request.pageContextText, !pageCtx.isEmpty {
            messages.append(["role": "system", "content": "Page context:\n\(pageCtx)"])
        }

        let historyMessages = request.messages.dropLast()
        for msg in historyMessages {
            messages.append(["role": msg.role.rawValue, "content": msg.content])
        }

        if let last = request.messages.last {
            if let visual = request.visualContext {
                let base64Image = visual.imageData.base64EncodedString()
                let contentArray: [[String: Any]] = [
                    ["type": "text", "text": last.content],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:\(visual.mimeType);base64,\(base64Image)",
                            "detail": "high"
                        ]
                    ]
                ]
                messages.append(["role": last.role.rawValue, "content": contentArray])
            } else {
                messages.append(["role": last.role.rawValue, "content": last.content])
            }
        }
        return messages
    }

    private func extractOpenAIContent(from jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String else {
            return nil
        }
        return content
    }
}

// MARK: - Real Anthropic Provider

/// Anthropic Claude streaming provider using Messages API.
/// API key is read from Keychain via AIProviderFactory — never from UserDefaults or disk.
public final class AnthropicProvider: AIProviderProtocol, @unchecked Sendable {
    public let name: String = "Anthropic Claude 3.5 Sonnet"
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard !self.apiKey.isEmpty else {
                continuation.finish(throwing: AIError.missingAPIKey("Anthropic"))
                return
            }

            let session = makeStreamingSession()
            continuation.onTermination = { _ in session.invalidateAndCancel() }

            Task {
                do {
                    guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
                        continuation.finish(throwing: AIError.invalidResponse("Invalid endpoint"))
                        return
                    }

                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue(self.apiKey, forHTTPHeaderField: "x-api-key")
                    urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let userMessages = self.buildAnthropicMessages(from: request)
                    var body: [String: Any] = [
                        "model": "claude-sonnet-4-5",
                        "max_tokens": 2048,
                        "messages": userMessages,
                        "stream": true
                    ]

                    let systemString = self.buildSystemString(from: request)
                    if !systemString.isEmpty { body["system"] = systemString }

                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
                    let (bytes, response) = try await session.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIError.invalidResponse("No HTTP response"))
                        return
                    }
                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: AIError.httpError(httpResponse.statusCode))
                        return
                    }

                    var receivedAny = false
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else { break }
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))

                        if let chunk = self.extractAnthropicContent(from: jsonString) {
                            receivedAny = true
                            continuation.yield(chunk)
                        }
                    }

                    if !receivedAny {
                        continuation.finish(throwing: AIError.invalidResponse("Empty response"))
                        return
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func buildAnthropicMessages(from request: AIRequest) -> [[String: Any]] {
        let historyMessages = request.messages.dropLast()
        var userMessages: [[String: Any]] = historyMessages.map { msg in
            ["role": msg.role.rawValue, "content": msg.content]
        }

        if let last = request.messages.last {
            if let visual = request.visualContext {
                let base64Image = visual.imageData.base64EncodedString()
                let contentBlocks: [[String: Any]] = [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": visual.mimeType,
                            "data": base64Image
                        ]
                    ],
                    ["type": "text", "text": last.content]
                ]
                userMessages.append(["role": last.role.rawValue, "content": contentBlocks])
            } else {
                userMessages.append(["role": last.role.rawValue, "content": last.content])
            }
        }
        return userMessages
    }

    private func buildSystemString(from request: AIRequest) -> String {
        var systemParts: [String] = []
        if let sys = request.systemInstruction { systemParts.append(sys) }
        if let ctx = request.pageContextText, !ctx.isEmpty {
            systemParts.append("Page context:\n\(ctx)")
        }
        return systemParts.joined(separator: "\n\n")
    }

    private func extractAnthropicContent(from jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let eventType = json["type"] as? String
        if eventType == "content_block_delta",
           let delta = json["delta"] as? [String: Any],
           let text = delta["text"] as? String {
            return text
        }
        return nil
    }
}
