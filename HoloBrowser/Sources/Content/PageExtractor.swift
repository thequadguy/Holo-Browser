import WebKit

/// Utility extracting clean article text and structural metadata from WKWebView DOM via JavaScript evaluation.
public enum PageExtractor {
    
    private static let extractionJS = """
    (function() {
        var body = document.body ? document.body.innerText : '';
        var title = document.title || '';
        var headings = Array.from(document.querySelectorAll('h1, h2, h3'))
                            .map(function(h) { return h.innerText.trim(); })
                            .filter(function(t) { return t.length > 0; });
        return {
            title: title,
            bodyText: body.substring(0, 30000),
            headings: headings.slice(0, 15)
        };
    })()
    """
    
    @MainActor
    public static func extractContext(from webView: WKWebView) async throws -> PageContext {
        let result = try await webView.evaluateJavaScript(extractionJS)
        guard let dict = result as? [String: Any] else {
            throw AIError.invalidResponse("Failed to parse DOM extraction result.")
        }
        
        let title = dict["title"] as? String ?? ""
        let bodyText = dict["bodyText"] as? String ?? ""
        let headings = dict["headings"] as? [String] ?? []
        let urlString = webView.url?.absoluteString ?? ""
        
        let truncatedBody = TokenCounter.truncateToTokenBudget(bodyText, maxTokens: 6000)
        
        return PageContext(
            title: title,
            urlString: urlString,
            bodyText: truncatedBody,
            headings: headings
        )
    }
}
