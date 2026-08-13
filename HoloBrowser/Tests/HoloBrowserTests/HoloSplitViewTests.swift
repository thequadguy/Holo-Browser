import XCTest
@testable import HoloBrowser

@MainActor
final class HoloSplitViewTests: XCTestCase {
    var tabManager: TabManager!
    let profileID = UUID()

    override func setUp() {
        super.setUp()
        tabManager = TabManager()
    }

    override func tearDown() {
        tabManager = nil
        super.tearDown()
    }

    func testEnteringAndExitingSplitMode() {
        let tab1 = tabManager.createNewTab(url: URL(string: "https://apple.com")!, profileID: profileID)
        let tab2 = tabManager.createNewTab(url: URL(string: "https://github.com")!, profileID: profileID)

        XCTAssertFalse(tabManager.splitState.isActive)

        tabManager.enterSplitView(primaryID: tab1.id, secondaryID: tab2.id)

        XCTAssertTrue(tabManager.splitState.isActive)
        XCTAssertEqual(tabManager.splitState.primaryTabID, tab1.id)
        XCTAssertEqual(tabManager.splitState.secondaryTabID, tab2.id)
        XCTAssertEqual(tabManager.activeTabID, tab1.id)

        tabManager.exitSplitView()

        XCTAssertFalse(tabManager.splitState.isActive)
        // Verify both tabs remain open after exiting split view
        XCTAssertEqual(tabManager.tabs.count, 2)
    }

    func testSplitPaneSelectionAndReplacement() {
        let tab1 = tabManager.createNewTab(url: URL(string: "https://apple.com")!, profileID: profileID)
        let tab2 = tabManager.createNewTab(url: URL(string: "https://github.com")!, profileID: profileID)
        let tab3 = tabManager.createNewTab(url: URL(string: "https://google.com")!, profileID: profileID)

        tabManager.enterSplitView(primaryID: tab1.id, secondaryID: tab2.id)

        tabManager.setSplitActivePane(.secondary)
        XCTAssertEqual(tabManager.splitState.activePane, .secondary)
        XCTAssertEqual(tabManager.activeTabID, tab2.id)

        tabManager.replaceSplitTab(pane: .secondary, newTabID: tab3.id)
        XCTAssertEqual(tabManager.splitState.secondaryTabID, tab3.id)
        XCTAssertEqual(tabManager.secondaryTab?.id, tab3.id)
        XCTAssertEqual(tabManager.tabs.count, 3) // Old tab2 remains open
    }

    func testMultiTabComparisonContextFromSplitView() {
        let page1 = HoloContext.CurrentPage(title: "Apple M3", urlString: "https://apple.com", extractedText: "Apple M3 specs")
        let page2 = HoloContext.CurrentPage(title: "Intel i9", urlString: "https://intel.com", extractedText: "Intel i9 specs")

        let relTab = HoloContext.RelevantTab(id: UUID(), title: page2.title, urlString: page2.urlString, snippet: page2.extractedText)

        let context = HoloContext(
            currentPage: page1,
            selectedText: nil,
            relevantTabs: [relTab],
            activeSpaceName: "Hardware Research",
            isPrivateBrowsing: false
        )

        let privacyManager = AIPrivacyManager()
        let request = AIContextBuilder.buildRequest(userQuery: "Compare Apple M3 vs Intel i9", holoContext: context, privacyManager: privacyManager)

        XCTAssertNotNil(request.pageContextText)
        XCTAssertTrue(request.pageContextText!.contains("Apple M3"))
        XCTAssertTrue(request.pageContextText!.contains("Intel i9"))
    }
}
