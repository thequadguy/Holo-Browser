import XCTest
@testable import HoloBrowser

@MainActor
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

    // MARK: - Text truncation and tab limits

    @MainActor
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
        XCTAssertLessThanOrEqual(context.currentPage!.extractedText.count, HoloContextBuilder.maxPageTextLength)
        XCTAssertLessThanOrEqual(context.selectedText!.count, HoloContextBuilder.maxSelectedTextLength)
        XCTAssertEqual(context.relevantTabs.count, 2)
        XCTAssertEqual(context.activeSpaceName, "Research Space")
    }

    // MARK: - Private browsing URL redaction

    @MainActor
    func testPrivateBrowsingRedaction() {
        let tab = HoloContext.RelevantTab(
            id: UUID(),
            title: "Private Tab",
            urlString: "https://secret-bank.com/user?token=12345"
        )

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

    // MARK: - AI request builder from HoloContext

    @MainActor
    func testAIRequestBuilderFromHoloContext() {
        let page = HoloContext.CurrentPage(
            title: "SwiftUI Documentation",
            urlString: "https://developer.apple.com",
            extractedText: "Declarative UI framework for macOS."
        )
        let tab = HoloContext.RelevantTab(id: UUID(), title: "WebKit Guide", urlString: "https://webkit.org")
        let context = HoloContext(
            currentPage: page,
            selectedText: "Declarative UI",
            relevantTabs: [tab],
            activeSpaceName: "Development",
            isPrivateBrowsing: false
        )

        let request = AIContextBuilder.buildRequest(
            userQuery: "How does SwiftUI work?",
            holoContext: context,
            privacyManager: privacyManager
        )

        XCTAssertNotNil(request.pageContextText)
        XCTAssertTrue(request.pageContextText!.contains("Active Holo Space: Development"))
        XCTAssertTrue(request.pageContextText!.contains("SwiftUI Documentation"))
        XCTAssertTrue(request.pageContextText!.contains("Declarative UI"))
        XCTAssertTrue(request.pageContextText!.contains("WebKit Guide"))
    }

    // MARK: - Serialization safety: screenshot data must NEVER be persisted

    func testHoloContextSerializationExcludesScreenshotData() throws {
        let imageData = Data(repeating: 0xAB, count: 50_000)
        let visual = HoloVisualContext(imageData: imageData, width: 800, height: 600, sourceTabID: UUID())
        let original = HoloContext(
            currentPage: HoloContext.CurrentPage(title: "Test", urlString: "https://example.com", extractedText: "content"),
            selectedText: "selected",
            relevantTabs: [],
            activeSpaceName: "Test Space",
            isPrivateBrowsing: false,
            visualContext: visual
        )

        // Encode
        let encoded = try JSONEncoder().encode(original)

        // Decoded context must NOT contain screenshot data.
        let decoded = try JSONDecoder().decode(HoloContext.self, from: encoded)
        XCTAssertNil(decoded.visualContext, "visualContext MUST be nil after decode — screenshot data must never persist")

        // Verify text fields survived the round-trip.
        XCTAssertEqual(decoded.currentPage?.title, "Test")
        XCTAssertEqual(decoded.selectedText, "selected")
        XCTAssertEqual(decoded.activeSpaceName, "Test Space")
        XCTAssertFalse(decoded.isPrivateBrowsing)

        // Confirm the JSON payload itself contains no base64/binary image data.
        let jsonString = String(data: encoded, encoding: .utf8) ?? ""
        XCTAssertFalse(jsonString.contains("imageData"), "JSON must not contain imageData key")
        XCTAssertFalse(jsonString.contains("mimeType"), "JSON must not contain mimeType key")
    }

    // MARK: - Visual context suppressed in private browsing at builder level

    @MainActor
    func testVisualContextSuppressedWhenPrivate() {
        let imageData = Data(repeating: 0xFF, count: 10_000)
        let visual = HoloVisualContext(imageData: imageData, width: 400, height: 300, sourceTabID: UUID())

        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Private Page",
            currentPageURL: "https://example.com",
            rawPageText: "content",
            selectedText: nil,
            tabs: [],
            activeSpaceName: nil,
            isPrivateBrowsing: true,
            visualContext: visual,
            privacyManager: privacyManager
        )

        XCTAssertNil(context.visualContext,
            "Builder must strip visual context when isPrivateBrowsing is true")
    }

    // MARK: - Visual context suppressed when over size limit at builder level

    @MainActor
    func testVisualContextSuppressedWhenOverSizeLimit() {
        let largeData = Data(repeating: 0xFF, count: HoloContextBuilder.maxImagePayloadBytes + 1)
        let visual = HoloVisualContext(imageData: largeData, width: 2048, height: 1536, sourceTabID: UUID())

        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Large Image Page",
            currentPageURL: "https://example.com",
            rawPageText: "content",
            selectedText: nil,
            tabs: [],
            activeSpaceName: nil,
            isPrivateBrowsing: false,
            visualContext: visual,
            privacyManager: privacyManager
        )

        XCTAssertNil(context.visualContext,
            "Builder must strip visual context when imageData exceeds the \(HoloContextBuilder.maxImagePayloadBytes / 1024) KB limit")
    }
}
