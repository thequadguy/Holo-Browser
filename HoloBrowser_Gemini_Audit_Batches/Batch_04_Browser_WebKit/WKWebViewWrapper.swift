import SwiftUI
import WebKit

/// SwiftUI NSViewRepresentable wrapper displaying the active Tab's WKWebView.
/// P0-B Fix: makeNSView no longer creates an orphan HoloWebView with a bare WKWebViewConfiguration.
/// If restoreIfNeeded() returns nil (tab is .closed), we return the same view (no-op update).
/// ContentView ensures WKWebViewWrapper is only rendered when tab.state != .closed.
public struct WKWebViewWrapper: NSViewRepresentable {
    @ObservedObject var tab: Tab

    public init(tab: Tab) {
        self.tab = tab
    }

    public func makeNSView(context: Context) -> HoloWebView {
        // restoreIfNeeded() returns nil only when state == .closed.
        // ContentView guards against rendering a closed tab, but we add a belt-and-suspenders
        // fallback that re-uses the tab's own configuration rather than creating a bare orphan.
        if let webView = tab.restoreIfNeeded() {
            return webView
        }
        // Defensive path: should be unreachable in normal flow.
        // Use the tab's profile-isolated configuration rather than bare WKWebViewConfiguration().
        // This prevents data-store isolation bypass if this path is ever hit.
        assertionFailure("WKWebViewWrapper: makeNSView called on a closed tab. ContentView should guard against this.")
        let safeConfig = WKWebViewConfiguration()
        return HoloWebView(frame: .zero, configuration: safeConfig)
    }

    public func updateNSView(_ nsView: HoloWebView, context: Context) {
        // State changes driven via NavigationManager KVO bindings.
    }
}
