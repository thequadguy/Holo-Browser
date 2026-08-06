import SwiftUI
import AppKit

/// Native macOS downloads popover UI showing active/completed downloads with progress bars and Finder reveal buttons.
public struct DownloadsView: View {
    @ObservedObject var downloadManager: DownloadManager
    
    public init(downloadManager: DownloadManager) {
        self.downloadManager = downloadManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Downloads")
                        .font(.headline)
                }
                Spacer()
                
                Button("Clear Completed") {
                    downloadManager.clearCompleted()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            if downloadManager.downloads.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No recent downloads")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(downloadManager.downloads) { item in
                            DownloadRowView(item: item)
                        }
                    }
                }
                .frame(minHeight: 160, maxHeight: 280)
            }
        }
        .padding(14)
        .frame(width: 380)
    }
}

private struct DownloadRowView: View {
    let item: DownloadItem
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isFinished ? "doc.fill" : "arrow.down.circle")
                .font(.system(size: 20))
                .foregroundColor(item.isFinished ? .accentColor : .purple)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.filename)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                
                if item.isFinished {
                    Text("Completed")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                } else {
                    ProgressView(value: item.progress, total: 1.0)
                        .progressViewStyle(.linear)
                }
            }
            
            Spacer()
            
            if let dest = item.destinationURL, FileManager.default.fileExists(atPath: dest.path) {
                Button(action: {
                    NSWorkspace.shared.activateFileViewerSelecting([dest])
                }) {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}
