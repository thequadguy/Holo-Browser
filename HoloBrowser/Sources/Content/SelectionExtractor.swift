import WebKit

/// Utility extracting active user text selection from WKWebView.
public enum SelectionExtractor {
    
    private static let selectionJS = "window.getSelection().toString();"
    
    @MainActor
    public static func extractSelection(from webView: WKWebView) async -> String? {
        do {
            let result = try await webView.evaluateJavaScript(selectionJS)
            if let selection = result as? String, !selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return selection
            }
        } catch {
            return nil
        }
        return nil
    }
}
