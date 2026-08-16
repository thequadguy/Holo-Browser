import Foundation
import Combine

/// Primary facade for Holo Browser AI operations. Decoupled from UI view structures.
/// Enforces mandatory AIPrivacyManager pipeline sanitization and private mode AI access validation.
@MainActor
public final class AIManager: ObservableObject {
    @Published public var provider: AIProviderProtocol
    @Published public var isSidebarVisible: Bool = false
    @Published public var activeTaskError: String?
    
    public let privacyManager: AIPrivacyManager
    public let conversationManager = ConversationManager()
    private var activeStreamTask: Task<Void, Never>?
    
    public init(
        provider: AIProviderProtocol = MockAIProvider(),
        privacyManager: AIPrivacyManager? = nil
    ) {
        self.provider = provider
        self.privacyManager = privacyManager ?? AIPrivacyManager()
    }
    
    // MARK: - Primary AI API Methods
    
    /// Summarizes the current active webpage text streamingly after mandatory gatekeeper validation.
    public func summarizePage(title: String, text: String, isPrivate: Bool = false) {
        isSidebarVisible = true
        activeTaskError = nil
        do {
            let (sanitizedTitle, sanitizedText) = try AIContextGatekeeper.shared.processAndValidateRequest(
                prompt: title,
                context: text,
                provider: provider,
                isPrivateBrowsing: isPrivate
            )
            let request = PromptBuilder.buildSummarizeRequest(pageTitle: sanitizedTitle, pageText: sanitizedText)
            _ = conversationManager.appendUserMessage("Summarize this webpage")
            streamResponse(for: request, isPrivate: isPrivate)
        } catch {
            activeTaskError = error.localizedDescription
        }
    }
    
    /// Answers a user question strictly based on current webpage context after mandatory gatekeeper validation.
    public func askPage(question: String, text: String, isPrivate: Bool = false) {
        isSidebarVisible = true
        activeTaskError = nil
        do {
            let (sanitizedQuestion, sanitizedText) = try AIContextGatekeeper.shared.processAndValidateRequest(
                prompt: question,
                context: text,
                provider: provider,
                isPrivateBrowsing: isPrivate
            )
            let request = PromptBuilder.buildAskPageRequest(question: sanitizedQuestion, pageText: sanitizedText)
            _ = conversationManager.appendUserMessage(sanitizedQuestion)
            streamResponse(for: request, isPrivate: isPrivate)
        } catch {
            activeTaskError = error.localizedDescription
        }
    }
    
    /// Explains selected text snippet after mandatory gatekeeper validation.
    public func explainSelection(_ selection: String, isPrivate: Bool = false) {
        isSidebarVisible = true
        activeTaskError = nil
        do {
            let (sanitizedSel, _) = try AIContextGatekeeper.shared.processAndValidateRequest(
                prompt: selection,
                context: "",
                provider: provider,
                isPrivateBrowsing: isPrivate
            )
            let request = PromptBuilder.buildExplainSelectionRequest(selection: sanitizedSel)
            _ = conversationManager.appendUserMessage("Explain: \"\(sanitizedSel)\"")
            streamResponse(for: request, isPrivate: isPrivate)
        } catch {
            activeTaskError = error.localizedDescription
        }
    }
    
    /// Rewrites selected text snippet after mandatory gatekeeper validation.
    public func rewriteSelection(_ selection: String, isPrivate: Bool = false) {
        isSidebarVisible = true
        activeTaskError = nil
        do {
            let (sanitizedSel, _) = try AIContextGatekeeper.shared.processAndValidateRequest(
                prompt: selection,
                context: "",
                provider: provider,
                isPrivateBrowsing: isPrivate
            )
            let request = PromptBuilder.buildRewriteSelectionRequest(selection: sanitizedSel)
            _ = conversationManager.appendUserMessage("Rewrite: \"\(sanitizedSel)\"")
            streamResponse(for: request, isPrivate: isPrivate)
        } catch {
            activeTaskError = error.localizedDescription
        }
    }
    
    /// Executes interactive chat with sanitized context after mandatory gatekeeper validation.
    public func chat(userText: String, pageText: String? = nil, isPrivate: Bool = false) {
        isSidebarVisible = true
        activeTaskError = nil
        do {
            let (sanitizedUserText, sanitizedPageText) = try AIContextGatekeeper.shared.processAndValidateRequest(
                prompt: userText,
                context: pageText ?? "",
                provider: provider,
                isPrivateBrowsing: isPrivate
            )
            let message = AIMessage(role: .user, content: sanitizedUserText)
            let request = AIRequest(
                messages: conversationManager.messages + [message],
                pageContextText: sanitizedPageText.isEmpty ? nil : sanitizedPageText
            )
            _ = conversationManager.appendUserMessage(sanitizedUserText)
            streamResponse(for: request, isPrivate: isPrivate)
        } catch {
            activeTaskError = error.localizedDescription
        }
    }
    
    /// Sends a screenshot + question to the AI provider.
    ///
    /// Phase 5 implementation: the real JPEG bytes in `visualContext` are attached to the
    /// `AIRequest` and forwarded to the provider for multimodal transmission.
    ///
    /// Screenshot lifecycle: `ScreenshotManager.clearVisualContext()` is called after the
    /// stream finishes, regardless of success or failure, so JPEG data is never retained
    /// beyond the AI request that triggered it.
    public func captureAndAsk(
        question: String,
        visualContext: HoloVisualContext,
        pageText: String?,
        isPrivate: Bool = false
    ) {
        isSidebarVisible = true
        activeTaskError = nil
        do {
            let (sanitizedQuestion, sanitizedPageText) = try AIContextGatekeeper.shared.processAndValidateRequest(
                prompt: question,
                context: pageText ?? "",
                provider: provider,
                isPrivateBrowsing: isPrivate
            )
            let message = AIMessage(role: .user, content: sanitizedQuestion)
            let sysInstruction = "You are Holo AI, a macOS browser assistant. Analyze the screenshot and respond."
            let request = AIRequest(
                messages: conversationManager.messages + [message],
                pageContextText: sanitizedPageText.isEmpty ? nil : sanitizedPageText,
                systemInstruction: sysInstruction,
                temperature: 0.7,
                visualContext: visualContext
            )
            _ = conversationManager.appendUserMessage(sanitizedQuestion)
            streamResponse(for: request, isPrivate: isPrivate)
        } catch {
            activeTaskError = error.localizedDescription
            // Clear screenshot data even on gatekeeper rejection.
            ScreenshotManager.shared.clearVisualContext()
        }
    }

    public func toggleSidebar() {
        isSidebarVisible.toggle()
    }

    public func cancelActiveStream() {
        activeStreamTask?.cancel()
        activeStreamTask = nil
        conversationManager.finishStreaming()
    }
    
    // MARK: - Streaming Core Logic

    private func streamResponse(for request: AIRequest, isPrivate: Bool) {
        cancelActiveStream()

        let assistantMsgID = conversationManager.appendAssistantPlaceholder()

        activeStreamTask = Task { @MainActor in
            var accumulatedText = ""
            do {
                // Validate Private Browsing AI rules
                try privacyManager.validateAIExecution(provider: provider, isPrivate: isPrivate)

                let stream = provider.sendMessage(request)
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    accumulatedText += chunk
                    conversationManager.updateStreamingMessage(id: assistantMsgID, text: accumulatedText)
                }
            } catch {
                self.activeTaskError = error.localizedDescription
                conversationManager.updateStreamingMessage(
                    id: assistantMsgID,
                    text: "Error: \(error.localizedDescription)"
                )
            }
            conversationManager.finishStreaming()
            // Clear transient screenshot data after AI request completes.
            ScreenshotManager.shared.clearVisualContext()
        }
    }
}
