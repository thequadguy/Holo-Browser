import Foundation
import WebKit
import AppKit

public enum ScreenshotError: LocalizedError, Equatable {
    case privateBrowsingBlocked
    case highRiskDomainBlocked(String)
    case captureFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .privateBrowsingBlocked:
            return "Screenshot capture is strictly disabled in Private Browsing mode."
        case .highRiskDomainBlocked(let domain):
            return "Screenshot capture blocked on high-risk domain: \(domain)"
        case .captureFailed(let reason):
            return "Screenshot capture failed: \(reason)"
        case .cancelled:
            return "Screenshot capture was cancelled."
        }
    }
}

/// Asynchronous manager handling non-blocking WKWebView snapshot capture and transient JPEG downsampling.
///
/// Privacy architecture:
/// - Layer 1 (this class): checks tab.isPrivate AND caller-supplied isPrivateBrowsing.
///   Both must be false for capture to proceed.
/// - Layer 2 (AIContextGatekeeper.validateImageContext): independent check in the AI path.
/// - Domain blocking delegates to the centralised HighRiskDomainChecker.
///
/// Concurrency architecture:
/// - WKWebView.takeSnapshot runs on the MainActor (required by WebKit).
/// - NSImage → CGImage conversion happens on the MainActor immediately after snapshot,
///   producing a CGImage value type that is safe to pass to a detached Task.
/// - Resize + JPEG encode runs in Task.detached (off the main thread).
/// - All published state mutations happen back on MainActor via @MainActor isolation.
@MainActor
public final class ScreenshotManager: ObservableObject {
    public static let shared = ScreenshotManager()

    @Published public private(set) var isCapturing: Bool = false
    @Published public private(set) var lastCapturedVisualContext: HoloVisualContext?
    @Published public private(set) var captureError: String?

    private init() {}

    /// Captures the active tab's WKWebView snapshot and returns a bounded HoloVisualContext.
    ///
    /// Privacy contract (enforced before any pixel is captured):
    /// 1. `isPrivateBrowsing` parameter must be false.
    /// 2. `tab.isPrivate` must also be false (defence in depth — the caller cannot lie about
    ///    private state by passing the wrong flag).
    /// 3. The tab's current URL must not be on the high-risk domain list.
    public func captureTabSnapshot(
        tab: Tab,
        isPrivateBrowsing: Bool,
        maxDimension: CGFloat = 1024.0,
        quality: CGFloat = 0.75
    ) async throws -> HoloVisualContext {

        // Layer 1a — caller-supplied private browsing flag.
        guard !isPrivateBrowsing else {
            let error = ScreenshotError.privateBrowsingBlocked
            self.captureError = error.localizedDescription
            throw error
        }

        // Layer 1b — authoritative tab.isPrivate check.
        // This prevents a buggy caller from hard-coding false.
        guard !tab.isPrivate else {
            let error = ScreenshotError.privateBrowsingBlocked
            self.captureError = error.localizedDescription
            throw error
        }

        // Layer 2 — consolidated high-risk domain check.
        if let host = tab.url?.host?.lowercased(), HighRiskDomainChecker.isHighRisk(host) {
            let error = ScreenshotError.highRiskDomainBlocked(host)
            self.captureError = error.localizedDescription
            throw error
        }

        guard let webView = tab.webView else {
            let error = ScreenshotError.captureFailed("No active WKWebView available.")
            self.captureError = error.localizedDescription
            throw error
        }

        self.isCapturing = true
        self.captureError = nil

        defer {
            self.isCapturing = false
        }

        // 3. Native WKWebView snapshot — must run on MainActor.
        let config = WKSnapshotConfiguration()
        config.rect = webView.bounds

        let nsImage: NSImage
        do {
            nsImage = try await webView.takeSnapshot(configuration: config)
        } catch {
            let err = ScreenshotError.captureFailed(error.localizedDescription)
            self.captureError = err.localizedDescription
            throw err
        }

        // 4. Convert NSImage → CGImage on the MainActor before leaving the actor boundary.
        //    CGImage is an immutable, reference-counted Core Foundation object that is safe
        //    to pass across actor boundaries; NSImage is NOT Sendable.
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            let err = ScreenshotError.captureFailed("Failed to access CGImage representation.")
            self.captureError = err.localizedDescription
            throw err
        }

        let tabID = tab.id

        // 5. Off-main-actor resize + JPEG encode.
        let visualContext = try await processSnapshot(
            cgImage: cgImage,
            tabID: tabID,
            maxDimension: maxDimension,
            quality: quality
        )

        self.lastCapturedVisualContext = visualContext
        return visualContext
    }

    public func clearVisualContext() {
        lastCapturedVisualContext = nil
        captureError = nil
    }

    // MARK: - Private Helpers

    /// Performs dimension-bounded downsampling and JPEG encoding off the MainActor.
    ///
    /// `cgImage` is a Core Foundation immutable object — it is safe to capture by value
    /// in a detached task without violating Swift concurrency rules.
    private func processSnapshot(
        cgImage: CGImage,
        tabID: UUID,
        maxDimension: CGFloat,
        quality: CGFloat
    ) async throws -> HoloVisualContext {
        // Capture immutable scalars only — no actor-isolated state enters the detached task.
        let origWidth = CGFloat(cgImage.width)
        let origHeight = CGFloat(cgImage.height)
        let maxImagePayloadBytes = HoloContextBuilder.maxImagePayloadBytes

        return try await Task.detached(priority: .userInitiated) { () -> HoloVisualContext in
            let maxDim = max(origWidth, origHeight)
            let scale = maxDim > maxDimension ? (maxDimension / maxDim) : 1.0
            let targetWidth  = Int(origWidth  * scale)
            let targetHeight = Int(origHeight * scale)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: nil,
                width: targetWidth,
                height: targetHeight,
                bitsPerComponent: 8,
                bytesPerRow: targetWidth * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw ScreenshotError.captureFailed("Failed to create downsampling graphics context.")
            }

            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

            guard let resizedCGImage = context.makeImage() else {
                throw ScreenshotError.captureFailed("Failed to construct resized image.")
            }

            let rep = NSBitmapImageRep(cgImage: resizedCGImage)

            // Attempt at configured quality first.
            var jpegData: Data? = rep.representation(using: .jpeg, properties: [.compressionFactor: quality])

            // If still over the size limit, progressively reduce quality to enforce the bound.
            // This guarantees the hard 500 KB limit is respected even on very large displays.
            var currentQuality = quality
            while let data = jpegData, data.count > maxImagePayloadBytes, currentQuality > 0.3 {
                currentQuality -= 0.1
                jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: currentQuality])
            }

            guard let finalJpegData = jpegData, finalJpegData.count <= maxImagePayloadBytes else {
                throw ScreenshotError.captureFailed(
                    "Could not compress screenshot to within the \(maxImagePayloadBytes / 1024) KB limit."
                )
            }

            return HoloVisualContext(
                imageData: finalJpegData,
                mimeType: "image/jpeg",
                width: targetWidth,
                height: targetHeight,
                sourceTabID: tabID
            )
        }.value
    }
}
