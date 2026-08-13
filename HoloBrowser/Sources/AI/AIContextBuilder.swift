import Foundation

/// Prompt engineering builder combining user query, DOM context, selection, and history into sanitized AIRequest models.
@MainActor
public enum AIContextBuilder {

    /// Builds an AIRequest from the given inputs.
    ///
    /// P1-4 Fix: `isPrivateBrowsing` parameter added.
    /// When true, the full page URL is NEVER sent to the AI provider —
    /// private browsing URLs can contain session tokens, auth parameters, or PII
    /// path segments (e.g. /accounts/12345?token=abc123).
    /// The page title and body content are still sent (stripped of the URL) so AI
    /// context remains useful. Callers should pass `activeProfile.isPrivate`.
    public static func buildRequest(
        userQuery: String,
        pageContext: PageContext?,
        selectionText: String?,
        historyMessages: [AIMessage] = [],
        privacyManager: AIPrivacyManager,
        isPrivateBrowsing: Bool = false
    ) -> AIRequest {
        let systemPrompt = "You are Holo AI, a high-performance native macOS web browser assistant. Provide clear, accurate, and bulleted responses."

        let sanitizedQuery = privacyManager.sanitizeContextForAI(userQuery)

        var combinedContext = ""
        if let ctx = pageContext {
            let sanitized = privacyManager.sanitizeContextForAI(ctx.bodyText)

            if isPrivateBrowsing {
                // P1-4: In private browsing, omit the URL entirely from the AI context.
                // Title is still included as it typically contains no sensitive identifiers.
                combinedContext += "Webpage Title: \(ctx.title)\n[URL redacted — Private Browsing]\n\nPage Content:\n\(sanitized)\n\n"
            } else {
                combinedContext += "Webpage Title: \(ctx.title)\nURL: \(ctx.urlString)\n\nPage Content:\n\(sanitized)\n\n"
            }
        }

        if let sel = selectionText, !sel.isEmpty {
            let sanitizedSel = privacyManager.sanitizeContextForAI(sel)
            combinedContext += "Selected Text:\n\"\(sanitizedSel)\"\n\n"
        }

        let userMsg = AIMessage(role: .user, content: sanitizedQuery)
        let allMessages = historyMessages + [userMsg]

        return AIRequest(
            messages: allMessages,
            pageContextText: combinedContext.isEmpty ? nil : combinedContext,
            systemInstruction: systemPrompt,
            temperature: 0.7
        )
    }

    /// Builds an AIRequest from a structured HoloContext model.
    public static func buildRequest(
        userQuery: String,
        holoContext: HoloContext,
        historyMessages: [AIMessage] = [],
        privacyManager: AIPrivacyManager
    ) -> AIRequest {
        let systemPrompt = "You are HoloMind, a native macOS spatial browser assistant. Provide clear, accurate, and bulleted responses."
        let sanitizedQuery = privacyManager.sanitizeContextForAI(userQuery)

        var combinedContext = ""

        if let spaceName = holoContext.activeSpaceName, !spaceName.isEmpty {
            combinedContext += "Active Holo Space: \(spaceName)\n"
        }

        if let page = holoContext.currentPage {
            if holoContext.isPrivateBrowsing {
                combinedContext += "Current Page Title: \(page.title)\n[URL Redacted — Private Browsing]\n"
            } else {
                combinedContext += "Current Page Title: \(page.title)\nURL: \(page.urlString)\n"
            }
            if !page.headings.isEmpty {
                combinedContext += "Headings: \(page.headings.joined(separator: " | "))\n"
            }
            if !page.extractedText.isEmpty {
                combinedContext += "Content Summary:\n\(page.extractedText)\n\n"
            }
        }

        if let selection = holoContext.selectedText, !selection.isEmpty {
            combinedContext += "User Selected Text:\n\"\(selection)\"\n\n"
        }

        if !holoContext.relevantTabs.isEmpty {
            combinedContext += "Relevant Open Tabs:\n"
            for tab in holoContext.relevantTabs {
                combinedContext += "- \(tab.title) (\(tab.urlString))"
                if let snippet = tab.snippet, !snippet.isEmpty {
                    combinedContext += ": \(snippet)"
                }
                combinedContext += "\n"
            }
        }

        let userMsg = AIMessage(role: .user, content: sanitizedQuery)
        let allMessages = historyMessages + [userMsg]

        return AIRequest(
            messages: allMessages,
            pageContextText: combinedContext.isEmpty ? nil : combinedContext,
            systemInstruction: systemPrompt,
            temperature: 0.7
        )
    }
}

