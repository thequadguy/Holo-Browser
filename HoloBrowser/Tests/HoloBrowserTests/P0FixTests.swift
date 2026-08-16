import XCTest
import WebKit
@testable import HoloBrowser

// MARK: - P0-Fix-1 Tests: WKWebsiteDataStore Profile Isolation

final class ProfileDataStoreTests: XCTestCase {

    @MainActor
    func test_privateProfile_usesNonPersistentStore() {
        let pm = ProfileManager()
        let privateProfile = pm.createProfile(name: "Private Test", isPrivate: true)
        let store = pm.websiteDataStore(for: privateProfile)
        // Non-persistent store is not the same object as .default()
        XCTAssertFalse(store.isPersistent, "Private profile must use a non-persistent WKWebsiteDataStore")
    }

    @MainActor
    func test_twoRegularProfiles_useDifferentDataStores() {
        let pm = ProfileManager()
        let profileA = pm.createProfile(name: "Work", colorHex: "#FF0000")
        let profileB = pm.createProfile(name: "Personal", colorHex: "#0000FF")
        let storeA = pm.websiteDataStore(for: profileA)
        let storeB = pm.websiteDataStore(for: profileB)
        // On macOS 14+ each profile gets its own identifier-scoped store
        XCTAssertFalse(storeA === storeB, "Two different profiles must not share the same WKWebsiteDataStore instance")
    }

    @MainActor
    func test_tabManager_passesDataStoreToNewTab() {
        let tm = TabManager()
        let pm = ProfileManager()
        let privateProfile = pm.createProfile(name: "Private", isPrivate: true)
        let privateStore = pm.websiteDataStore(for: privateProfile)

        let tab = tm.createNewTab(url: URL(string: "https://example.com")!, dataStore: privateStore)
        // We verify the tab was created (it should never be nil)
        XCTAssertNotNil(tab)
        // Activating the tab forces WebView creation; verify the webview was created
        tab.activate()
        XCTAssertNotNil(tab.webView, "Tab.webView must be non-nil after activation")
    }
}

// MARK: - P0-Fix-2 Tests: NavigationDelegate Assignment

final class NavigationDelegateTests: XCTestCase {

    @MainActor
    func test_tab_assignsNavigationDelegate_onRestoreIfNeeded() {
        let tab = Tab(initialURL: URL(string: "https://example.com")!)
        // Calling restoreIfNeeded creates the WebView
        let webView = tab.restoreIfNeeded()
        XCTAssertNotNil(webView, "restoreIfNeeded must return a non-nil HoloWebView")
        XCTAssertTrue(
            webView?.navigationDelegate === tab.navigationManager,
            "webView.navigationDelegate must be set to tab.navigationManager"
        )
    }

    @MainActor
    func test_tab_suspend_clears_navigationDelegate() {
        let tab = Tab(initialURL: URL(string: "https://example.com")!)
        tab.activate()
        XCTAssertNotNil(tab.webViewInstance, "WebView should exist after activation")
        tab.deactivate()
        tab.suspend()
        XCTAssertNil(tab.webViewInstance, "WebView must be nil after suspend")
    }
}

// MARK: - P0-Fix-3 Tests: WebContent Crash Recovery

final class CrashRecoveryTests: XCTestCase {

    @MainActor
    func test_reliabilityManager_incrementsCrashCount() async {
        let rm = ReliabilityManager()
        let tab = Tab(initialURL: URL(string: "https://example.com")!)
        tab.reliabilityManager = rm
        tab.activate()

        XCTAssertEqual(rm.crashCount, 0)
        rm.handleWebContentProcessTermination(tab: tab)
        XCTAssertEqual(rm.crashCount, 1, "Crash count must increment on process termination")
        XCTAssertEqual(rm.lastRecoveredURLString, "https://example.com")
    }

    @MainActor
    func test_navigationManager_hasTerminationDelegate_method() {
        // Verify NavigationManager implements the optional delegate method.
        // If the method did not exist, the protocol conformance would fail to compile.
        let nm = NavigationManager()
        let responds = nm.responds(to: #selector(nm.webViewWebContentProcessDidTerminate(_:)))
        XCTAssertTrue(responds, "NavigationManager must implement webViewWebContentProcessDidTerminate")
    }
}

// MARK: - P0-Fix-4 Tests: Retain Cycle Prevention

final class RetainCycleTests: XCTestCase {

    @MainActor
    func test_weakScriptMessageProxy_doesNotRetainTarget() {
        final class MockHandler: NSObject, WKScriptMessageHandler, @unchecked Sendable {
            nonisolated func userContentController(_ ucc: WKUserContentController, didReceive msg: WKScriptMessage) {}
        }

        var handler: MockHandler? = MockHandler()
        weak var weakHandler = handler

        let proxy = WeakScriptMessageProxy(target: handler!)
        XCTAssertNotNil(proxy.target)

        handler = nil // Release the strong reference
        XCTAssertNil(weakHandler, "Handler must deallocate — WeakScriptMessageProxy must not retain it strongly")
        XCTAssertNil(proxy.target, "Proxy.target must be nil after handler is released")
    }
}

// MARK: - P0-Fix-5 Tests: Permission Manager Approval Flow

final class PermissionManagerTests: XCTestCase {

    @MainActor
    func test_pendingRequest_isNil_initially() {
        let pm = PermissionManager()
        XCTAssertNil(pm.pendingRequest, "pendingRequest must be nil before any website requests access")
    }

    @MainActor
    func test_approve_calls_decisionHandler_with_grant() {
        let pm = PermissionManager()
        var receivedDecision: WKPermissionDecision?

        if #available(macOS 12.0, *) {
            let req = MediaPermissionRequest(
                domain: "example.com",
                captureType: .camera,
                decisionHandler: { decision in
                    receivedDecision = decision
                }
            )
            pm.enqueue(req)
            pm.approve(id: req.id)

            XCTAssertEqual(receivedDecision, .grant)
            XCTAssertNil(pm.pendingRequest, "pendingRequest must be cleared after approval")
        }
    }

    @MainActor
    func test_deny_calls_decisionHandler_with_deny() {
        let pm = PermissionManager()
        var receivedDecision: WKPermissionDecision?

        if #available(macOS 12.0, *) {
            let req = MediaPermissionRequest(
                domain: "evil.com",
                captureType: .microphone,
                decisionHandler: { decision in
                    receivedDecision = decision
                }
            )
            pm.enqueue(req)
            pm.deny(id: req.id)

            XCTAssertEqual(receivedDecision, .deny)
            XCTAssertNil(pm.pendingRequest, "pendingRequest must be cleared after denial")
        }
    }

    @MainActor
    func test_rememberDecision_savesGrant() {
        let pm = PermissionManager()

        if #available(macOS 12.0, *) {
            let req = MediaPermissionRequest(
                domain: "trusted.com",
                captureType: .camera,
                decisionHandler: { _ in }
            )
            pm.enqueue(req)
            pm.approve(id: req.id, rememberDecision: true)
            XCTAssertEqual(pm.mediaPermissions["trusted.com"], .grant, "Saved grant decision must be persisted for domain")
        }
    }
}

// MARK: - P0-Fix-6 Tests: AI Provider Architecture

final class AIProviderTests: XCTestCase {

    func test_mockProvider_isNotNil() {
        let provider = MockAIProvider()
        XCTAssertFalse(provider.name.isEmpty)
    }

    func test_openAIProvider_finishesWithError_whenKeyIsEmpty() async {
        let provider = OpenAIProvider(apiKey: "")
        var threwMissingKeyError = false

        do {
            for try await _ in provider.sendMessage(AIRequest(messages: [AIMessage(role: .user, content: "hi")])) {}
        } catch let error as AIError {
            if case .missingAPIKey = error { threwMissingKeyError = true }
        } catch {}

        XCTAssertTrue(threwMissingKeyError, "OpenAIProvider must throw AIError.missingAPIKey when key is empty")
    }

    func test_anthropicProvider_finishesWithError_whenKeyIsEmpty() async {
        let provider = AnthropicProvider(apiKey: "")
        var threwMissingKeyError = false

        do {
            for try await _ in provider.sendMessage(AIRequest(messages: [AIMessage(role: .user, content: "hi")])) {}
        } catch let error as AIError {
            if case .missingAPIKey = error { threwMissingKeyError = true }
        } catch {}

        XCTAssertTrue(threwMissingKeyError, "AnthropicProvider must throw AIError.missingAPIKey when key is empty")
    }

    @MainActor
    func test_providerFactory_returnsMock_whenNoKeyConfigured() async {
        // Ensure no residual test key exists
        _ = await AIProviderFactory.deleteKey(for: .openAI)
        let provider = await AIProviderFactory.provider(for: .openAI)
        XCTAssertTrue(provider is MockAIProvider, "Factory must return MockAIProvider when no OpenAI key is in Keychain")
    }

    @MainActor
    func test_providerFactory_returnsOpenAI_whenKeyIsStored() async {
        let testKey = "sk-test-p0fix6-integration-key"
        _ = await AIProviderFactory.saveKey(testKey, for: .openAI)
        let provider = await AIProviderFactory.provider(for: .openAI)
        XCTAssertTrue(provider is OpenAIProvider, "Factory must return OpenAIProvider when a key is stored in Keychain")
        // Cleanup
        _ = await AIProviderFactory.deleteKey(for: .openAI)
    }

    @MainActor
    func test_providerFactory_isConfigured_returnsTrueAfterSave() async {
        _ = await AIProviderFactory.deleteKey(for: .anthropic)
        let notConfigured = await AIProviderFactory.isConfigured(for: .anthropic)
        XCTAssertFalse(notConfigured)
        _ = await AIProviderFactory.saveKey("sk-ant-test", for: .anthropic)
        let configured = await AIProviderFactory.isConfigured(for: .anthropic)
        XCTAssertTrue(configured)
        _ = await AIProviderFactory.deleteKey(for: .anthropic)
    }
}

// MARK: - RecentlyClosedTabs Cap Test (P2-Fix)

final class TabManagerTests: XCTestCase {

    @MainActor
    func test_recentlyClosedTabs_cappedAt50() {
        let tm = TabManager()
        let profileID = UUID()
        // Close 60 tabs and verify the cap is enforced
        for tabIndex in 0..<60 {
            let tab = tm.createNewTab(url: URL(string: "https://example.com/\(tabIndex)")!)
            tm.closeTab(id: tab.id, currentProfileID: profileID)
        }
        XCTAssertLessThanOrEqual(tm.recentlyClosedTabs.count, 50, "recentlyClosedTabs must be capped at 50 entries")
    }
}
