import XCTest
import WebKit
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
        let tab1 = Tab(initialURL: URL(string: "https://github.com/swift")!)
        let tab2 = Tab(initialURL: URL(string: "https://apple.com")!)

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

    func testUpdateValidator() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dummyDMG = tempDir.appendingPathComponent("HoloBrowser_Update_Test.dmg")
        let dummyEXE = tempDir.appendingPathComponent("HoloBrowser_Update_Test.exe")
        let sampleData = Data("HoloBrowser-Production-Update-Payload-2026".utf8)

        try sampleData.write(to: dummyDMG)
        try sampleData.write(to: dummyEXE)
        defer {
            try? FileManager.default.removeItem(at: dummyDMG)
            try? FileManager.default.removeItem(at: dummyEXE)
        }

        // 1. Valid package format
        XCTAssertNoThrow(try UpdateValidator.validatePackageFormat(at: dummyDMG))
        XCTAssertThrowsError(try UpdateValidator.validatePackageFormat(at: dummyEXE)) { error in
            XCTAssertEqual(error as? UpdateValidator.ValidationError, .unsupportedFormat("exe"))
        }

        // 2. SHA-256 Checksum Verification
        let actualSHA = try UpdateValidator.computeSHA256(for: dummyDMG)
        XCTAssertFalse(actualSHA.isEmpty)
        XCTAssertNoThrow(try UpdateValidator.validateChecksum(for: dummyDMG, expectedSHA256: actualSHA))
        XCTAssertThrowsError(try UpdateValidator.validateChecksum(for: dummyDMG, expectedSHA256: "deadbeef00000000")) { error in
            if case .checksumMismatch(let expected, let actual) = error as? UpdateValidator.ValidationError {
                XCTAssertEqual(expected, "deadbeef00000000")
                XCTAssertEqual(actual, actualSHA)
            } else {
                XCTFail("Expected checksumMismatch error")
            }
        }

        // 3. Semantic Version Comparison & Progression
        XCTAssertEqual(try UpdateValidator.compareVersions("1.0.0", "1.1.0"), .orderedAscending)
        XCTAssertEqual(try UpdateValidator.compareVersions("1.2.0", "1.2.0"), .orderedSame)
        XCTAssertEqual(try UpdateValidator.compareVersions("2.0.0", "1.9.9"), .orderedDescending)
        XCTAssertEqual(try UpdateValidator.compareVersions("v1.2.3-beta.1", "1.2.3"), .orderedSame)

        XCTAssertNoThrow(try UpdateValidator.validateVersionProgression(currentVersion: "1.0.0", targetVersion: "1.1.0"))
        XCTAssertThrowsError(try UpdateValidator.validateVersionProgression(currentVersion: "2.0.0", targetVersion: "1.9.0")) { error in
            XCTAssertEqual(error as? UpdateValidator.ValidationError, .downgradeAttempt(current: "2.0.0", target: "1.9.0"))
        }

        // 4. Combined Pipeline Validation
        XCTAssertTrue(UpdateValidator.validateUpdatePackage(
            at: dummyDMG,
            targetVersion: "1.1.0",
            currentVersion: "1.0.0",
            expectedSHA256: actualSHA
        ))

        // Rejection: Invalid version string
        XCTAssertFalse(UpdateValidator.validateUpdatePackage(
            at: dummyDMG,
            targetVersion: "invalid_ver"
        ))

        // Rejection: Downgrade attempt
        XCTAssertFalse(UpdateValidator.validateUpdatePackage(
            at: dummyDMG,
            targetVersion: "0.9.0",
            currentVersion: "1.0.0"
        ))

        // Rejection: Non-existent file
        let missingURL = tempDir.appendingPathComponent("non_existent_file.dmg")
        XCTAssertFalse(UpdateValidator.validateUpdatePackage(
            at: missingURL,
            targetVersion: "2.0.0"
        ))
    }

    @MainActor
    func testProfileManagerIsolation() {
        // ProfileManager has no singleton — create a fresh instance per test.
        let manager = ProfileManager()
        let profile = manager.createProfile(name: "Test Profile", colorHex: "#FF0000")
        XCTAssertEqual(profile.name, "Test Profile")
    }

    func testDiskStorageActorSerialWritesAndReads() async throws {
        let url = URL(fileURLWithPath: "/tmp/test_storage_actor.json")
        try await DiskStorageActor.shared.write(["key": "value"], to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let readData = try await DiskStorageActor.shared.read(from: url, type: [String: String].self)
        XCTAssertEqual(readData["key"], "value")

        try? FileManager.default.removeItem(at: url)
    }

    @MainActor
    func testDownloadManagerPathTraversalSanitization() async throws {
        let downloadsFolder = FileManager.default.temporaryDirectory.appendingPathComponent("TestDownloads")
        try? FileManager.default.createDirectory(at: downloadsFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: downloadsFolder) }

        // 1. Defend against ../../ relative directory traversal
        let dirty1 = "../../etc/passwd"
        let clean1 = DownloadPathSanitizer.sanitizeDestination(suggestedFilename: dirty1, directory: downloadsFolder)
        XCTAssertTrue(clean1.path.hasPrefix(downloadsFolder.path), "Must be contained in downloads folder")
        XCTAssertEqual(clean1.lastPathComponent, "passwd")

        // 2. Defend against ../../../tmp/file
        let dirty2 = "../../../tmp/malicious.sh"
        let clean2 = DownloadPathSanitizer.sanitizeDestination(suggestedFilename: dirty2, directory: downloadsFolder)
        XCTAssertTrue(clean2.path.hasPrefix(downloadsFolder.path))
        XCTAssertEqual(clean2.lastPathComponent, "malicious.sh")

        // 3. Defend against absolute paths
        let dirty3 = "/private/etc/shadow"
        let clean3 = DownloadPathSanitizer.sanitizeDestination(suggestedFilename: dirty3, directory: downloadsFolder)
        XCTAssertTrue(clean3.path.hasPrefix(downloadsFolder.path))
        XCTAssertEqual(clean3.lastPathComponent, "shadow")

        // 4. Defend against Windows backslashes
        let dirty4 = "..\\..\\windows\\system32\\cmd.exe"
        let clean4 = DownloadPathSanitizer.sanitizeDestination(suggestedFilename: dirty4, directory: downloadsFolder)
        XCTAssertTrue(clean4.path.hasPrefix(downloadsFolder.path))
        XCTAssertEqual(clean4.lastPathComponent, "cmd.exe")

        // 5. Defend against empty string and dotfiles
        let emptyClean = DownloadPathSanitizer.sanitizeDestination(suggestedFilename: "", directory: downloadsFolder)
        XCTAssertTrue(emptyClean.path.hasPrefix(downloadsFolder.path))
        XCTAssertEqual(emptyClean.lastPathComponent, "download")

        let dotClean = DownloadPathSanitizer.sanitizeDestination(suggestedFilename: ".", directory: downloadsFolder)
        XCTAssertTrue(dotClean.path.hasPrefix(downloadsFolder.path))
        XCTAssertEqual(dotClean.lastPathComponent, "download")

        // 6. Collision numbering
        let existingFile = downloadsFolder.appendingPathComponent("archive.zip")
        try Data("test".utf8).write(to: existingFile)
        let collisionClean = DownloadPathSanitizer.sanitizeDestination(suggestedFilename: "archive.zip", directory: downloadsFolder)
        XCTAssertEqual(collisionClean.lastPathComponent, "archive (1).zip")
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
        _ = manager.createNewTab(url: URL(string: "https://example.com/1")!)
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

    @MainActor
    func testContentBlockingManagerRuleApplication() {
        let blocker = ContentBlockingManager.shared
        XCTAssertTrue(blocker.isEnabled)

        let config = WKWebViewConfiguration()
        blocker.applyRules(to: config)

        // Toggle state verification
        blocker.setEnabled(false)
        XCTAssertFalse(blocker.isEnabled)
        blocker.setEnabled(true)
        XCTAssertTrue(blocker.isEnabled)
    }
}
