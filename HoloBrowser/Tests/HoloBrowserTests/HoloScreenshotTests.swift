import XCTest
import WebKit
@testable import HoloBrowser

@MainActor
final class HoloScreenshotTests: XCTestCase {
    var manager: ScreenshotManager!
    var tabManager: TabManager!
    let profileID = UUID()

    override func setUp() {
        super.setUp()
        manager = ScreenshotManager.shared
        tabManager = TabManager()
    }

    override func tearDown() {
        manager.clearVisualContext()
        manager = nil
        tabManager = nil
        super.tearDown()
    }

    func testPrivateBrowsingBlocksScreenshotCapture() async {
        let tab = tabManager.createNewTab(url: URL(string: "https://example.com")!, profileID: profileID)

        do {
            _ = try await manager.captureTabSnapshot(tab: tab, isPrivateBrowsing: true)
            XCTFail("Should have thrown private browsing error")
        } catch let error as ScreenshotError {
            XCTAssertEqual(error, ScreenshotError.privateBrowsingBlocked)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testHighRiskSensitiveDomainBlocksScreenshotCapture() async {
        let tab = tabManager.createNewTab(url: URL(string: "https://chase.com/login")!, profileID: profileID)

        do {
            _ = try await manager.captureTabSnapshot(tab: tab, isPrivateBrowsing: false)
            XCTFail("Should have thrown high risk domain error")
        } catch let error as ScreenshotError {
            if case .highRiskDomainBlocked(let domain) = error {
                XCTAssertEqual(domain, "chase.com")
            } else {
                XCTFail("Expected highRiskDomainBlocked error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testVisualContextByteSizeLimitInHoloContext() {
        let largeData = Data(repeating: 0xFF, count: 600 * 1024) // 600 KB exceeding 500 KB limit
        let visual = HoloVisualContext(imageData: largeData, width: 1024, height: 768, sourceTabID: UUID())

        let privacyManager = AIPrivacyManager()
        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Test Page",
            currentPageURL: "https://example.com",
            rawPageText: "Content text",
            headings: [],
            selectedText: nil,
            tabs: [],
            activeSpaceName: nil,
            isPrivateBrowsing: false,
            visualContext: visual,
            privacyManager: privacyManager
        )

        // Must drop oversized visual context to prevent memory bloating
        XCTAssertNil(context.visualContext)
    }

    func testValidVisualContextPreservedInHoloContext() {
        let validData = Data(repeating: 0x88, count: 120 * 1024) // 120 KB JPEG
        let visual = HoloVisualContext(imageData: validData, width: 800, height: 600, sourceTabID: UUID())

        let privacyManager = AIPrivacyManager()
        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Valid Page",
            currentPageURL: "https://example.com",
            rawPageText: "Content text",
            headings: [],
            selectedText: nil,
            tabs: [],
            activeSpaceName: nil,
            isPrivateBrowsing: false,
            visualContext: visual,
            privacyManager: privacyManager
        )

        XCTAssertNotNil(context.visualContext)
        XCTAssertEqual(context.visualContext?.imageData.count, 120 * 1024)
        XCTAssertEqual(context.visualContext?.width, 800)
    }

    func testSplitViewTabSourceID() {
        let tabPrimary = tabManager.createNewTab(url: URL(string: "https://apple.com")!, profileID: profileID)
        let tabSecondary = tabManager.createNewTab(url: URL(string: "https://github.com")!, profileID: profileID)

        tabManager.enterSplitView(primaryID: tabPrimary.id, secondaryID: tabSecondary.id)

        // When primary pane active
        tabManager.setSplitActivePane(.primary)
        XCTAssertEqual(tabManager.activeTabID, tabPrimary.id)

        // When secondary pane active
        tabManager.setSplitActivePane(.secondary)
        XCTAssertEqual(tabManager.activeTabID, tabSecondary.id)
    }
}
