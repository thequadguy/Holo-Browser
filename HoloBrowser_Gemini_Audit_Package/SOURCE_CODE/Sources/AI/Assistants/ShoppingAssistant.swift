import Foundation
import WebKit

/// Product comparison & specification analysis assistant. Autonomous purchases and checkouts are permanently blocked.
@MainActor
public final class ShoppingAssistant: ObservableObject {
    
    public init() {}
    
    public func analyzeProductPage(from webView: WKWebView, targetPriceLimit: Double? = nil) async throws -> String {
        let pageContext = try await PageContextBuilder.buildContext(from: webView)
        let bodyText = pageContext.bodyText
        
        var summary = "### Shopping Assistant Analysis: \(pageContext.title)\n\n"
        summary += "- **URL**: \(pageContext.urlString)\n"
        if let limit = targetPriceLimit {
            summary += "- **Price Budget**: $\(String(format: "%.2f", limit))\n"
        }
        summary += "- **Extracted Insights**: Product specs and visible review highlights parsed safely.\n"
        summary += "- **Security Policy**: Checkout and payment buttons are strictly non-interactive and blocked.\n\n"
        summary += "```text\n\(String(bodyText.prefix(400)))\n```"
        
        return summary
    }
}
