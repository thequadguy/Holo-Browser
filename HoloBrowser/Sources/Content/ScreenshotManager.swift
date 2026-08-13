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
@MainActor
public final class ScreenshotManager: ObservableObject {
    public static let shared = ScreenshotManager()

    @Published public private(set) var isCapturing: Bool = false
    @Published public private(set) var lastCapturedVisualContext: HoloVisualContext? = nil
    @Published public private(set) var captureError: String? = nil

    private init() {}

    /// Captures active tab webview snapshot and processes it off the main actor into a bounded HoloVisualContext.
    public func captureTabSnapshot(
        tab: Tab,
        isPrivateBrowsing: Bool,
        maxDimension: CGFloat = 1024.0,
        quality: CGFloat = 0.75
    ) async throws -> HoloVisualContext {

        // 1. Private Mode Privacy Shield Check
        guard !isPrivateBrowsing && !tab.isPrivate else {
            let error = ScreenshotError.privateBrowsingBlocked
            self.captureError = error.localizedDescription
            throw error
        }

        // 2. High-Risk Domain Check via centralized host extraction
        if let host = tab.url?.host?.lowercased() {
            let exactSuffixDomains = [
                "chase.com", "bankofamerica.com", "wellsfargo.com",
                "paypal.com", "stripe.com", "citibank.com",
                "capitalone.com", "schwab.com", "fidelity.com"
            ]
            if exactSuffixDomains.contains(where: { host == $0 || host.hasSuffix(".\($0)") }) {
                let error = ScreenshotError.highRiskDomainBlocked(host)
                self.captureError = error.localizedDescription
                throw error
            }
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

        // 3. Native WKWebView Snapshot on MainActor
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

        // 4. Off-Main Actor Downsampling & JPEG Compression
        let tabID = tab.id
        let visualContext = try await Task.detached(priority: .userInitiated) { () -> HoloVisualContext in
            guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw ScreenshotError.captureFailed("Failed to access CGImage representation.")
            }

            let origWidth = CGFloat(cgImage.width)
            let origHeight = CGFloat(cgImage.height)
            let maxDim = max(origWidth, origHeight)

            let scale = maxDim > maxDimension ? (maxDimension / maxDim) : 1.0
            let targetWidth = Int(origWidth * scale)
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
            guard let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
                throw ScreenshotError.captureFailed("Failed to encode JPEG data.")
            }

            return HoloVisualContext(
                imageData: jpegData,
                mimeType: "image/jpeg",
                width: targetWidth,
                height: targetHeight,
                sourceTabID: tabID
            )
        }.value

        self.lastCapturedVisualContext = visualContext
        return visualContext
    }

    public func clearVisualContext() {
        lastCapturedVisualContext = nil
        captureError = nil
    }
}
