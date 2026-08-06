import Foundation
import WebKit
import Combine

// MARK: - Weak Script Message Handler Proxy (P0-Fix-4)

/// Breaks the WKUserContentController → BrowserViewModel retain cycle.
/// WKUserContentController retains its message handler strongly; using a proxy
/// with a weak back-reference ensures the handler releases with the owning object.
final class WeakScriptMessageProxy: NSObject, WKScriptMessageHandler, @unchecked Sendable {
    weak var target: (AnyObject & WKScriptMessageHandler)?

    init(target: AnyObject & WKScriptMessageHandler) {
        self.target = target
    }

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        Task { @MainActor in
            self.target?.userContentController(userContentController, didReceive: message)
        }
    }

}

// MARK: - Tab

/// Data model and WebKit state wrapper for a single browser tab.
/// P0-Fix-1: accepts a WKWebsiteDataStore so the caller (TabManager) can inject profile-isolated storage.
/// P0-Fix-2: assigns navigationDelegate and uiDelegate on every webview creation.
/// P0-Fix-3: implements webViewWebContentProcessDidTerminate via NavigationManager delegation.
@MainActor
public final class Tab: Identifiable, ObservableObject {
    public let id: UUID
    public let navigationManager: NavigationManager

    @Published public private(set) var url: URL?
    @Published public private(set) var title: String = ""
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var canGoBack: Bool = false
    @Published public private(set) var canGoForward: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    @Published public private(set) var state: TabState = .background
    @Published public var isPinned: Bool = false
    @Published public var crashCount: Int = 0


    // P0-Fix-1: injected profile data store (non-persistent for private, per-profile otherwise)
    private let websiteDataStore: WKWebsiteDataStore

    private(set) var webViewInstance: HoloWebView?
    private var cancellables = Set<AnyCancellable>()

    /// `permissionManager` is held weakly to avoid a delegate retain cycle;
    /// it is owned by ContentView / the injection site above.
    public weak var permissionManager: PermissionManager?

    /// `reliabilityManager` is held weakly; owned by ContentView.
    public weak var reliabilityManager: ReliabilityManager?

    public init(
        id: UUID = UUID(),
        initialURL: URL? = nil,
        isPinned: Bool = false,
        navigationManager: NavigationManager? = nil,
        websiteDataStore: WKWebsiteDataStore? = nil   // P0-Fix-1 injection point
    ) {
        self.id = id
        self.url = initialURL
        self.isPinned = isPinned
        self.navigationManager = navigationManager ?? NavigationManager()
        // Resolve the data store on the MainActor (where WKWebsiteDataStore.default() is safe to call)
        self.websiteDataStore = websiteDataStore ?? WKWebsiteDataStore.default()
        setupBindings()

        if let initialURL = initialURL {
            self.navigationManager.load(url: initialURL)
        }
    }

    public var webView: WKWebView? {
        if webViewInstance == nil, state != .closed {
            _ = restoreIfNeeded()
        }
        return webViewInstance
    }

    private func setupBindings() {
        navigationManager.$currentURL
            .receive(on: DispatchQueue.main)
            .assign(to: &$url)

        navigationManager.$pageTitle
            .receive(on: DispatchQueue.main)
            .assign(to: &$title)

        navigationManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        navigationManager.$estimatedProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$progress)

        navigationManager.$canGoBack
            .receive(on: DispatchQueue.main)
            .assign(to: &$canGoBack)

        navigationManager.$canGoForward
            .receive(on: DispatchQueue.main)
            .assign(to: &$canGoForward)

        navigationManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }

    public func activate() {
        guard state != .active else { return }
        _ = restoreIfNeeded()
        state = .active
    }

    public func deactivate() {
        guard state == .active else { return }
        state = .background
    }

    public func suspend() {
        guard state == .background else { return }
        state = .suspended
        webViewInstance?.stopLoading()
        webViewInstance?.navigationDelegate = nil
        webViewInstance?.uiDelegate = nil
        webViewInstance = nil
        // P1-8 Fix: nil out NavigationManager.webView so its Combine/KVO publishers
        // on isLoading, estimatedProgress, canGoBack, canGoForward, title, URL
        // are cancelled before the HoloWebView deallocates.
        // Without this, suspending 50+ tabs leaves 300+ orphaned Combine subscribers.
        navigationManager.webView = nil
    }


    // MARK: - WebView Creation (P0-Fix-1, P0-Fix-2)

    @discardableResult
    public func restoreIfNeeded() -> HoloWebView? {
        guard webViewInstance == nil else { return webViewInstance }

        // P0-Fix-1: use the profile-isolated WKWebsiteDataStore injected at init.
        let config = WKWebViewConfiguration()
        config.websiteDataStore = websiteDataStore

        let wv = HoloWebView(frame: .zero, configuration: config)

        // P0-Fix-2: assign navigation delegate so all WKNavigationDelegate callbacks fire.
        wv.navigationDelegate = navigationManager

        // P0-Fix-3: wire back-reference so crash recovery can reach ReliabilityManager via this tab.
        navigationManager.owningTab = self

        // P0-Fix-2: assign UI delegate for permission and new-window handling.
        if let pm = permissionManager {
            wv.uiDelegate = pm
        }

        self.webViewInstance = wv
        navigationManager.webView = wv

        if let currentURL = url {
            navigationManager.load(url: currentURL)
        }

        if state == .suspended {
            state = .background
        }

        return webViewInstance
    }

    public func close() {
        state = .closed
        webViewInstance?.stopLoading()
        webViewInstance?.navigationDelegate = nil
        webViewInstance?.uiDelegate = nil
        webViewInstance = nil
        cancellables.removeAll()
    }
}
