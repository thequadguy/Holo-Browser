import WebKit
import Combine
import Foundation

/// Navigation state machine and WKNavigationDelegate handler for Holo Browser.
@MainActor
public final class NavigationManager: NSObject, ObservableObject {
    
    // Published state properties observed by BrowserViewModel
    @Published public private(set) var currentURL: URL?
    @Published public private(set) var pageTitle: String = ""
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var estimatedProgress: Double = 0.0
    @Published public private(set) var canGoBack: Bool = false
    @Published public private(set) var canGoForward: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    
    /// Reference to the active HoloWebView
    public weak var webView: WKWebView? {
        didSet {
            setupKVOObservers()
        }
    }

    /// Weak back-reference to the owning Tab; used to route crash recovery to ReliabilityManager.
    public weak var owningTab: Tab?
    
    private var kvoSubscriptions = Set<AnyCancellable>()
    
    public override init() {
        super.init()
    }
    
    /// Attaches KVO publishers to observe internal WKWebView state cleanly.
    private func setupKVOObservers() {
        kvoSubscriptions.removeAll()
        
        guard let webView = webView else { return }
        
        webView.publisher(for: \.estimatedProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.estimatedProgress = progress
            }
            .store(in: &kvoSubscriptions)
        
        webView.publisher(for: \.isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &kvoSubscriptions)
        
        webView.publisher(for: \.canGoBack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] back in
                self?.canGoBack = back
            }
            .store(in: &kvoSubscriptions)
        
        webView.publisher(for: \.canGoForward)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] forward in
                self?.canGoForward = forward
            }
            .store(in: &kvoSubscriptions)
        
        webView.publisher(for: \.title)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                self?.pageTitle = title ?? ""
            }
            .store(in: &kvoSubscriptions)
        
        webView.publisher(for: \.url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                if let url = url {
                    self?.currentURL = url
                }
            }
            .store(in: &kvoSubscriptions)
    }
    
    // MARK: - Navigation Actions
    
    /// Loads a specified URL in the managed web view.
    public func load(url: URL) {
        self.errorMessage = nil
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    /// Navigates back in history stack.
    public func goBack() {
        if webView?.canGoBack == true {
            self.errorMessage = nil
            webView?.goBack()
        }
    }
    
    /// Navigates forward in history stack.
    public func goForward() {
        if webView?.canGoForward == true {
            self.errorMessage = nil
            webView?.goForward()
        }
    }
    
    /// Reloads current webpage payload.
    public func reload() {
        self.errorMessage = nil
        webView?.reload()
    }
    
    /// Stops active navigation stream.
    public func stopLoading() {
        webView?.stopLoading()
    }
    
    /// Clears any visible error state banner.
    public func clearError() {
        self.errorMessage = nil
    }
    
    deinit {
        kvoSubscriptions.removeAll()
    }
}

// MARK: - WKNavigationDelegate
extension NavigationManager: WKNavigationDelegate {
    
    nonisolated public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Task { @MainActor in
            self.errorMessage = nil
            self.isLoading = true
        }
    }
    
    nonisolated public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Task { @MainActor in
            if let url = webView.url {
                self.currentURL = url
            }
        }
    }
    
    nonisolated public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.isLoading = false
            self.estimatedProgress = 1.0
            if let title = webView.title {
                self.pageTitle = title
            }
        }
    }
    
    nonisolated public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.handleNavigationError(error)
        }
    }
    
    nonisolated public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.handleNavigationError(error)
        }
    }
    
    @MainActor
    private func handleNavigationError(_ error: Error) {
        let nsError = error as NSError
        // Ignore user-cancelled navigations (e.g. clicking a link before previous finished)
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        self.errorMessage = error.localizedDescription
    }

    // MARK: - P0-Fix-3: WebContent Process Crash Recovery

    /// Called by WebKit when the WebContent process crashes or is terminated by the OS.
    /// Reloads the webview immediately and routes the event to ReliabilityManager for tracking.
    nonisolated public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Task { @MainActor in
            guard let tab = self.owningTab else {
                webView.reload()
                return
            }
            
            tab.crashCount += 1
            tab.reliabilityManager?.handleWebContentProcessTermination(tab: tab)
            
            if tab.crashCount == 1 {
                // 1st crash: immediate recovery reload
                webView.reload()
            } else if tab.crashCount == 2 {
                // 2nd crash: reload after 1-second delay
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                webView.reload()
            } else {
                // 3rd crash or higher: stop recovery loop to prevent crash loop and present UI warning
                self.errorMessage = "WebContent process crashed repeatedly (3x). Auto-recovery paused. Click reload to try again."
            }
        }
    }

}
