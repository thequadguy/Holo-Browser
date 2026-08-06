import Foundation
import Combine

/// Lightweight Composition Root for Holo Browser.
/// Instantiates, wires, and holds single shared instances of core services, injecting them cleanly into BrowserViewModel.
@MainActor
public final class BrowserEnvironment: ObservableObject {
    public let tabManager: TabManager
    public let profileManager: ProfileManager
    public let passwordManager: PasswordManager
    public let extensionManager: ExtensionManager
    public let sessionManager: SessionManager
    public let readingListManager: ReadingListManager
    public let bookmarkManager: BookmarkManager
    public let privacyManager: AIPrivacyManager
    public let aiManager: AIManager
    public let permissionManager: PermissionManager
    public let reliabilityManager: ReliabilityManager
    public let bookmarkStore: BookmarkStore
    public let historyStore: HistoryStore
    
    public init() {
        let profileManager = ProfileManager()
        let tabManager = TabManager()
        let passwordManager = PasswordManager()
        let extensionManager = ExtensionManager()
        let sessionManager = SessionManager()
        let readingListManager = ReadingListManager()
        let bookmarkManager = BookmarkManager()
        let privacyManager = AIPrivacyManager()
        let aiManager = AIManager(privacyManager: privacyManager)
        let permissionManager = PermissionManager()
        let reliabilityManager = ReliabilityManager()
        let bookmarkStore = BookmarkStore()
        let historyStore = HistoryStore()
        
        self.profileManager = profileManager
        self.tabManager = tabManager
        self.passwordManager = passwordManager
        self.extensionManager = extensionManager
        self.sessionManager = sessionManager
        self.readingListManager = readingListManager
        self.bookmarkManager = bookmarkManager
        self.privacyManager = privacyManager
        self.aiManager = aiManager
        self.permissionManager = permissionManager
        self.reliabilityManager = reliabilityManager
        self.bookmarkStore = bookmarkStore
        self.historyStore = historyStore
    }
    
    /// Creates a fully configured BrowserViewModel with environment dependencies injected.
    public func makeBrowserViewModel() -> BrowserViewModel {
        return BrowserViewModel(
            tabManager: tabManager,
            profileManager: profileManager,
            passwordManager: passwordManager,
            extensionManager: extensionManager,
            sessionManager: sessionManager,
            readingListManager: readingListManager,
            bookmarkManager: bookmarkManager
        )
    }
}
