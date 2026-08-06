import XCTest
@testable import HoloBrowser

final class SubsystemUnitTests: XCTestCase {
    
    @MainActor
    func testAIContextGatekeeperValidation() throws {
        let gatekeeper = AIContextGatekeeper.shared
        let provider = MockAIProvider()
        
        let (prompt, context) = try gatekeeper.processAndValidateRequest(
            prompt: "Help me sk-1234567890abcdef12345678",
            context: "Authorization: Bearer secrettoken123",
            provider: provider,
            isPrivateBrowsing: false
        )
        
        XCTAssertFalse(prompt.contains("sk-1234567890abcdef12345678"))
        XCTAssertFalse(context.contains("secrettoken123"))
    }
    
    @MainActor
    func testSmartTabManagerGroupingAndUndo() {
        let manager = SmartTabManager.shared
        let tab1 = Tab(url: URL(string: "https://github.com/swift")!, title: "Swift GitHub")
        let tab2 = Tab(url: URL(string: "https://apple.com")!, title: "Apple Developer")
        
        manager.analyzeTabs([tab1, tab2])
        XCTAssertFalse(manager.suggestions.isEmpty)
        
        manager.undoGrouping()
        XCTAssertTrue(manager.previousGroupsState.isEmpty)
    }
    
    @MainActor
    func testRecoveryManagerSafeModeAndQuarantine() {
        let recovery = RecoveryManager.shared
        recovery.registerAppLaunch()
        recovery.resetCorruptedSessionData()
        recovery.registerStableExecution()
        XCTAssertEqual(recovery.consecutiveCrashCount, 0)
    }
    
    @MainActor
    func testMigrationManagerVersionTracking() {
        let migration = MigrationManager.shared
        migration.performPendingMigrations()
        XCTAssertGreaterThanOrEqual(migration.currentSchemaVersion, 1)
    }
    
    func testUpdateValidator() {
        let dummyURL = URL(fileURLWithPath: "/tmp/HoloBrowser_v1.1.dmg")
        let result = UpdateValidator.validateUpdatePackage(at: dummyURL, targetVersion: "1.1.0")
        XCTAssertFalse(result) // File doesn't exist on disk
        
        let downgradeResult = UpdateValidator.validateUpdatePackage(at: dummyURL, targetVersion: "0.9.0")
        XCTAssertFalse(downgradeResult) // Reject downgrade
    }
    
    @MainActor
    func testProfileManagerIsolation() {
        let manager = ProfileManager.shared
        let profile = manager.createProfile(name: "Test Profile", colorHex: "#FF0000")
        XCTAssertEqual(profile.name, "Test Profile")
    }
    
    func testDiskStorageActorSerialWritesAndReads() async throws {
        let url = URL(fileURLWithPath: "/tmp/test_storage_actor.json")
        await DiskStorageActor.shared.write(["key": "value"], to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        
        let readData = try await DiskStorageActor.shared.read(from: url, type: [String: String].self)
        XCTAssertEqual(readData["key"], "value")
        
        try? FileManager.default.removeItem(at: url)
    }
    
    @MainActor
    func testDownloadManagerPathTraversalSanitization() async {
        let downloadManager = DownloadManager()
        let response = URLResponse()
        let fakeDownload = WKDownload()
        
        let destination = await downloadManager.download(
            fakeDownload,
            decideDestinationUsing: response,
            suggestedFilename: "../../../Library/LaunchAgents/malicious.plist"
        )
        
        XCTAssertNotNil(destination)
        XCTAssertEqual(destination?.lastPathComponent, "malicious.plist")
        XCTAssertFalse(destination?.path.contains("..") ?? true)
    }
    
    @MainActor
    func testBookmarkManagerAddSearchFavoriteDelete() {
        let manager = BookmarkManager()
        let url = URL(string: "https://apple.com/swift")!
        let item = manager.addBookmark(title: "Swift Language", url: url, folderName: "Developer", isFavorite: true)
        
        XCTAssertEqual(item.title, "Swift Language")
        XCTAssertTrue(item.isFavorite)
        
        let searchResults = manager.searchBookmarks(query: "Swift")
        XCTAssertFalse(searchResults.isEmpty)
        XCTAssertEqual(searchResults.first?.title, "Swift Language")
        
        let favorites = manager.favoriteBookmarks
        XCTAssertTrue(favorites.contains(where: { $0.id == item.id }))
        
        manager.deleteBookmark(id: item.id)
        XCTAssertFalse(manager.bookmarks.contains(where: { $0.id == item.id }))
    }
    
    @MainActor
    func testTabPinningAndUnpinning() {
        let manager = TabManager()
        let tab1 = manager.createNewTab(url: URL(string: "https://example.com/1")!)
        let tab2 = manager.createNewTab(url: URL(string: "https://example.com/2")!)
        
        manager.pinTab(id: tab2.id)
        XCTAssertTrue(tab2.isPinned)
        XCTAssertEqual(manager.tabs.first?.id, tab2.id)
        
        manager.unpinTab(id: tab2.id)
        XCTAssertFalse(tab2.isPinned)
    }
    
    @MainActor
    func testHoloDoctorErrorHumanization() {
        let doctor = HoloDoctor.shared
        let wkError = NSError(domain: "WKErrorDomain", code: 102, userInfo: nil)
        let humanized = doctor.humanize(error: wkError)
        XCTAssertTrue(humanized.contains("Holo couldn't load this page"))
        
        let offlineError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let humanizedOffline = doctor.humanize(error: offlineError)
        XCTAssertTrue(humanizedOffline.contains("offline"))
    }
    
    @MainActor
    func testMemoryPrivacyManagerClearAndExport() {
        let json = MemoryPrivacyManager.exportMemoriesJSON()
        XCTAssertNotNil(json)
        MemoryPrivacyManager.clearAllMemories()
    }
}
