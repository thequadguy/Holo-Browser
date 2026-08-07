import Foundation
import Combine

/// Authoritative Composition Root for Holo Browser.
/// Instantiates, wires, and holds single shared instances of core services and overlay coordinators.
@MainActor
public final class BrowserEnvironment: ObservableObject {
    public let tabManager: TabManager
    public let profileManager: ProfileManager
    public let passwordManager: PasswordManager
    public let extensionManager: ExtensionManager
    public let sessionManager: SessionManager
    public let readingListManager: ReadingListManager
    public let bookmarkManager: BookmarkManager
    public let downloadManager: DownloadManager
    public let privacyManager: AIPrivacyManager
    public let aiManager: AIManager
    public let permissionManager: PermissionManager
    public let reliabilityManager: ReliabilityManager
    public let bookmarkStore: BookmarkStore
    public let historyStore: HistoryStore
    
    public let overlayCoordinator: OverlayCoordinator
    public let eventBus: HoloEventBus
    public let performanceMonitor: PerformanceMonitor
    @Published public var mindEngine: HoloMindEngine
    
    public init() {
        let profileManager = ProfileManager()
        let tabManager = TabManager()
        let passwordManager = PasswordManager()
        let extensionManager = ExtensionManager()
        let sessionManager = SessionManager()
        let readingListManager = ReadingListManager()
        let bookmarkManager = BookmarkManager()
        let downloadManager = DownloadManager()
        let privacyManager = AIPrivacyManager()
        let aiManager = AIManager(privacyManager: privacyManager)
        let permissionManager = PermissionManager()
        let reliabilityManager = ReliabilityManager()
        let bookmarkStore = BookmarkStore()
        let historyStore = HistoryStore()
        
        let overlayCoordinator = OverlayCoordinator()
        let eventBus = HoloEventBus.shared
        let performanceMonitor = PerformanceMonitor()
        let mindEngine = HoloMindEngine()
        
        self.profileManager = profileManager
        self.tabManager = tabManager
        self.passwordManager = passwordManager
        self.extensionManager = extensionManager
        self.sessionManager = sessionManager
        self.readingListManager = readingListManager
        self.bookmarkManager = bookmarkManager
        self.downloadManager = downloadManager
        self.privacyManager = privacyManager
        self.aiManager = aiManager
        self.permissionManager = permissionManager
        self.reliabilityManager = reliabilityManager
        self.bookmarkStore = bookmarkStore
        self.historyStore = historyStore
        
        self.overlayCoordinator = overlayCoordinator
        self.eventBus = eventBus
        self.performanceMonitor = performanceMonitor
        self.mindEngine = mindEngine
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
            bookmarkManager: bookmarkManager,
            downloadManager: downloadManager
        )
    }
}
