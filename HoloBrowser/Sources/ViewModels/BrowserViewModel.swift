import SwiftUI
import Combine
import WebKit

/// Presentation view model for Holo Browser main window, bound to TabManager, ProfileManager, PasswordManager, ExtensionManager, SessionManager, and ReadingListManager.
@MainActor
public final class BrowserViewModel: NSObject, ObservableObject, WKScriptMessageHandler {
    
    @Published public var inputURLString: String = ""
    @Published public private(set) var currentURL: URL?
    @Published public private(set) var pageTitle: String = "Holo Browser"
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var canGoBack: Bool = false
    @Published public private(set) var canGoForward: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    
    public let tabManager: TabManager
    public let profileManager: ProfileManager
    public let passwordManager: PasswordManager
    public let extensionManager: ExtensionManager
    public let sessionManager: SessionManager
    public let readingListManager: ReadingListManager
    public let bookmarkManager: BookmarkManager
    public let downloadManager: DownloadManager
    
    private var activeTabCancellables = Set<AnyCancellable>()
    private var managerCancellables = Set<AnyCancellable>()
    
    public init(
        tabManager: TabManager,
        profileManager: ProfileManager,
        passwordManager: PasswordManager,
        extensionManager: ExtensionManager,
        sessionManager: SessionManager,
        readingListManager: ReadingListManager,
        bookmarkManager: BookmarkManager,
        downloadManager: DownloadManager? = nil
    ) {
        self.tabManager = tabManager
        self.profileManager = profileManager
        self.passwordManager = passwordManager
        self.extensionManager = extensionManager
        self.sessionManager = sessionManager
        self.readingListManager = readingListManager
        self.bookmarkManager = bookmarkManager
        self.downloadManager = downloadManager ?? DownloadManager()
        super.init()
        setupManagerBindings()
    }
    
    public convenience override init() {
        self.init(
            tabManager: TabManager(),
            profileManager: ProfileManager(),
            passwordManager: PasswordManager(),
            extensionManager: ExtensionManager(),
            sessionManager: SessionManager(),
            readingListManager: ReadingListManager(),
            bookmarkManager: BookmarkManager(),
            downloadManager: DownloadManager()
        )
    }
    
    // MARK: - Session Auto-Save & Recovery
    
    public func restorePreviousSession() {
        guard let session = sessionManager.loadPreviousSession() else { return }
        let currentProfileID = profileManager.activeProfile.id
        tabManager.tabs.forEach { tabManager.closeTab(id: $0.id, currentProfileID: currentProfileID) }
        
        // Restore saved profile if found, preserving profile isolation and privacy state
        if let matchedProfile = profileManager.profiles.first(where: { $0.id == session.profileID }) {
            profileManager.selectProfile(id: matchedProfile.id)
        }

        
        let store = profileManager.activeWebsiteDataStore
        for (idx, savedItem) in session.tabs.enumerated() {
            if let url = URL(string: savedItem.urlString) {
                let tab = tabManager.createNewTab(url: url, dataStore: store, profileID: session.profileID)
                tab.isPinned = savedItem.isPinned
                if idx == session.activeTabIndex {
                    tabManager.selectTab(id: tab.id)
                }
            }
        }
        sessionManager.showRecoveryPrompt = false
    }

    
    public func autoSaveSession() {
        sessionManager.saveActiveSession(
            tabs: tabManager.tabs,
            activeTabIndex: tabManager.tabs.firstIndex(where: { $0.id == tabManager.activeTabID }) ?? 0,
            profileID: profileManager.activeProfile.id,
            isPrivate: profileManager.activeProfile.isPrivate
        )
    }
    
    // MARK: - WKScriptMessageHandler Login Form Detection

    nonisolated public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Task { @MainActor in
            guard message.name == "holoPasswordDetector", let dict = message.body as? [String: String] else { return }
            let domain = dict["domain"] ?? ""
            let username = dict["username"] ?? ""
            let password = dict["password"] ?? ""

            guard !domain.isEmpty, !password.isEmpty else { return }

            // P1-5 / Private-browsing guard: never prompt to save credentials in a private profile.
            // Private browsing credentials should never be persisted to Keychain or credentials.json.
            guard !profileManager.activeProfile.isPrivate else { return }

            // P1-5: use SecureCredentialPrompt so the password is zeroed after consumption.
            self.passwordManager.promptSaveCredential = SecureCredentialPrompt(
                domain: domain,
                username: username,
                password: password
            )
        }
    }

    
    private func setupManagerBindings() {
        tabManager.$activeTabID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupActiveTabBindings()
                self?.autoSaveSession()
            }
            .store(in: &managerCancellables)
        
        tabManager.$tabs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tabManager.suspendInactiveTabs(maxActiveBackground: 4)
                self?.autoSaveSession()
            }
            .store(in: &managerCancellables)
        
        extensionManager.$extensions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncUserScriptsToActiveTab()
            }
            .store(in: &managerCancellables)
        
        setupActiveTabBindings()
    }
    
    private func syncUserScriptsToActiveTab() {
        guard let activeTab = tabManager.activeTab, let webView = activeTab.webView else { return }
        let scripts = extensionManager.activeUserScripts()
        webView.configuration.userContentController.removeAllUserScripts()
        // P0-2 Fix: Always preserve system login form detection script
        webView.configuration.userContentController.addUserScript(HoloWebView.loginDetectionScript)
        for script in scripts {
            webView.configuration.userContentController.addUserScript(script)
        }
    }


    
    private func setupActiveTabBindings() {
        activeTabCancellables.removeAll()
        
        guard let activeTab = tabManager.activeTab else { return }
        
        // P0-Fix-4: remove and re-add via weak proxy to break WKUserContentController retain cycle.
        activeTab.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "holoPasswordDetector")
        let proxy = WeakScriptMessageProxy(target: self)
        activeTab.webView?.configuration.userContentController.add(proxy, name: "holoPasswordDetector")
        
        syncUserScriptsToActiveTab()
        
        activeTab.$url
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.currentURL = url
                if self?.isLoading == false, let urlString = url?.absoluteString {
                    self?.inputURLString = urlString
                }
            }
            .store(in: &activeTabCancellables)
        
        activeTab.$title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                self?.pageTitle = title.isEmpty ? "Holo Browser" : title
            }
            .store(in: &activeTabCancellables)
        
        activeTab.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &activeTabCancellables)
        
        activeTab.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] p in
                self?.progress = p
            }
            .store(in: &activeTabCancellables)
        
        activeTab.$canGoBack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] back in
                self?.canGoBack = back
            }
            .store(in: &activeTabCancellables)
        
        activeTab.$canGoForward
            .receive(on: DispatchQueue.main)
            .sink { [weak self] forward in
                self?.canGoForward = forward
            }
            .store(in: &activeTabCancellables)
        
        activeTab.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.errorMessage = msg
            }
            .store(in: &activeTabCancellables)
    }
    
    // MARK: - Navigation Actions
    
    public func submitAddressInput() {
        guard let activeTab = tabManager.activeTab else { return }
        
        let route = HoloSmartSearchRouter.route(for: inputURLString)
        
        switch route {
        case .web(let url):
            inputURLString = url.absoluteString
            activeTab.navigationManager.load(url: url)
        case .ai(let query):
            NotificationCenter.default.post(name: NSNotification.Name("HoloSmartSearchAI"), object: query)
        case .mission(let query):
            NotificationCenter.default.post(name: NSNotification.Name("HoloSmartSearchMission"), object: query)
        }
    }
    
    public func goBack() {
        tabManager.activeTab?.navigationManager.goBack()
    }
    
    public func goForward() {
        tabManager.activeTab?.navigationManager.goForward()
    }
    
    public func reloadOrStop() {
        guard let activeTab = tabManager.activeTab else { return }
        if activeTab.isLoading {
            activeTab.navigationManager.stopLoading()
        } else {
            activeTab.navigationManager.reload()
        }
    }
    
    public func dismissError() {
        tabManager.activeTab?.navigationManager.clearError()
    }
    
    public func toggleWebInspector() {
        guard let webView = tabManager.activeTab?.webView else { return }
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
    }
    
    public func createNewTab() {
        // P0-Fix-1: always pass the active profile's isolated data store.
        let store = profileManager.activeWebsiteDataStore
        tabManager.createNewTab(dataStore: store)
    }
    
    public func closeActiveTab() {
        if let activeID = tabManager.activeTabID {
            tabManager.closeTab(id: activeID, currentProfileID: profileManager.activeProfile.id)
        }
    }

    public func selectTab(at index: Int) {
        tabManager.selectTab(at: index)
    }
}

