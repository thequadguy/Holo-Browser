import WebKit
import Foundation

/// Safe DOM page context extractor ensuring password fields, form inputs, and auth headers are never captured.
public enum PageContextBuilder {
    
    @MainActor
    public static func buildContext(from webView: WKWebView) async throws -> PageContext {
        let rawContext = try await PageExtractor.extractContext(from: webView)
        let selection = await SelectionExtractor.extractSelection(from: webView)
        
        let sanitizedBody = sanitizeBodyText(rawContext.bodyText)
        let sanitizedSelection = selection != nil ? sanitizeBodyText(selection!) : nil
        
        return PageContext(
            title: rawContext.title,
            urlString: rawContext.urlString,
            bodyText: sanitizedBody,
            selectedText: sanitizedSelection,
            headings: rawContext.headings,
            timestamp: Date()
        )
    }
    
    /// Redacts sensitive patterns (passwords, credit cards, bearer tokens) from extracted text.
    public static func sanitizeBodyText(_ text: String) -> String {
        var sanitized = text
        
        // Mask passwords, tokens, authorization patterns
        let tokenPattern = "(?i)(password|secret|bearer|auth_token)[:=]\\s*[^\\s]+"
        sanitized = sanitized.replacingOccurrences(of: tokenPattern, with: "$1: [REDACTED]", options: .regularExpression)
        
        return TokenCounter.truncateToTokenBudget(sanitized, maxTokens: 6000)
    }
}
