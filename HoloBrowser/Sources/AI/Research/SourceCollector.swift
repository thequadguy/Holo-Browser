import WebKit
import Foundation

/// Webpage source collector capturing title, URL, and summary while stripping passwords and sensitive parameters.
public enum SourceCollector {
    
    @MainActor
    public static func collectSource(from webView: WKWebView) async throws -> ResearchSource {
        let pageContext = try await PageContextBuilder.buildContext(from: webView)
        let summarySnippet = PageContextBuilder.sanitizeBodyText(pageContext.bodyText)
        let truncatedSummary = String(summarySnippet.prefix(500))
        
        return ResearchSource(
            title: pageContext.title.isEmpty ? pageContext.urlString : pageContext.title,
            urlString: pageContext.urlString,
            faviconURLString: nil,
            summary: truncatedSummary,
            dateCollected: Date()
        )
    }
}
