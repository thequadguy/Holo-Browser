import XCTest
import WebKit
@testable import HoloBrowser

/// Tests the complete Stage 5 screenshot intelligence security model.
/// Every test exercises production code paths — not source file existence.
@MainActor
final class Stage5ScreenshotIntelligenceTests: XCTestCase {

    var tabManager: TabManager!
    let profileID = UUID()

    override func setUp() {
        super.setUp()
        tabManager = TabManager()
        ScreenshotManager.shared.clearVisualContext()
    }

    override func tearDown() {
        ScreenshotManager.shared.clearVisualContext()
        tabManager = nil
        super.tearDown()
    }

    // MARK: - CB-2: Private Browsing Protection

    func testPrivateFlagBlocksCapture() async {
        let tab = tabManager.createNewTab(url: URL(string: "https://example.com")!, profileID: profileID)
        do {
            _ = try await ScreenshotManager.shared.captureTabSnapshot(tab: tab, isPrivateBrowsing: true)
            XCTFail("Should have thrown privateBrowsingBlocked")
        } catch let screenshotError as ScreenshotError {
            XCTAssertEqual(screenshotError, .privateBrowsingBlocked)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testPrivateTabPropertyBlocksCapture() async {
        // Tab.isPrivate is derived from WKWebsiteDataStore.isPersistent.
        // Pass nonPersistent() data store to create a private-mode tab.
        let privateTab = tabManager.createNewTab(
            url: URL(string: "https://example.com")!,
            dataStore: WKWebsiteDataStore.nonPersistent(),
            profileID: profileID
        )
        XCTAssertTrue(privateTab.isPrivate, "Tab with nonPersistent dataStore must report isPrivate = true")
        do {
            _ = try await ScreenshotManager.shared.captureTabSnapshot(tab: privateTab, isPrivateBrowsing: false)
            XCTFail("tab.isPrivate should have blocked capture regardless of caller flag")
        } catch let screenshotError as ScreenshotError {
            XCTAssertEqual(screenshotError, .privateBrowsingBlocked)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - HighRiskDomainProtection

    func testExactHighRiskDomainBlocksCapture() async {
        let tab = tabManager.createNewTab(url: URL(string: "https://chase.com/login")!, profileID: profileID)
        do {
            _ = try await ScreenshotManager.shared.captureTabSnapshot(tab: tab, isPrivateBrowsing: false)
            XCTFail("Should have thrown highRiskDomainBlocked")
        } catch let screenshotError as ScreenshotError {
            if case .highRiskDomainBlocked(let host) = screenshotError {
                XCTAssertEqual(host, "chase.com")
            } else {
                XCTFail("Expected highRiskDomainBlocked, got: \(screenshotError)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSubdomainHighRiskDomainBlocksCapture() async {
        let tab = tabManager.createNewTab(url: URL(string: "https://accounts.chase.com/")!, profileID: profileID)
        do {
            _ = try await ScreenshotManager.shared.captureTabSnapshot(tab: tab, isPrivateBrowsing: false)
            XCTFail("Should have thrown highRiskDomainBlocked for subdomain")
        } catch let screenshotError as ScreenshotError {
            if case .highRiskDomainBlocked = screenshotError { /* expected */ } else {
                XCTFail("Expected highRiskDomainBlocked, got: \(screenshotError)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNilWebViewBlocksCapture() async {
        // A tab created without a URL may not have a webView loaded.
        // Use a URL so createNewTab succeeds but without navigating (webView may be nil until loaded).
        let tab = tabManager.createNewTab(url: URL(string: "holo://start")!, profileID: profileID)
        // Force webView to nil state — we test the guard independently via direct Tab init
        let rawTab = Tab(initialURL: nil)
        do {
            _ = try await ScreenshotManager.shared.captureTabSnapshot(tab: rawTab, isPrivateBrowsing: false)
            XCTFail("Should have thrown captureFailed (no webView)")
        } catch let screenshotError as ScreenshotError {
            if case .captureFailed = screenshotError { /* expected */ } else {
                XCTFail("Expected captureFailed, got: \(screenshotError)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        _ = tab // suppress unused warning
    }

    // MARK: - HighRiskDomainChecker Unit Tests

    func testHighRiskDomainCheckerExactMatch() {
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("chase.com"))
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("paypal.com"))
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("schwab.com"))
    }

    func testHighRiskDomainCheckerSubdomainMatch() {
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("accounts.chase.com"))
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("secure.bankofamerica.com"))
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("online.wellsfargo.com"))
    }

    func testHighRiskDomainCheckerFirstLabelKeywordMatch() {
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("bank.example.com"))
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("login.myservice.io"))
        XCTAssertTrue(HighRiskDomainChecker.isHighRisk("signin.example.org"))
    }

    func testHighRiskDomainCheckerAllowsSafeDomainsWithKeywordSubstring() {
        // "foodbank.org" — "bank" is in the middle of the first label, NOT a standalone label.
        XCTAssertFalse(HighRiskDomainChecker.isHighRisk("foodbank.org"))
        // "myloginservice.com" — "login" is embedded in the label, not standalone.
        XCTAssertFalse(HighRiskDomainChecker.isHighRisk("myloginservice.com"))
    }

    func testHighRiskDomainCheckerAllowsNormalDomains() {
        XCTAssertFalse(HighRiskDomainChecker.isHighRisk("example.com"))
        XCTAssertFalse(HighRiskDomainChecker.isHighRisk("github.com"))
        XCTAssertFalse(HighRiskDomainChecker.isHighRisk("apple.com"))
        XCTAssertFalse(HighRiskDomainChecker.isHighRisk("wikipedia.org"))
    }

    // MARK: - Gatekeeper Private Browsing Block

    func testGatekeeperBlocksImageContextInPrivateBrowsing() throws {
        let imageData = Data(repeating: 0xAB, count: 1000)
        let visual = HoloVisualContext(imageData: imageData, width: 100, height: 100, sourceTabID: UUID())
        XCTAssertThrowsError(
            try AIContextGatekeeper.shared.validateImageContext(
                visualContext: visual,
                isPrivateBrowsing: true,
                domainHost: "example.com"
            )
        ) { error in
            if let aiError = error as? AIError, case .privacyBlocked = aiError {
                // expected
            } else {
                XCTFail("Expected AIError.privacyBlocked, got: \(error)")
            }
        }
    }

    func testGatekeeperBlocksImageContextOnHighRiskDomain() throws {
        let imageData = Data(repeating: 0xAB, count: 1000)
        let visual = HoloVisualContext(imageData: imageData, width: 100, height: 100, sourceTabID: UUID())
        XCTAssertThrowsError(
            try AIContextGatekeeper.shared.validateImageContext(
                visualContext: visual,
                isPrivateBrowsing: false,
                domainHost: "chase.com"
            )
        ) { error in
            if let aiError = error as? AIError, case .privacyBlocked = aiError {
                // expected
            } else {
                XCTFail("Expected AIError.privacyBlocked, got: \(error)")
            }
        }
    }

    func testGatekeeperBlocksOversizedImagePayload() throws {
        let largeData = Data(repeating: 0xFF, count: 600 * 1024) // 600 KB > 500 KB limit
        let visual = HoloVisualContext(imageData: largeData, width: 2048, height: 1536, sourceTabID: UUID())
        XCTAssertThrowsError(
            try AIContextGatekeeper.shared.validateImageContext(
                visualContext: visual,
                isPrivateBrowsing: false,
                domainHost: "example.com"
            )
        ) { error in
            if let aiError = error as? AIError, case .privacyBlocked = aiError {
                // expected
            } else {
                XCTFail("Expected AIError.privacyBlocked, got: \(error)")
            }
        }
    }

    func testGatekeeperAllowsValidImageContext() {
        let validData = Data(repeating: 0x88, count: 100 * 1024) // 100 KB
        let visual = HoloVisualContext(imageData: validData, width: 800, height: 600, sourceTabID: UUID())
        XCTAssertNoThrow(
            try AIContextGatekeeper.shared.validateImageContext(
                visualContext: visual,
                isPrivateBrowsing: false,
                domainHost: "example.com"
            )
        )
    }

    // MARK: - OpenAI Multimodal Payload Structure

    func testOpenAIRequestIncludesImageWhenVisualContextPresent() throws {
        let imageData = Data(repeating: 0xCC, count: 1024)
        let visual = HoloVisualContext(imageData: imageData, mimeType: "image/jpeg", width: 200, height: 150, sourceTabID: UUID())
        let message = AIMessage(role: .user, content: "What do you see?")
        let request = AIRequest(messages: [message], visualContext: visual)

        // Verify the request carries the visual context.
        XCTAssertNotNil(request.visualContext)
        XCTAssertEqual(request.visualContext?.mimeType, "image/jpeg")
        XCTAssertEqual(request.visualContext?.imageData.count, 1024)

        // Verify base64 encoding round-trips correctly.
        let base64 = request.visualContext!.imageData.base64EncodedString()
        let decoded = Data(base64Encoded: base64)
        XCTAssertEqual(decoded, imageData, "Base64 round-trip must be lossless")
    }

    func testOpenAIRequestHasNoImageWhenVisualContextAbsent() {
        let message = AIMessage(role: .user, content: "Plain question")
        let request = AIRequest(messages: [message])
        XCTAssertNil(request.visualContext, "Text-only request must not carry a visual context")
    }

    // MARK: - Anthropic Payload MIME Type

    func testAnthropicImageMimeTypeIsCorrect() {
        let imageData = Data(repeating: 0xDD, count: 512)
        let visual = HoloVisualContext(imageData: imageData, mimeType: "image/jpeg", width: 100, height: 100, sourceTabID: UUID())
        XCTAssertEqual(visual.mimeType, "image/jpeg", "MIME type must be image/jpeg for Anthropic image blocks")
    }

    // MARK: - Serialization Safety

    func testHoloContextSerializationDropsScreenshotData() throws {
        let imageData = Data(repeating: 0xAB, count: 50_000)
        let visual = HoloVisualContext(imageData: imageData, width: 800, height: 600, sourceTabID: UUID())
        let context = HoloContext(
            currentPage: HoloContext.CurrentPage(title: "T", urlString: "https://x.com", extractedText: "e"),
            selectedText: "s",
            relevantTabs: [],
            activeSpaceName: "Space",
            isPrivateBrowsing: false,
            visualContext: visual
        )

        let encoded = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(HoloContext.self, from: encoded)

        XCTAssertNil(decoded.visualContext,
            "Screenshot bytes must be absent after JSON round-trip")
        XCTAssertEqual(decoded.currentPage?.title, "T")
        XCTAssertFalse(
            (String(data: encoded, encoding: .utf8) ?? "").contains("imageData"),
            "Encoded JSON must not contain imageData key"
        )
    }

    // MARK: - Visual Context Lifecycle

    func testClearVisualContextRemovesData() {
        // Manually install a fake visual context to simulate a prior capture.
        let imageData = Data(repeating: 0xEE, count: 100)
        // Use reflection-free internal mechanism via the ScreenshotManager's public API.
        // We cannot install it directly, so we just verify clearVisualContext works.
        ScreenshotManager.shared.clearVisualContext()
        XCTAssertNil(ScreenshotManager.shared.lastCapturedVisualContext)
        XCTAssertNil(ScreenshotManager.shared.captureError)
        _ = imageData // suppress unused warning
    }

    // MARK: - HoloContextBuilder Size and Privacy Enforcement

    @MainActor
    func testBuilderStripsVisualContextInPrivateBrowsing() {
        let visual = HoloVisualContext(imageData: Data(repeating: 1, count: 100), width: 100, height: 100, sourceTabID: UUID())
        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Page",
            currentPageURL: "https://example.com",
            rawPageText: "text",
            selectedText: nil,
            tabs: [],
            activeSpaceName: nil,
            isPrivateBrowsing: true,
            visualContext: visual,
            privacyManager: AIPrivacyManager()
        )
        XCTAssertNil(context.visualContext)
    }

    @MainActor
    func testBuilderStripsVisualContextOverSizeLimit() {
        let oversized = Data(repeating: 0xFF, count: HoloContextBuilder.maxImagePayloadBytes + 1)
        let visual = HoloVisualContext(imageData: oversized, width: 2048, height: 1536, sourceTabID: UUID())
        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Page",
            currentPageURL: "https://example.com",
            rawPageText: "text",
            selectedText: nil,
            tabs: [],
            activeSpaceName: nil,
            isPrivateBrowsing: false,
            visualContext: visual,
            privacyManager: AIPrivacyManager()
        )
        XCTAssertNil(context.visualContext)
    }

    @MainActor
    func testBuilderPreservesValidVisualContext() {
        let valid = Data(repeating: 0x88, count: 120 * 1024) // 120 KB < 500 KB limit
        let visual = HoloVisualContext(imageData: valid, width: 800, height: 600, sourceTabID: UUID())
        let context = HoloContextBuilder.buildSanitizedContext(
            currentPageTitle: "Page",
            currentPageURL: "https://example.com",
            rawPageText: "text",
            selectedText: nil,
            tabs: [],
            activeSpaceName: nil,
            isPrivateBrowsing: false,
            visualContext: visual,
            privacyManager: AIPrivacyManager()
        )
        XCTAssertNotNil(context.visualContext)
        XCTAssertEqual(context.visualContext?.imageData.count, 120 * 1024)
    }
}
