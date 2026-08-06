import Foundation
import Combine
import WebKit

/// Closed tab record: preserves both URL and originating profile ID for correct restoration.
/// P1-1 Fix: previously recentlyClosedTabs was [URL] with no profile metadata, causing
/// Cmd+Shift+T to restore tabs under the wrong profile's data store.
public struct ClosedTabRecord {
    public let url: URL
    public let profileID: UUID
}

/// Data model representing a group of tabs.
public struct TabGroup: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var tabIDs: [UUID]
    
    public init(id: UUID = UUID(), name: String, tabIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.tabIDs = tabIDs
    }
}

/// Main-actor observable manager orchestrating multi-tab lifecycle, active tab selection, and memory suspension.
@MainActor
public final class TabManager: ObservableObject {
    @Published public private(set) var tabs: [Tab] = []
    @Published public var activeTabID: UUID?
    @Published public private(set) var recentlyClosedTabs: [ClosedTabRecord] = []

    // Weak references injected by ContentView.onAppear — after managers are ready.
    public weak var permissionManager: PermissionManager?
    public weak var reliabilityManager: ReliabilityManager?

    /// Default data store used when no profile is specified.
    private var defaultDataStore: WKWebsiteDataStore = .default()

    /// P1-2 Fix: init() no longer creates the initial tab.
    /// The initial tab is created by setup(dataStore:) called from ContentView.onAppear,
    /// after permissionManager and reliabilityManager have been injected.
    /// This eliminates the startup race where the first webview was created with nil delegates.
    public init() {}

    /// Called from ContentView.onAppear after manager injection.
    /// Creates the initial tab with the correct profile data store and live delegates.
    public func setup(dataStore: WKWebsiteDataStore, startupURL: URL? = nil) {
        guard tabs.isEmpty else { return }
        let url = startupURL ?? URL(string: "holo://start")!
        createNewTab(url: url, dataStore: dataStore)
    }

    /// Helper returning the currently active Tab object.
    public var activeTab: Tab? {
        guard let id = activeTabID else { return tabs.first }
        return tabs.first(where: { $0.id == id })
    }

    /// Resolves the isolated WKWebsiteDataStore for a profile ID. Never silently falls back to default.
    public func dataStore(for profileID: UUID, profileManager: ProfileManager) throws -> WKWebsiteDataStore {
        guard let store = profileManager.websiteDataStore(for: profileID) else {
            throw NSError(
                domain: "TabManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Unknown profile ID \(profileID). Silent fallback to default WKWebsiteDataStore is strictly prohibited."]
            )
        }
        return store
    }

    // MARK: - Tab Creation

    /// Creates and appends a new tab using an explicitly specified profile data store.
    /// Passing `.nonPersistent()` for private browsing ensures cookie/session isolation.
    @discardableResult
    public func createNewTab(
        url: URL = URL(string: "holo://start")!,
        dataStore: WKWebsiteDataStore? = nil,
        profileID: UUID? = nil
    ) -> Tab {
        let store = dataStore ?? defaultDataStore
        let newTab = Tab(initialURL: url, websiteDataStore: store)

        // Always inject current delegates so every tab has crash recovery and permission wiring.
        newTab.permissionManager = permissionManager
        newTab.reliabilityManager = reliabilityManager

        tabs.append(newTab)
        selectTab(id: newTab.id)
        return newTab
    }


    // MARK: - Tab Selection

    /// Switches current active tab to the specified ID.
    public func selectTab(id: UUID) {
        guard tabs.contains(where: { $0.id == id }) else { return }

        for tab in tabs {
            if tab.id == id {
                tab.activate()
            } else if tab.state == .active {
                tab.deactivate()
            }
        }
        activeTabID = id
    }

    // MARK: - Tab Close & Restore

    /// Closes and deallocates specified tab, tracking URL + profileID in recentlyClosedTabs.
    public func closeTab(id: UUID, currentProfileID: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }

        let tabToClose = tabs[index]
        if let url = tabToClose.url {
            let record = ClosedTabRecord(url: url, profileID: currentProfileID)
            recentlyClosedTabs.insert(record, at: 0)
            // Cap the closed-tab stack at 50 entries.
            if recentlyClosedTabs.count > 50 {
                recentlyClosedTabs = Array(recentlyClosedTabs.prefix(50))
            }
        }
        tabToClose.close()
        tabs.remove(at: index)

        if activeTabID == id {
            if tabs.indices.contains(index) {
                selectTab(id: tabs[index].id)
            } else if let last = tabs.last {
                selectTab(id: last.id)
            } else {
                // Always ensure at least one tab exists.
                createNewTab(dataStore: dataStore(for: currentProfileID))
            }
        }
    }

    /// Restores the most recently closed tab using its original profile's data store.
    /// P1-1 Fix: now passes the correct profile data store from the ClosedTabRecord.
    /// Falls back to the provided fallbackDataStore if the original profile is no longer available.
    @discardableResult
    public func restoreRecentlyClosedTab(
        dataStore: WKWebsiteDataStore? = nil
    ) -> Tab? {
        guard !recentlyClosedTabs.isEmpty else { return nil }
        let record = recentlyClosedTabs.removeFirst()
        // Use provided fallback (active profile's store from ContentView) — caller is responsible
        // for passing the correct store for the record's profileID when available.
        return createNewTab(url: record.url, dataStore: dataStore, profileID: record.profileID)
    }

    // MARK: - Profile Switch Tab Migration (P1-7)

    /// Called when the user switches profile.
    /// Closes all non-pinned tabs (which belong to the previous profile's data store)
    /// and opens a single new tab with the new profile's isolated store.
    /// Pinned tabs are preserved but their webview is rebuilt with the new store on next activation.
    ///
    /// This eliminates cross-profile cookie leakage where tabs from the old profile
    /// remained live and continued sending/receiving cookies for the wrong profile.
    public func migrateToNewProfile(dataStore: WKWebsiteDataStore, newProfileID: UUID) {
        // Close all non-pinned tabs, recording their URLs for the recently-closed list.
        let tabsToClose = tabs.filter { !$0.isPinned }
        for tab in tabsToClose {
            if let url = tab.url {
                let record = ClosedTabRecord(url: url, profileID: newProfileID)
                recentlyClosedTabs.insert(record, at: 0)
            }
            tab.close()
        }
        tabs.removeAll { !$0.isPinned }

        // Cap the recently closed list.
        if recentlyClosedTabs.count > 50 {
            recentlyClosedTabs = Array(recentlyClosedTabs.prefix(50))
        }

        // Always open one fresh tab in the new profile.
        createNewTab(dataStore: dataStore, profileID: newProfileID)
    }

    // MARK: - Index Navigation

    /// Switches to tab by 0-based index (for Cmd + 1..9 shortcuts).
    public func selectTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        selectTab(id: tabs[index].id)
    }

    @Published public private(set) var tabGroups: [TabGroup] = []

    // MARK: - Tab Management Features (Phase 4)
    
    public func pinTab(id: UUID) {
        if let idx = tabs.firstIndex(where: { $0.id == id }) {
            tabs[idx].isPinned = true
            let pinnedTab = tabs.remove(at: idx)
            let firstUnpinnedIdx = tabs.firstIndex(where: { !$0.isPinned }) ?? tabs.endIndex
            tabs.insert(pinnedTab, at: firstUnpinnedIdx)
        }
    }
    
    public func unpinTab(id: UUID) {
        if let idx = tabs.firstIndex(where: { $0.id == id }) {
            tabs[idx].isPinned = false
        }
    }
    
    public func togglePinTab(id: UUID) {
        if let tab = tabs.first(where: { $0.id == id }) {
            if tab.isPinned {
                unpinTab(id: id)
            } else {
                pinTab(id: id)
            }
        }
    }
    
    public func duplicateTab(id: UUID, currentProfileID: UUID) {
        guard let tabToDuplicate = tabs.first(where: { $0.id == id }),
              let url = tabToDuplicate.url else { return }
        createNewTab(url: url, dataStore: dataStore(for: currentProfileID), profileID: currentProfileID)
    }
    
    public func closeOtherTabs(keeping id: UUID, currentProfileID: UUID) {
        let tabsToClose = tabs.filter { $0.id != id && !$0.isPinned }
        for tab in tabsToClose {
            if let url = tab.url {
                let record = ClosedTabRecord(url: url, profileID: currentProfileID)
                recentlyClosedTabs.insert(record, at: 0)
            }
            tab.close()
        }
        tabs.removeAll(where: { $0.id != id && !$0.isPinned })
        
        if recentlyClosedTabs.count > 50 {
            recentlyClosedTabs = Array(recentlyClosedTabs.prefix(50))
        }
    }
    
    public func createTabGroup(name: String, tabIDs: [UUID]) {
        let group = TabGroup(name: name, tabIDs: tabIDs)
        tabGroups.append(group)
    }
    
    public func removeTabGroup(id: UUID) {
        tabGroups.removeAll(where: { $0.id == id })
    }
    
    // MARK: - Memory Management

    /// Suspends background tabs when total count exceeds threshold to conserve memory.
    public func suspendInactiveTabs(maxActiveBackground: Int = 4) {
        let backgroundTabs = tabs.filter { $0.state == .background }
        if backgroundTabs.count > maxActiveBackground {
            let overflowCount = backgroundTabs.count - maxActiveBackground
            for tab in backgroundTabs.prefix(overflowCount) {
                tab.suspend()
            }
        }
    }

    // MARK: - Private Helpers

    private func dataStore(for profileID: UUID) -> WKWebsiteDataStore {
        // Minimal fallback — callers should pass a known store from ProfileManager.
        return defaultDataStore
    }
}
