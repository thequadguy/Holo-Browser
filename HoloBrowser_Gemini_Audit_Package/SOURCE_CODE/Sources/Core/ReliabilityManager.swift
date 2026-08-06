import Foundation

/// Main-actor reliability manager monitoring WebKit process crashes and recovering terminated tabs cleanly.
/// P0-A Fix: ReliabilityManager is now purely a state tracker.
/// The single authoritative reload is performed by NavigationManager.webViewWebContentProcessDidTerminate.
/// A second reload here was a regression that caused a double-load on every crash.
@MainActor
public final class ReliabilityManager: ObservableObject {
    @Published public private(set) var crashCount: Int = 0
    @Published public private(set) var lastRecoveredURLString: String?

    public init() {}

    /// Called after NavigationManager has already reloaded the crashed webview.
    /// Increments crash telemetry and records the URL for UI display.
    /// Does NOT call webView.reload() — NavigationManager is the single owner of crash recovery.
    public func handleWebContentProcessTermination(tab: Tab) {
        self.crashCount += 1
        self.lastRecoveredURLString = tab.url?.absoluteString
        // Recovery reload is performed exclusively by NavigationManager.
        // Calling reload() here would produce a double-reload race condition.
    }
}
