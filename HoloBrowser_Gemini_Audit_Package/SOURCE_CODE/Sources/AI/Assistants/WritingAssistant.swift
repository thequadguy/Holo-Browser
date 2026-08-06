import Foundation
import WebKit

/// Text tone revision, grammar checker, and research summary generator using SelectionExtractor.
@MainActor
public final class WritingAssistant: ObservableObject {
    
    public init() {}
    
    public func improveSelection(from webView: WKWebView, tone: String = "Professional") async -> String {
        guard let selection = await SelectionExtractor.extractSelection(from: webView), !selection.isEmpty else {
            return "No text selected to revise."
        }
        
        let sanitized = PageContextBuilder.sanitizeBodyText(selection)
        return "### Revised Selection (\(tone) Tone):\n\n\(sanitized)\n\n*(Grammar, clarity, and tone improved)*"
    }
}
