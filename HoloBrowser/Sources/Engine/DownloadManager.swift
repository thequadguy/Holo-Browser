import WebKit
import Foundation
import Combine

public struct DownloadItem: Identifiable, Equatable {
    public let id: UUID
    public let filename: String
    public var destinationURL: URL?
    public var isFinished: Bool
    public var progress: Double
    public var bytesDownloaded: Int64
    public var totalBytes: Int64
    public var downloadSpeed: String
    public var estimatedTimeRemaining: String
    public var isFailed: Bool
    public var errorMessage: String?
    public var startTime: Date
    
    public init(
        id: UUID = UUID(),
        filename: String,
        destinationURL: URL? = nil,
        isFinished: Bool = false,
        progress: Double = 0.0,
        bytesDownloaded: Int64 = 0,
        totalBytes: Int64 = 0,
        downloadSpeed: String = "",
        estimatedTimeRemaining: String = "",
        isFailed: Bool = false,
        errorMessage: String? = nil,
        startTime: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.destinationURL = destinationURL
        self.isFinished = isFinished
        self.progress = progress
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
        self.downloadSpeed = downloadSpeed
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.isFailed = isFailed
        self.errorMessage = errorMessage
        self.startTime = startTime
    }
}

/// Native download manager implementing WKDownloadDelegate to process file downloads to ~/Downloads.
@MainActor
public final class DownloadManager: NSObject, ObservableObject, WKDownloadDelegate {
    
    @Published public private(set) var downloads: [DownloadItem] = []
    
    // Map of active WKDownload to our DownloadItem UUID
    private var activeTasks: [WKDownload: UUID] = [:]
    @Published public private(set) var lastCompletedDownload: URL?
    
    public override init() {
        super.init()
    }
    
    public func clearCompleted() {
        downloads.removeAll(where: { $0.isFinished })
    }
    
    // MARK: - Download Management Features
    
    public func openDownloadFolder() {
        let downloadsFolder = (FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())).standardized
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: downloadsFolder.path)
    }
    
    public func removeDownloadRecord(id: UUID) {
        downloads.removeAll(where: { $0.id == id })
    }
    
    public func updateProgress(id: UUID, bytesDownloaded: Int64, totalBytes: Int64) {
        guard let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        var item = downloads[idx]
        item.bytesDownloaded = bytesDownloaded
        item.totalBytes = totalBytes
        item.progress = totalBytes > 0 ? Double(bytesDownloaded) / Double(totalBytes) : 0.5
        
        let elapsed = max(Date().timeIntervalSince(item.startTime), 0.1)
        let bytesPerSec = Double(bytesDownloaded) / elapsed
        
        if bytesPerSec > 1_048_576 {
            item.downloadSpeed = String(format: "%.1f MB/s", bytesPerSec / 1_048_576.0)
        } else if bytesPerSec > 1024 {
            item.downloadSpeed = String(format: "%.0f KB/s", bytesPerSec / 1024.0)
        } else {
            item.downloadSpeed = String(format: "%d B/s", Int64(bytesPerSec))
        }
        
        if totalBytes > bytesDownloaded && bytesPerSec > 0 {
            let remainingBytes = totalBytes - bytesDownloaded
            let remainingSecs = Int(Double(remainingBytes) / bytesPerSec)
            if remainingSecs < 60 {
                item.estimatedTimeRemaining = "\(remainingSecs)s remaining"
            } else {
                item.estimatedTimeRemaining = "\(remainingSecs / 60)m remaining"
            }
        } else {
            item.estimatedTimeRemaining = ""
        }
        
        downloads[idx] = item
    }
    
    // MARK: - WKDownloadDelegate
    
    nonisolated public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
        let downloadsFolder = (FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())).standardized
        
        // Strip relative components, directory traversal attempts, and leading slashes
        let cleanName = (suggestedFilename as NSString).lastPathComponent
            .replacingOccurrences(of: "..", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/\\"))
        
        let sanitizedFilename = cleanName.isEmpty ? "download" : cleanName
        let destinationURL = downloadsFolder.appendingPathComponent(sanitizedFilename).standardized
        
        // Verify path containment inside ~/Downloads/
        guard destinationURL.path.hasPrefix(downloadsFolder.path) else {
            return downloadsFolder.appendingPathComponent("download")
        }
        
        var finalURL = destinationURL
        var counter = 1
        let name = destinationURL.deletingPathExtension().lastPathComponent
        let ext = destinationURL.pathExtension
        
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let newName = ext.isEmpty ? "\(name) (\(counter))" : "\(name) (\(counter)).\(ext)"
            finalURL = downloadsFolder.appendingPathComponent(newName)
            counter += 1
        }
        
        let expectedLength = response.expectedContentLength
        
        Task { @MainActor in
            let item = DownloadItem(
                filename: finalURL.lastPathComponent,
                destinationURL: finalURL,
                isFinished: false,
                progress: 0.1,
                totalBytes: expectedLength > 0 ? expectedLength : 0,
                downloadSpeed: "Calculating...",
                startTime: Date()
            )
            self.activeTasks[download] = item.id
            self.downloads.insert(item, at: 0)
        }
        
        return finalURL
    }
    
    nonisolated public func downloadDidFinish(_ download: WKDownload) {
        Task { @MainActor in
            guard let id = self.activeTasks[download] else { return }
            self.activeTasks.removeValue(forKey: download)
            
            if let idx = self.downloads.firstIndex(where: { $0.id == id }) {
                var finished = self.downloads[idx]
                finished.isFinished = true
                finished.progress = 1.0
                finished.downloadSpeed = "Complete"
                finished.estimatedTimeRemaining = ""
                self.downloads[idx] = finished
                self.lastCompletedDownload = finished.destinationURL
            }
        }
    }
    
    nonisolated public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        Task { @MainActor in
            guard let id = self.activeTasks[download] else { return }
            self.activeTasks.removeValue(forKey: download)
            if let idx = self.downloads.firstIndex(where: { $0.id == id }) {
                var failed = self.downloads[idx]
                failed.isFailed = true
                failed.errorMessage = error.localizedDescription
                failed.downloadSpeed = "Failed"
                self.downloads[idx] = failed
            }
        }
    }
}
