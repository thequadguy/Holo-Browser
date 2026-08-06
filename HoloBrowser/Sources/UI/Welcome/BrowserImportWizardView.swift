import SwiftUI
import AppKit

/// Interactive Browser Migration & Data Import Wizard.
/// Solves the user transparency issue by verifying imported bookmarks/folders/history and displaying live confirmation counts.
public struct BrowserImportWizardView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var historyStore: HistoryStore
    let onDismiss: () -> Void
    let onOpenBookmarks: (() -> Void)?
    let onOpenHistory: (() -> Void)?
    
    @State private var selectedBrowser: String = "Chrome"
    @State private var importBookmarks: Bool = true
    @State private var importHistory: Bool = true
    @State private var isImporting: Bool = false
    @State private var summaryResult: ImportSummaryResult? = nil
    
    private let browserOptions = [
        ("Chrome", "Google Chrome", "globe.americas.fill", Color.blue),
        ("Safari", "Apple Safari", "safari.fill", Color.blue),
        ("Brave", "Brave Browser", "lion.fill", Color.orange),
        ("Firefox", "Mozilla Firefox", "flame.fill", Color.red)
    ]
    
    public init(
        bookmarkManager: BookmarkManager,
        historyStore: HistoryStore,
        onDismiss: @escaping () -> Void,
        onOpenBookmarks: (() -> Void)? = nil,
        onOpenHistory: (() -> Void)? = nil
    ) {
        self.bookmarkManager = bookmarkManager
        self.historyStore = historyStore
        self.onDismiss = onDismiss
        self.onOpenBookmarks = onOpenBookmarks
        self.onOpenHistory = onOpenHistory
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Browser Migration Wizard")
                        .font(.system(size: 16, weight: .bold))
                    Text("Import bookmarks, folders, and history into Holo Browser")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
            
            Divider()
            
            // Content State Engine
            VStack(alignment: .leading, spacing: 16) {
                if let summary = summaryResult {
                    importSummaryView(summary)
                } else if isImporting {
                    importProgressView
                } else {
                    importConfigurationView
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
            
            Divider()
            
            // Footer Action Bar
            HStack {
                if summaryResult != nil {
                    HoloGlassButton(title: "Close Wizard", icon: "xmark") {
                        onDismiss()
                    }
                } else {
                    HoloGlassButton(title: "Cancel") {
                        onDismiss()
                    }
                    
                    Spacer()
                    
                    HoloGlassButton(title: "Select File & Import", icon: "folder.badge.plus", isProminent: true) {
                        triggerFileImport()
                    }
                }
            }
            .padding(14)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
        }
        .frame(width: 540, height: 420)
        .holoGlassCard(cornerRadius: 14, padding: 0)
    }
    
    // MARK: - Subviews
    
    private var importConfigurationView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("1. Select Source Browser")
                .font(.system(size: 13, weight: .semibold))
            
            HStack(spacing: 10) {
                ForEach(browserOptions, id: \.0) { id, name, icon, color in
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedBrowser == id ? .white : color)
                        Text(name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedBrowser == id ? .white : .primary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedBrowser == id ? Color.accentColor : Color.gray.opacity(0.1))
                    )
                    .onTapGesture {
                        selectedBrowser = id
                    }
                }
            }
            
            Text("2. Select Data Components to Import")
                .font(.system(size: 13, weight: .semibold))
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Bookmarks & Folder Hierarchy", isOn: $importBookmarks)
                    .font(.system(size: 12))
                Toggle("Browsing History Records", isOn: $importHistory)
                    .font(.system(size: 12))
            }
            
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                Text("Select your exported HTML bookmarks file from \(selectedBrowser). Zero password or telemetry data accessed.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.08)))
        }
    }
    
    private var importProgressView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)
            
            Text("Processing & Committing Imported Items...")
                .font(.system(size: 14, weight: .semibold))
            
            Text("Writing bookmarks, creating folder hierarchy, and updating history index.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func importSummaryView(_ summary: ImportSummaryResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Import Completed Successfully!")
                        .font(.system(size: 16, weight: .bold))
                    Text("Source: \(summary.sourceBrowser)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(spacing: 10) {
                MetricRow(title: "Bookmarks Imported", value: "\(summary.bookmarksCount)", icon: "bookmark.fill", color: .blue)
                MetricRow(title: "Folders Created", value: "\(summary.foldersCreatedCount)", icon: "folder.fill", color: .purple)
                MetricRow(title: "History Records Committed", value: "\(summary.historyCount)", icon: "clock.fill", color: .orange)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.08)))
            
            if !summary.failures.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warnings/Failures (\(summary.failures.count)):")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                    Text(summary.failures.prefix(2).joined(separator: "\n"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                if let openBookmarks = onOpenBookmarks {
                    HoloGlassButton(title: "Verify Bookmarks in Library", icon: "bookmark") {
                        openBookmarks()
                        onDismiss()
                    }
                }
                if let openHistory = onOpenHistory {
                    HoloGlassButton(title: "Verify History", icon: "clock") {
                        openHistory()
                        onDismiss()
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Import File Action
    
    private func triggerFileImport() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.html]
        panel.title = "Select Exported HTML Bookmarks File (\(selectedBrowser))"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.isImporting = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let result = BrowserImportManager.executeFullImport(
                        fileURL: url,
                        browserSource: self.selectedBrowser,
                        bookmarkManager: self.bookmarkManager,
                        historyStore: self.historyStore,
                        importHistory: self.importHistory
                    )
                    
                    self.isImporting = false
                    self.summaryResult = result
                    LocalUsageMetrics.shared.recordFeatureUsage(name: "FullBrowserImportExecuted")
                }
            }
        }
    }
}

private struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .frame(width: 20)
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
