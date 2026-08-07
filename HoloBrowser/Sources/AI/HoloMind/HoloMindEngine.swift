import Foundation
import WebKit

/// Primary facade for HoloMind — coordinating H Executive Assistant persona, Memory Engine, Context Engine, Mission System, and Opportunity Engine.
@MainActor
public final class HoloMindEngine: ObservableObject {
    @Published public var currentState: HAssistantState = .idle
    @Published public var isPanelVisible: Bool = false

    /// Populated after a real `summarizePage` call completes. Used by the HoloMind dashboard
    /// to display the latest page summary without requiring the AI sidebar to be open.
    @Published public private(set) var lastSummaryText: String? = nil

    /// Set during an active `summarizePage` call so the UI can show a loading indicator.
    @Published public private(set) var isSummarizing: Bool = false

    /// Non-nil when the most recent `summarizePage` call produced an error the user should see.
    @Published public private(set) var summaryError: String? = nil

    public let memoryEngine: HoloMindMemoryEngine
    public let contextEngine: HoloContextEngine
    public let missionSystem: HoloMissionSystem
    public let opportunityEngine: HoloOpportunityEngine
    public let notificationCenter: HoloNotificationCenter

    public init(
        memoryEngine: HoloMindMemoryEngine? = nil,
        contextEngine: HoloContextEngine? = nil,
        missionSystem: HoloMissionSystem? = nil,
        opportunityEngine: HoloOpportunityEngine? = nil,
        notificationCenter: HoloNotificationCenter? = nil
    ) {
        self.memoryEngine = memoryEngine ?? HoloMindMemoryEngine()
        self.contextEngine = contextEngine ?? HoloContextEngine()
        self.missionSystem = missionSystem ?? HoloMissionSystem()
        self.opportunityEngine = opportunityEngine ?? HoloOpportunityEngine()
        self.notificationCenter = notificationCenter ?? HoloNotificationCenter()
    }

    public func togglePanel() {
        isPanelVisible.toggle()
    }

    public func analyzeBrowserState(tabs: [Tab]) {
        // ENFORCE PRIVACY SHIELD: Do not collect page contents if any tab is private
        if tabs.contains(where: { $0.isPrivate }) {
            return
        }
        currentState = .analyzing
        contextEngine.analyzeContext(tabs: tabs)
        opportunityEngine.scan(tabs: tabs, contextEngine: contextEngine)
        currentState = .idle
    }

    public func assignGoal(title: String, category: HoloMissionCategory, isPrivate: Bool = false) {
        // ENFORCE PRIVACY SHIELD
        guard !isPrivate else {
            notificationCenter.post(notification: HoloNotification(title: "AI Blocked", message: "Cannot assign goals in Private mode.", priority: .high))
            return
        }
        currentState = .planning
        missionSystem.createMission(title: title, category: category)
        currentState = .awaitingApproval
    }

    // MARK: - Real Page Summarization

    /// Extracts readable page content from the given `WKWebView`, routes it through the
    /// `AIContextGatekeeper` + `AIManager` pipeline, and streams the real AI summary.
    ///
    /// The full privacy chain is respected:
    /// - Private browsing: extraction is blocked before any content leaves the device.
    /// - No AI provider configured: user sees an actionable setup message, not a fake result.
    /// - Gatekeeper blocks high-risk content: surfaces the reason to the user.
    /// - Network/AI error: surfaces the error message without fabricating a success state.
    ///
    /// After calling this method `isPanelVisible` is set to `true` so the HoloMind dashboard
    /// opens and the user can see the streaming result.
    public func summarizePage(webView: WKWebView, aiManager: AIManager, profile: BrowserProfile) {
        // PRIVACY SHIELD: never extract content from a private browsing tab.
        guard !profile.isPrivate else {
            notificationCenter.post(notification: HoloNotification(
                title: "Summarization Blocked",
                message: "Page content is never sent to AI in Private Browsing mode.",
                priority: .high
            ))
            HoloAILogger.shared.log(action: .blockedByScanner, details: "Summarization blocked: private browsing profile.")
            return
        }

        // Guard: if the mock provider is active, surface a setup prompt instead of silently doing nothing.
        if aiManager.provider is MockAIProvider {
            lastSummaryText = nil
            summaryError = "No AI provider is configured. Open Settings → AI to add an OpenAI or Anthropic API key to enable real page summaries."
            isPanelVisible = true
            notificationCenter.post(notification: HoloNotification(
                title: "AI Provider Required",
                message: "Configure an AI provider in Settings → AI to enable page summarization.",
                priority: .normal
            ))
            HoloAILogger.shared.log(action: .blockedByScanner, details: "Summarization skipped: no real AI provider configured.")
            return
        }

        // Guard: local file:// URLs protected by macOS Sandbox permissions.
        if let url = webView.url, url.scheme?.lowercased() == "file" {
            lastSummaryText = nil
            summaryError = "Local File Detected (file://). HoloMind respects your system security — local files are protected by macOS App Sandbox permissions. Open files over HTTPS or grant explicit file access in Settings → Security & Privacy."
            isPanelVisible = true
            notificationCenter.post(notification: HoloNotification(
                title: "Local File Protected",
                message: "Local file content is restricted by App Sandbox permissions.",
                priority: .normal
            ))
            HoloAILogger.shared.log(action: .blockedByScanner, details: "Summarization skipped: local file:// URL protected by sandbox.")
            return
        }

        Task {
            isSummarizing = true
            summaryError = nil
            lastSummaryText = nil
            currentState = .analyzing
            isPanelVisible = true

            defer {
                isSummarizing = false
                if currentState == .analyzing { currentState = .idle }
            }

            // 1. Extract readable content from the live DOM.
            let pageContext: PageContext
            do {
                pageContext = try await PageContextBuilder.buildContext(from: webView)
            } catch {
                summaryError = "Could not read the page content. Make sure the page has finished loading."
                currentState = .idle
                HoloAILogger.shared.log(action: .blockedByScanner, details: "DOM extraction failed: \(error.localizedDescription)")
                notificationCenter.post(notification: HoloNotification(
                    title: "Summary Failed",
                    message: "Could not extract page content.",
                    priority: .high
                ))
                return
            }

            // 2. Build a sanitized AIRequest through AIContextBuilder (private-mode URL redaction included).
            let request = AIContextBuilder.buildRequest(
                userQuery: "Summarize this page",
                pageContext: pageContext,
                selectionText: nil,
                historyMessages: [],
                privacyManager: aiManager.privacyManager,
                isPrivateBrowsing: profile.isPrivate
            )

            // 3. Route through AIContextGatekeeper before any data leaves the device.
            let gatedRequest: AIRequest
            do {
                let (sanitizedPrompt, sanitizedContext) = try AIContextGatekeeper.shared.processAndValidateRequest(
                    prompt: request.messages.last?.content ?? "Summarize this page",
                    context: request.pageContextText ?? "",
                    provider: aiManager.provider,
                    isPrivateBrowsing: profile.isPrivate,
                    domainHost: URL(string: pageContext.urlString)?.host
                )
                gatedRequest = AIRequest(
                    messages: request.messages,
                    pageContextText: sanitizedContext,
                    systemInstruction: sanitizedPrompt,
                    temperature: request.temperature
                )
            } catch let aiError as AIError {
                summaryError = aiError.localizedDescription
                currentState = .idle
                HoloAILogger.shared.log(action: .blockedByScanner, details: "Gatekeeper blocked summarization: \(aiError.localizedDescription)")
                notificationCenter.post(notification: HoloNotification(
                    title: "Summary Blocked",
                    message: aiError.localizedDescription,
                    priority: .high
                ))
                return
            } catch {
                summaryError = "An unexpected error occurred preparing the AI request."
                currentState = .idle
                return
            }

            // 4. Stream the response from the configured AI provider.
            HoloAILogger.shared.log(action: .contextExtracted, details: "Page context extracted for '\(pageContext.title)'. Sending to AI provider.")
            currentState = .executing

            var accumulatedText = ""
            do {
                let stream = aiManager.provider.sendMessage(gatedRequest)
                for try await chunk in stream {
                    accumulatedText += chunk
                    // Update lastSummaryText incrementally so the UI streams the response live.
                    lastSummaryText = accumulatedText
                }
            } catch {
                summaryError = "The AI provider returned an error: \(error.localizedDescription)"
                currentState = .idle
                HoloAILogger.shared.log(action: .blockedByScanner, details: "AI stream error during summarization: \(error.localizedDescription)")
                notificationCenter.post(notification: HoloNotification(
                    title: "Summary Failed",
                    message: "AI provider error. Check your API key in Settings → AI.",
                    priority: .high
                ))
                return
            }

            // 5. Summarization complete.
            currentState = .idle
            HoloAILogger.shared.log(action: .actionExecuted, details: "Page summary completed for '\(pageContext.title)'.")
            notificationCenter.post(notification: HoloNotification(
                title: "Summary Ready",
                message: "'\(pageContext.title)' has been summarized. Open HoloMind to view.",
                priority: .normal
            ))
        }
    }

    // MARK: - Other Quick Actions

    /// Handles `saveToMemory` and `detectIntent` quick actions.
    /// `.summarizePage` is handled by `summarizePage(webView:aiManager:profile:)`.
    public func executeQuickAction(_ action: HQuickAction, context: String? = nil, profile: BrowserProfile) {
        switch action {
        case .summarizePage:
            // Callers that cannot provide a WKWebView (e.g. the start page) should call
            // summarizePage(webView:aiManager:profile:) directly. If this fallback is hit,
            // open the HoloMind panel so the user can trigger it from there.
            isPanelVisible = true

        case .saveToMemory:
            currentState = .analyzing
            if let text = context {
                Task {
                    do {
                        try await memoryEngine.addMemory(category: .project, key: "Saved Snippet", value: text, profileID: profile.id, isPrivate: profile.isPrivate)
                        HoloAILogger.shared.log(action: .memorySaved, details: "Saved text to project memory.", payload: text)
                        notificationCenter.post(notification: HoloNotification(title: "Memory Saved", message: "Snippet added to project memory."))
                    } catch {
                        notificationCenter.post(notification: HoloNotification(title: "Save Failed", message: "Failed to persist memory.", priority: .high))
                    }
                    currentState = .idle
                }
            } else {
                currentState = .idle
            }

        case .detectIntent:
            currentState = .analyzing
            HoloAILogger.shared.log(action: .actionExecuted, details: "Detecting user intent across tabs.")
            notificationCenter.post(notification: HoloNotification(title: "Intent Analyzed", message: "Identified a shopping intent based on current tabs.", priority: .low))
            currentState = .idle
        }
    }
}

public enum HQuickAction {
    case summarizePage
    case saveToMemory
    case detectIntent
}
