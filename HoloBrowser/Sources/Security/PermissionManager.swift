import Foundation
import WebKit

/// Represents an ongoing permission request awaiting user approval/denial.
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

/// Unified media capture permission delegate for WKWebView.
///
/// P0-C Fix: replaced single `pendingRequest: Optional` with a FIFO queue.
///
/// Under the previous design, if website A requested the camera while website B's
/// permission sheet was already showing, website B's `MediaPermissionRequest` was
/// overwritten without calling its `decisionHandler`. This violates WebKit's
/// invariant that every `decisionHandler` must be invoked exactly once, causing
/// WebKit to hang or drop subsequent permission requests permanently.
///
/// With `requestQueue`, incoming requests are enqueued and presented sequentially.
/// `cancelAll()` is called when tabs close, resolving all queued requests with `.deny`.
public final class PermissionManager: NSObject, ObservableObject, WKUIDelegate {

    /// Saved per-domain decisions from previous sessions.
    @Published public private(set) var mediaPermissions: [String: PermissionState] = [:]

    /// The request currently shown in the UI. Nil when no request is pending.
    @Published public private(set) var pendingRequest: MediaPermissionRequest?

    // FIFO queue of requests waiting to be shown once the current one is resolved.
    private var requestQueue: [MediaPermissionRequest] = []
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

    // MARK: - User Decision API (called from UI)

    /// Called when the user approves the currently displayed permission request.
    public func approve(id: UUID, rememberDecision: Bool = false) {
        guard let req = pendingRequest, req.id == id else { return }
        if rememberDecision {
            mediaPermissions[req.domain] = .grant
            saveAsync()
        }
        req.decisionHandler(.grant)
        dequeueNext()
    }

    /// Called when the user denies the currently displayed permission request.
    public func deny(id: UUID, rememberDecision: Bool = false) {
        guard let req = pendingRequest, req.id == id else { return }
        if rememberDecision {
            mediaPermissions[req.domain] = .deny
            saveAsync()
        }
        req.decisionHandler(.deny)
        dequeueNext()
    }

    /// Cancels all queued requests (e.g. on tab close), resolving them with .deny
    /// so WebKit's decisionHandler contract is always satisfied.
    public func cancelAll() {
        if let current = pendingRequest {
            current.decisionHandler(.deny)
        }
        requestQueue.forEach { $0.decisionHandler(.deny) }
        requestQueue.removeAll()
        pendingRequest = nil
    }

    /// Manually set a saved permission state for a domain (e.g. from Settings).
    public func setPermission(domain: String, state: PermissionState) {
        mediaPermissions[domain] = state
        saveAsync()
    }

    // MARK: - Private Queue Management

    func enqueue(_ request: MediaPermissionRequest) {
        if pendingRequest == nil {
            // Nothing currently shown — display immediately.
            pendingRequest = request
        } else {
            // Something is shown — queue for later.
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
