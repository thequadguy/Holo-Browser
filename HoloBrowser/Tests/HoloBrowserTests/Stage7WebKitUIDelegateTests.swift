import XCTest
import WebKit
@testable import HoloBrowser

@MainActor
final class Stage7WebKitUIDelegateTests: XCTestCase {

    // MARK: - Popup & New-Tab Routing Tests

    func testPopupRoutingCreatesNewTab() {
        let tabManager = TabManager()
        let initialTabCount = tabManager.tabs.count

        let popupURL = URL(string: "https://example.com/popup-window")!
        let newTab = PopupRouter.handlePopupRequest(
            url: popupURL,
            dataStore: .default(),
            tabManager: tabManager
        )

        XCTAssertNotNil(newTab, "Popup router must return a newly created Tab")
        XCTAssertEqual(tabManager.tabs.count, initialTabCount + 1, "TabManager tab count must increment by 1")
        XCTAssertEqual(newTab?.url, popupURL, "New tab must preserve the requested popup URL")
        XCTAssertEqual(tabManager.activeTabID, newTab?.id, "New tab must be selected as active")
    }

    func testPopupRoutingPreservesPrivateBrowsingDataStore() {
        let tabManager = TabManager()
        let privateStore = WKWebsiteDataStore.nonPersistent()

        let privateURL = URL(string: "https://private.example.org/dashboard")!
        let newTab = PopupRouter.handlePopupRequest(
            url: privateURL,
            dataStore: privateStore,
            tabManager: tabManager
        )

        XCTAssertNotNil(newTab)
        XCTAssertTrue(newTab?.isPrivate == true, "Popup tab created from private browsing context must inherit non-persistent data store")
    }

    func testPopupRoutingWithNilURLDefaultsToAboutBlank() {
        let tabManager = TabManager()
        let initialCount = tabManager.tabs.count

        let newTab = PopupRouter.handlePopupRequest(
            url: nil,
            dataStore: .default(),
            tabManager: tabManager
        )

        XCTAssertNotNil(newTab)
        XCTAssertEqual(tabManager.tabs.count, initialCount + 1)
        XCTAssertEqual(newTab?.url?.absoluteString, "about:blank")
    }

    // MARK: - JavaScript Alert Tests

    func testJavaScriptAlertLifecycle() {
        var callCount = 0
        let req = JavaScriptDialogRequest(
            originDomain: "holo.direct",
            type: .alert(message: "System update available"),
            alertCompletion: {
                callCount += 1
            }
        )

        XCTAssertEqual(callCount, 0)
        req.resolveAlert()
        XCTAssertEqual(callCount, 1, "Alert completion handler must be called when resolved")

        // Redundant resolution must be a safe no-op
        req.resolveAlert()
        XCTAssertEqual(callCount, 1, "Alert completion handler must NOT be invoked more than once")
    }

    // MARK: - JavaScript Confirm Tests

    func testJavaScriptConfirmAccept() {
        var receivedResult: Bool?
        var callCount = 0

        let req = JavaScriptDialogRequest(
            originDomain: "bank.example.com",
            type: .confirm(message: "Transfer funds?"),
            confirmCompletion: { result in
                receivedResult = result
                callCount += 1
            }
        )

        req.resolveConfirm(true)
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(receivedResult, true, "Confirm accept must return true to WebKit")

        req.resolveConfirm(false)
        XCTAssertEqual(callCount, 1, "Confirm handler must NOT be invoked twice")
    }

    func testJavaScriptConfirmCancel() {
        var receivedResult: Bool?
        var callCount = 0

        let req = JavaScriptDialogRequest(
            originDomain: "shopping.example.com",
            type: .confirm(message: "Clear cart?"),
            confirmCompletion: { result in
                receivedResult = result
                callCount += 1
            }
        )

        req.resolveConfirm(false)
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(receivedResult, false, "Confirm cancel must return false to WebKit")
    }

    // MARK: - JavaScript Prompt Tests

    func testJavaScriptPromptAccept() {
        var enteredText: String?
        var callCount = 0

        let req = JavaScriptDialogRequest(
            originDomain: "forum.example.com",
            type: .prompt(prompt: "Enter handle", defaultText: "guest"),
            promptCompletion: { text in
                enteredText = text
                callCount += 1
            }
        )

        req.resolvePrompt("saturn_v")
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(enteredText, "saturn_v", "Prompt accept must return user-supplied text")

        req.resolvePrompt("apollo")
        XCTAssertEqual(callCount, 1, "Prompt handler must NOT be invoked twice")
    }

    func testJavaScriptPromptCancel() {
        var enteredText: String? = "initial"
        var callCount = 0

        let req = JavaScriptDialogRequest(
            originDomain: "forum.example.com",
            type: .prompt(prompt: "Enter handle", defaultText: "guest"),
            promptCompletion: { text in
                enteredText = text
                callCount += 1
            }
        )

        req.resolvePrompt(nil)
        XCTAssertEqual(callCount, 1)
        XCTAssertNil(enteredText, "Prompt cancel must return nil to WebKit")
    }

    // MARK: - Queueing & Dismissal Safety Tests

    func testPermissionManagerDialogQueueing() {
        let pm = PermissionManager()
        pm.cancelAllDialogs()

        var alertFired = false
        var confirmResult: Bool?

        let dialog1 = JavaScriptDialogRequest(
            originDomain: "site1.org",
            type: .alert(message: "Message 1"),
            alertCompletion: { alertFired = true }
        )
        let dialog2 = JavaScriptDialogRequest(
            originDomain: "site2.org",
            type: .confirm(message: "Message 2"),
            confirmCompletion: { confirmResult = $0 }
        )

        pm.enqueueDialog(dialog1)
        pm.enqueueDialog(dialog2)

        XCTAssertEqual(pm.pendingDialog?.id, dialog1.id, "First enqueued dialog must be pending")

        pm.resolveAlert(id: dialog1.id)
        XCTAssertTrue(alertFired, "First dialog must have resolved")
        XCTAssertEqual(pm.pendingDialog?.id, dialog2.id, "Second dialog must automatically become pending")

        pm.resolveConfirm(id: dialog2.id, result: true)
        XCTAssertEqual(confirmResult, true)
        XCTAssertNil(pm.pendingDialog, "All dialogs resolved — pendingDialog must be nil")
    }

    func testCancelAllDialogsResolvesWithSafeDefaults() {
        let pm = PermissionManager()
        pm.cancelAllDialogs()

        var alertResolved = false
        var confirmResolvedResult: Bool?
        var promptResolvedText: String? = "preset"

        let dialog1 = JavaScriptDialogRequest(
            originDomain: "a.com",
            type: .alert(message: "Alert A"),
            alertCompletion: { alertResolved = true }
        )
        let dialog2 = JavaScriptDialogRequest(
            originDomain: "b.com",
            type: .confirm(message: "Confirm B"),
            confirmCompletion: { confirmResolvedResult = $0 }
        )
        let dialog3 = JavaScriptDialogRequest(
            originDomain: "c.com",
            type: .prompt(prompt: "Prompt C", defaultText: "def"),
            promptCompletion: { promptResolvedText = $0 }
        )

        pm.enqueueDialog(dialog1)
        pm.enqueueDialog(dialog2)
        pm.enqueueDialog(dialog3)

        pm.cancelAllDialogs()

        XCTAssertTrue(alertResolved, "Alert must be resolved during cancelAllDialogs")
        XCTAssertEqual(confirmResolvedResult, false, "Confirm must be resolved with false during cancelAllDialogs")
        XCTAssertNil(promptResolvedText, "Prompt must be resolved with nil during cancelAllDialogs")
        XCTAssertNil(pm.pendingDialog, "Pending dialog must be cleared")
    }
}
