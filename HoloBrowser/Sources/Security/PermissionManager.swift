import Foundation
import WebKit

/// Represents an ongoing media capture permission request awaiting user approval/denial.
public struct MediaPermissionRequest: Identifiable {
    public let id: UUID = UUID()
    public let domain: String
    public let captureType: WKMediaCaptureType
    public let decisionHandler: @MainActor @Sendable (WKPermissionDecision) -> Void

    public init(
        domain: String,
        captureType: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor @Sendable (WKPermissionDecision) -> Void
    ) {
        self.domain = domain
        self.captureType = captureType
        self.decisionHandler = decisionHandler
    }
}

public enum PermissionState: String, Codable {
    case prompt
    case grant
    case deny
}

/// Supported JavaScript dialog types: alert, confirm, and prompt.
public enum JavaScriptDialogType: Equatable {
    case alert(message: String)
    case confirm(message: String)
    case prompt(prompt: String, defaultText: String?)
}

/// Represents an ongoing JavaScript dialog request guaranteeing exactly-once completion.
public final class JavaScriptDialogRequest: Identifiable {
    public let id: UUID = UUID()
    public let originDomain: String
    public let type: JavaScriptDialogType

    private var alertCompletion: (@MainActor @Sendable () -> Void)?
    private var confirmCompletion: (@MainActor @Sendable (Bool) -> Void)?
    private var promptCompletion: (@MainActor @Sendable (String?) -> Void)?
    private var isResolved: Bool = false

    public init(
        originDomain: String,
        type: JavaScriptDialogType,
        alertCompletion: (@MainActor @Sendable () -> Void)? = nil,
        confirmCompletion: (@MainActor @Sendable (Bool) -> Void)? = nil,
        promptCompletion: (@MainActor @Sendable (String?) -> Void)? = nil
    ) {
        self.originDomain = originDomain
        self.type = type
        self.alertCompletion = alertCompletion
        self.confirmCompletion = confirmCompletion
        self.promptCompletion = promptCompletion
    }

    @MainActor
    public func resolveAlert() {
        guard !isResolved else { return }
        isResolved = true
        let handler = alertCompletion
        alertCompletion = nil
        handler?()
    }

    @MainActor
    public func resolveConfirm(_ result: Bool) {
        guard !isResolved else { return }
        isResolved = true
        let handler = confirmCompletion
        confirmCompletion = nil
        handler?(result)
    }

    @MainActor
    public func resolvePrompt(_ text: String?) {
        guard !isResolved else { return }
        isResolved = true
        let handler = promptCompletion
        promptCompletion = nil
        handler?(text)
    }

    @MainActor
    public func cancel() {
        guard !isResolved else { return }
        isResolved = true
        let a = alertCompletion
        let c = confirmCompletion
        let p = promptCompletion
        alertCompletion = nil
        confirmCompletion = nil
        promptCompletion = nil

        a?()
        c?(false)
        p?(nil)
    }
}

/// Pure routing helper for WebKit popup / target="_blank" tab creation.
public enum PopupRouter {
    @MainActor
    public static func handlePopupRequest(
        url: URL?,
        dataStore: WKWebsiteDataStore,
        tabManager: TabManager?
    ) -> Tab? {
        guard let tm = tabManager else { return nil }
        let fallbackURL = url ?? URL(string: "about:blank")!
        let newTab = tm.createNewTab(url: fallbackURL, dataStore: dataStore)
        if let targetURL = url, targetURL.scheme != nil, targetURL.absoluteString != "about:blank" {
            newTab.navigationManager.load(url: targetURL)
        }
        return newTab
    }
}

/// Unified media capture and UI delegate for WKWebView.
/// Handles media permissions, popup / new-window tab creation, and JavaScript dialogs (alert, confirm, prompt).
public final class PermissionManager: NSObject, ObservableObject, WKUIDelegate {

    /// Weak reference to TabManager for popup / new-tab creation.
    public weak var tabManager: TabManager?

    /// Saved per-domain decisions from previous sessions.
    @Published public private(set) var mediaPermissions: [String: PermissionState] = [:]

    /// The media permission request currently shown in the UI. Nil when no request is pending.
    @Published public private(set) var pendingRequest: MediaPermissionRequest?

    /// The JavaScript dialog currently shown in the UI. Nil when no dialog is pending.
    @Published public private(set) var pendingDialog: JavaScriptDialogRequest?

    // FIFO queues of requests waiting to be shown once the current one is resolved.
    private var requestQueue: [MediaPermissionRequest] = []
    private var dialogQueue: [JavaScriptDialogRequest] = []
    private let fileURL: URL

    public override init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("permissions.json")
        super.init()
        load()
    }

    // MARK: - WKUIDelegate Media Capture Permission Handling

    @available(macOS 12.0, *)
    nonisolated public func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor @Sendable (WKPermissionDecision) -> Void
    ) {
        Task { @MainActor in
            let domain = origin.host

            // Check saved decision for this domain first — resolve immediately without UI.
            if let saved = self.mediaPermissions[domain] {
                switch saved {
                case .grant:
                    decisionHandler(.grant)
                    return
                case .deny:
                    decisionHandler(.deny)
                    return
                case .prompt:
                    break // Fall through to show prompt
                }
            }

            // No saved decision — enqueue the request.
            let request = MediaPermissionRequest(
                domain: domain,
                captureType: type,
                decisionHandler: decisionHandler
            )
            self.enqueue(request)
        }
    }

    // MARK: - WKUIDelegate Popup / New-Tab Handling

    @MainActor
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }

        let url = navigationAction.request.url
        if let newTab = PopupRouter.handlePopupRequest(
            url: url,
            dataStore: configuration.websiteDataStore,
            tabManager: self.tabManager
        ) {
            return newTab.restoreIfNeeded()
        }
        return nil
    }

    // MARK: - WKUIDelegate JavaScript Dialogs

    nonisolated public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable () -> Void
    ) {
        Task { @MainActor in
            let domain = frame.securityOrigin.host.isEmpty ? (webView.url?.host ?? "Webpage") : frame.securityOrigin.host
            self.enqueueDialog(
                JavaScriptDialogRequest(
                    originDomain: domain,
                    type: .alert(message: message),
                    alertCompletion: completionHandler
                )
            )
        }
    }

    nonisolated public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        Task { @MainActor in
            let domain = frame.securityOrigin.host.isEmpty ? (webView.url?.host ?? "Webpage") : frame.securityOrigin.host
            self.enqueueDialog(
                JavaScriptDialogRequest(
                    originDomain: domain,
                    type: .confirm(message: message),
                    confirmCompletion: completionHandler
                )
            )
        }
    }

    nonisolated public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (String?) -> Void
    ) {
        Task { @MainActor in
            let domain = frame.securityOrigin.host.isEmpty ? (webView.url?.host ?? "Webpage") : frame.securityOrigin.host
            self.enqueueDialog(
                JavaScriptDialogRequest(
                    originDomain: domain,
                    type: .prompt(prompt: prompt, defaultText: defaultText),
                    promptCompletion: completionHandler
                )
            )
        }
    }

    // MARK: - User Decision API (called from UI)

    /// Called when the user approves the currently displayed media permission request.
    public func approve(id: UUID, rememberDecision: Bool = false) {
        guard let req = pendingRequest, req.id == id else { return }
        if rememberDecision {
            mediaPermissions[req.domain] = .grant
            saveAsync()
        }
        req.decisionHandler(.grant)
        dequeueNext()
    }

    /// Called when the user denies the currently displayed media permission request.
    public func deny(id: UUID, rememberDecision: Bool = false) {
        guard let req = pendingRequest, req.id == id else { return }
        if rememberDecision {
            mediaPermissions[req.domain] = .deny
            saveAsync()
        }
        req.decisionHandler(.deny)
        dequeueNext()
    }

    // MARK: - JavaScript Dialog Resolution API

    /// Called when the user acknowledges an alert dialog.
    public func resolveAlert(id: UUID) {
        guard let dialog = pendingDialog, dialog.id == id else { return }
        dialog.resolveAlert()
        dequeueNextDialog()
    }

    /// Called when the user confirms or cancels a confirmation dialog.
    public func resolveConfirm(id: UUID, result: Bool) {
        guard let dialog = pendingDialog, dialog.id == id else { return }
        dialog.resolveConfirm(result)
        dequeueNextDialog()
    }

    /// Called when the user submits or cancels a prompt dialog.
    public func resolvePrompt(id: UUID, text: String?) {
        guard let dialog = pendingDialog, dialog.id == id else { return }
        dialog.resolvePrompt(text)
        dequeueNextDialog()
    }

    /// Cancels all queued requests (media and dialogs), resolving them with safe defaults
    /// so WebKit's completionHandler contracts are always satisfied.
    public func cancelAll() {
        if let current = pendingRequest {
            current.decisionHandler(.deny)
        }
        requestQueue.forEach { $0.decisionHandler(.deny) }
        requestQueue.removeAll()
        pendingRequest = nil

        cancelAllDialogs()
    }

    /// Cancels all active and queued JavaScript dialogs.
    public func cancelAllDialogs() {
        if let current = pendingDialog {
            current.cancel()
        }
        dialogQueue.forEach { $0.cancel() }
        dialogQueue.removeAll()
        pendingDialog = nil
    }

    /// Manually set a saved permission state for a domain (e.g. from Settings).
    public func setPermission(domain: String, state: PermissionState) {
        mediaPermissions[domain] = state
        saveAsync()
    }

    // MARK: - Private Queue Management

    func enqueue(_ request: MediaPermissionRequest) {
        if pendingRequest == nil {
            pendingRequest = request
        } else {
            requestQueue.append(request)
        }
    }

    private func dequeueNext() {
        if requestQueue.isEmpty {
            pendingRequest = nil
        } else {
            pendingRequest = requestQueue.removeFirst()
        }
    }

    func enqueueDialog(_ dialog: JavaScriptDialogRequest) {
        if pendingDialog == nil {
            pendingDialog = dialog
        } else {
            dialogQueue.append(dialog)
        }
    }

    private func dequeueNextDialog() {
        if dialogQueue.isEmpty {
            pendingDialog = nil
        } else {
            pendingDialog = dialogQueue.removeFirst()
        }
    }

    private func load() {
        Task { @MainActor in
            self.mediaPermissions = await SafeJSONDecoder.decodeWithFallbackAsync(
                [String: PermissionState].self,
                from: fileURL,
                fallback: [:]
            )
        }
    }

    private func saveAsync() {
        let copy = self.mediaPermissions
        let url = self.fileURL
        Task {
            try? await DiskStorageActor.shared.write(copy, to: url)
        }
    }
}
