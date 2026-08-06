import Foundation

// MARK: - Shared Streaming Session Configuration (P1-6)

/// P1-6 Fix: Custom URLSession replacing URLSession.shared for all AI provider streaming.
///
/// URLSession.shared uses timeoutIntervalForResource = 7 days, which means a stalled
/// SSE stream hangs indefinitely. This session enforces:
///   - timeoutIntervalForRequest  = 30s  (server must respond within 30 seconds)
///   - timeoutIntervalForResource = 120s (stream must complete within 2 minutes)
///
/// Additionally, Task.cancel() now properly cancels the underlying URLSession data task
/// via AsyncThrowingStream's onTermination → session.invalidateAndCancel().
private func makeStreamingSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest  = 30
    config.timeoutIntervalForResource = 120
    return URLSession(configuration: config)
}

/// Mock provider for testing and fallback without external API network latency.
/// ⚠️  PLACEHOLDER — returns canned responses only. Not suitable for production use.
/// Use AIProviderFactory.provider(for:) to build a real provider backed by Keychain credentials.
public final class MockAIProvider: AIProviderProtocol, @unchecked Sendable {
    public let name: String = "Mock Local Provider (Demo)"

    public init() {}

    public func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let userPrompt = request.messages.last?.content ?? ""
                let contextLength = request.pageContextText?.count ?? 0

                var responseText = "Here is an AI synthesis of the page content (" + String(contextLength) + " characters analyzed):\n\n"

                if userPrompt.lowercased().contains("summarize") {
                    responseText += "• Main Concept: High performance native macOS software engineering.\n• Key Takeaway: Holo Browser operates with native WebKit.\n• Technology Stack: Built using Swift, SwiftUI, AppKit, and WKWebView."
                } else if userPrompt.lowercased().contains("explain") {
                    responseText += "Explanation of selected text: The text emphasizes strict memory isolation and Swift 6 concurrency safety."
                } else {
                    responseText += "Holo AI Demo Response to '\(userPrompt)': Configure a real AI provider in Settings → AI to enable live responses."
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
///
/// P1-6 Fix: uses a dedicated URLSession with 30s request / 120s resource timeouts.
/// The session is invalidated when the stream's continuation terminates (cancelled or finished),
/// ensuring the underlying network task is properly released even if Task.cancel() is called.
public final class OpenAIProvider: AIProviderProtocol, @unchecked Sendable {
    public let name: String = "OpenAI GPT-4o"
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard !apiKey.isEmpty else {
                continuation.finish(throwing: AIError.missingAPIKey("OpenAI"))
                return
            }

            // P1-6: dedicated session per stream; invalidated on termination.
            let session = makeStreamingSession()

            continuation.onTermination = { _ in
                session.invalidateAndCancel()
            }

            Task {
                do {
                    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                        continuation.finish(throwing: AIError.invalidResponse("Invalid OpenAI endpoint URL"))
                        return
                    }

                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    // Build message array
                    var messages: [[String: String]] = []
                    if let systemPrompt = request.systemInstruction {
                        messages.append(["role": "system", "content": systemPrompt])
                    }
                    if let pageCtx = request.pageContextText, !pageCtx.isEmpty {
                        messages.append(["role": "system", "content": "Page context:\n\(pageCtx)"])
                    }
                    for msg in request.messages {
                        messages.append(["role": msg.role.rawValue, "content": msg.content])
                    }

                    let body: [String: Any] = [
                        "model": "gpt-4o",
                        "messages": messages,
                        "temperature": request.temperature,
                        "stream": true
                    ]

                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await session.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIError.invalidResponse("No HTTP response from OpenAI"))
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: AIError.httpError(httpResponse.statusCode))
                        return
                    }

                    var receivedAnyContent = false

                    // Parse SSE stream
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else {
                            continuation.finish()
                            return
                        }

                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        guard jsonString != "[DONE]" else { break }

                        if let data = jsonString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let delta = choices.first?["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            receivedAnyContent = true
                            continuation.yield(content)
                        }
                    }

                    // P1-6: If the stream completed without yielding any content, surface an error
                    // instead of silently finishing with an empty response.
                    if !receivedAnyContent {
                        continuation.finish(throwing: AIError.invalidResponse("OpenAI returned an empty response"))
                        return
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Real Anthropic Provider

/// Anthropic Claude streaming provider using Messages API.
/// API key is read from Keychain via AIProviderFactory — never from UserDefaults or disk.
///
/// P1-6 Fix: uses a dedicated URLSession with 30s request / 120s resource timeouts.
/// The session is invalidated when the stream's continuation terminates.
public final class AnthropicProvider: AIProviderProtocol, @unchecked Sendable {
    public let name: String = "Anthropic Claude 3.5 Sonnet"
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard !apiKey.isEmpty else {
                continuation.finish(throwing: AIError.missingAPIKey("Anthropic"))
                return
            }

            // P1-6: dedicated session per stream; invalidated on termination.
            let session = makeStreamingSession()

            continuation.onTermination = { _ in
                session.invalidateAndCancel()
            }

            Task {
                do {
                    guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
                        continuation.finish(throwing: AIError.invalidResponse("Invalid Anthropic endpoint URL"))
                        return
                    }

                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                    urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let userMessages = request.messages.map { msg -> [String: String] in
                        ["role": msg.role.rawValue, "content": msg.content]
                    }

                    var systemParts: [String] = []
                    if let sys = request.systemInstruction { systemParts.append(sys) }
                    if let ctx = request.pageContextText, !ctx.isEmpty {
                        systemParts.append("Page context:\n\(ctx)")
                    }
                    let systemString = systemParts.joined(separator: "\n\n")

                    var body: [String: Any] = [
                        "model": "claude-sonnet-4-5",
                        "max_tokens": 2048,
                        "messages": userMessages,
                        "stream": true
                    ]
                    if !systemString.isEmpty {
                        body["system"] = systemString
                    }

                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await session.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIError.invalidResponse("No HTTP response from Anthropic"))
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: AIError.httpError(httpResponse.statusCode))
                        return
                    }

                    var receivedAnyContent = false

                    // Parse Anthropic SSE stream
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else {
                            continuation.finish()
                            return
                        }

                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))

                        if let data = jsonString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            let eventType = json["type"] as? String
                            if eventType == "content_block_delta",
                               let delta = json["delta"] as? [String: Any],
                               let text = delta["text"] as? String {
                                receivedAnyContent = true
                                continuation.yield(text)
                            } else if eventType == "message_stop" {
                                break
                            }
                        }
                    }

                    // P1-6: Surface error on empty response instead of silent finish.
                    if !receivedAnyContent {
                        continuation.finish(throwing: AIError.invalidResponse("Anthropic returned an empty response"))
                        return
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
