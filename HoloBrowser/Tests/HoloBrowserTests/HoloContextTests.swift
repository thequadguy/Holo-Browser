https://apple.com
// @ai summarize current page
// http://localhost:8085/sample.pdf
// http://localhost:8085/sample.png
// http://localhost:8085/sample.txt
// import XCTest
@testable import HoloBrowser

final class HoloContextTests: XCTestCase {
    var privacyManager: AIPrivacyManager!

    override func setUp() {
        super.setUp()
        privacyManager = AIPrivacyManager()
    }

    override func tearDown() {
        privacyManager = nil
        super.tearDown()
    }

    func testHoloContextCreationAndTruncation() {
        let longText = String(repeating: "HoloBrowser test content. ", count: 300)
        let longSelection = String(repeating: "Selected text token. ", count: 100)

        let tab1 = HoloContext.RelevantTab(id: UUID(), title: "Tab 1", urlString: "https://apple.com", snippet: "Apple site")
        let tab2 = HoloContext.RelevantTab(id: UUID(), title: "Tab 2", urlString: "https://github.com", snippet: "GitHub code")

        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Test Page",
            currentPageURL: "https://example.com",
            rawPageText: longText,
            headings: ["H1 Header", "H2 Subheader"],
            selectedText: longSelection,
            tabs: [tab1, tab2],
            activeSpaceName: "Research Space",
            isPrivateBrowsing: false,
            privacyManager: privacyManager
        )

        XCTAssertNotNil(context.currentPage)
        XCTAssertEqual(context.currentPage?.title, "Test Page")
        XCTAssertTrue(context.currentPage!.extractedText.count <= HoloContextBuilder.maxPageTextLength)
        XCTAssertTrue(context.selectedText!.count <= HoloContextBuilder.maxSelectedTextLength)
        XCTAssertEqual(context.relevantTabs.count, 2)
        XCTAssertEqual(context.activeSpaceName, "Research Space")
    }

    func testPrivateBrowsingRedaction() {
        let tab = HoloContext.RelevantTab(id: UUID(), title: "Private Tab", urlString: "https://secret-bank.com/user?token=12345")

        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Private Account",
            currentPageURL: "https://secret-bank.com/user?token=12345",
            rawPageText: "Account details text",
            selectedText: nil,
            tabs: [tab],
            activeSpaceName: nil,
            isPrivateBrowsing: true,
            privacyManager: privacyManager
        )

        XCTAssertEqual(context.currentPage?.urlString, "[URL Redacted — Private Browsing]")
        XCTAssertNil(context.currentPage?.domainHost)
        XCTAssertEqual(context.relevantTabs.first?.urlString, "[URL Redacted]")
    }

    func testAIRequestBuilderFromHoloContext() {
        let page = HoloContext.CurrentPage(title: "SwiftUI Documentation", urlString: "https://developer.apple.com", extractedText: "Declarative UI framework for macOS.")
        let tab = HoloContext.RelevantTab(id: UUID(), title: "WebKit Guide", urlString: "https://webkit.org")

        let context = HoloContext(currentPage: page, selectedText: "Declarative UI", relevantTabs: [tab], activeSpaceName: "Development", isPrivateBrowsing: false)

        let request = AIContextBuilder.buildRequest(userQuery: "How does SwiftUI work?", holoContext: context, privacyManager: privacyManager)

        XCTAssertNotNil(request.pageContextText)
        XCTAssertTrue(request.pageContextText!.contains("Active Holo Space: Development"))
        XCTAssertTrue(request.pageContextText!.contains("SwiftUI Documentation"))
        XCTAssertTrue(request.pageContextText!.contains("Declarative UI"))
        XCTAssertTrue(request.pageContextText!.contains("WebKit Guide"))
    }
}
