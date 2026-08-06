import WebKit
import Foundation
import Combine

public enum PermissionState: String, Codable {
    case prompt
    case grant
    case deny
}

/// Pending permission request surfaced to the UI for user approval.
public struct MediaPermissionRequest: Identifiable {
    public let id: UUID = UUID()
    public let domain: String
    public let captureType: WKMediaCaptureType
    public let decisionHandler: @MainActor @Sendable (WKPermissionDecision) -> Void
}

/// Website Media & Hardware Permission Manager conforming to WKUIDelegate.
///
/// P0-C Fix: replaced single `pendingRequest: Optional` with a FIFO queue.
/// The previous design overwrote the first request when a second arrived simultaneously,
/// leaving the first WebKit decisionHandler uncalled — a WebKit API contract violation
/// that caused process assertion failures.
///
/// The queue processes one request at a time. Arriving requests are enqueued and
/// surfaced to the UI sequentially after each approve/deny resolution.
@MainActor
public final class PermissionManager: NSObject, ObservableObject, WKUIDelegate {

    /// Saved per-domain decisions from previous sessions.
    @Published public private(set) var mediaPermissions: [String: PermissionState] = [:]

    /// The request currently shown in the UI. Nil when no request is pending.
    @Published public private(set) var pendingRequest: MediaPermissionRequest? = nil

    // FIFO queue of requests waiting to be shown once the current one is resolved.
    private var requestQueue: [MediaPermissionRequest] = []

    public override init() {
        super.init()
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
        }
        req.decisionHandler(.grant)
        dequeueNext()
    }

    /// Called when the user denies the currently displayed permission request.
    public func deny(id: UUID, rememberDecision: Bool = false) {
        guard let req = pendingRequest, req.id == id else { return }
        if rememberDecision {
            mediaPermissions[req.domain] = .deny
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
    }

    // MARK: - Private Queue Management

    private func enqueue(_ request: MediaPermissionRequest) {
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
}
