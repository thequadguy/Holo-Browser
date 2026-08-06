import WebKit
import Foundation
import Combine

public struct DownloadItem: Identifiable, Equatable {
    public let id: UUID
    public let filename: String
    public var destinationURL: URL?
    public var isFinished: Bool
    public var progress: Double
    
    public init(
        id: UUID = UUID(),
        filename: String,
        destinationURL: URL? = nil,
        isFinished: Bool = false,
        progress: Double = 0.0
    ) {
        self.id = id
        self.filename = filename
        self.destinationURL = destinationURL
        self.isFinished = isFinished
        self.progress = progress
    }
}

/// Native download manager implementing WKDownloadDelegate to process file downloads to ~/Downloads.
@MainActor
public final class DownloadManager: NSObject, ObservableObject, WKDownloadDelegate {
    
    @Published public private(set) var downloads: [DownloadItem] = []
    @Published public private(set) var activeDownloads: [String] = []
    @Published public private(set) var lastCompletedDownload: URL?
    
    public override init() {
        super.init()
    }
    
    public func clearCompleted() {
        downloads.removeAll(where: { $0.isFinished })
    }
    
    // MARK: - WKDownloadDelegate
    
    nonisolated public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
        let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = downloadsFolder.appendingPathComponent(suggestedFilename)
        
        try? FileManager.default.removeItem(at: destinationURL)
        
        Task { @MainActor in
            self.activeDownloads.append(suggestedFilename)
            let item = DownloadItem(filename: suggestedFilename, destinationURL: destinationURL, isFinished: false, progress: 0.5)
            self.downloads.insert(item, at: 0)
        }
        
        return destinationURL
    }
    
    nonisolated public func downloadDidFinish(_ download: WKDownload) {
        Task { @MainActor in
            if !self.activeDownloads.isEmpty {
                self.activeDownloads.removeFirst()
            }
            if let idx = self.downloads.firstIndex(where: { !$0.isFinished }) {
                var finished = self.downloads[idx]
                finished.isFinished = true
                finished.progress = 1.0
                self.downloads[idx] = finished
                self.lastCompletedDownload = finished.destinationURL
            }
        }
    }
    
    nonisolated public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        Task { @MainActor in
            if !self.activeDownloads.isEmpty {
                self.activeDownloads.removeFirst()
            }
        }
    }
}
