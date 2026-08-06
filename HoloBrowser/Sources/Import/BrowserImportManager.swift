import Foundation

public struct ImportedBookmark: Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let urlString: String
    public let folderName: String?
    public let browserSource: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        urlString: String,
        folderName: String? = "Imported",
        browserSource: String = "Browser"
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.folderName = folderName
        self.browserSource = browserSource
    }
}

public struct ImportSummaryResult: Equatable {
    public let bookmarksCount: Int
    public let foldersCreatedCount: Int
    public let historyCount: Int
    public let failures: [String]
    public let sourceBrowser: String
    
    public init(
        bookmarksCount: Int,
        foldersCreatedCount: Int,
        historyCount: Int,
        failures: [String] = [],
        sourceBrowser: String
    ) {
        self.bookmarksCount = bookmarksCount
        self.foldersCreatedCount = foldersCreatedCount
        self.historyCount = historyCount
        self.failures = failures
        self.sourceBrowser = sourceBrowser
    }
}

/// Robust reader and importer for Safari, Chrome, Brave, and Firefox exports with direct UI store insertion.
public enum BrowserImportManager {
    
    /// Parses an exported HTML bookmark file (Netscape Bookmark Format used by Chrome, Safari, Firefox, Brave).
    public static func importHTMLBookmarks(from url: URL, source: String = "Chrome") -> [ImportedBookmark] {
        guard let html = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var results: [ImportedBookmark] = []
        var currentFolder = "Imported"
        
        let lines = html.components(separatedBy: .newlines)
        let linkRegex = try? NSRegularExpression(pattern: "<A [^>]*HREF=\"([^\"]+)\"[^>]*>([^<]+)</A>", options: [.caseInsensitive])
        let folderRegex = try? NSRegularExpression(pattern: "<H3[^>]*>([^<]+)</H3>", options: [.caseInsensitive])
        
        for line in lines {
            let nsLine = line as NSString
            let lineRange = NSRange(location: 0, length: nsLine.length)
            
            if let folderMatch = folderRegex?.firstMatch(in: line, options: [], range: lineRange), folderMatch.numberOfRanges >= 2 {
                let folder = nsLine.substring(with: folderMatch.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !folder.isEmpty {
                    currentFolder = folder
                }
            }
            
            if let linkMatch = linkRegex?.firstMatch(in: line, options: [], range: lineRange), linkMatch.numberOfRanges >= 3 {
                let href = nsLine.substring(with: linkMatch.range(at: 1))
                let title = nsLine.substring(with: linkMatch.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !href.isEmpty && !title.isEmpty && (href.hasPrefix("http://") || href.hasPrefix("https://")) {
                    results.append(ImportedBookmark(title: title, urlString: href, folderName: currentFolder, browserSource: source))
                }
            }
        }
        
        return results
    }
    
    /// Executes full data import and commits bookmarks directly into BookmarkManager and HistoryStore.
    @MainActor
    public static func executeFullImport(
        fileURL: URL,
        browserSource: String,
        bookmarkManager: BookmarkManager,
        historyStore: HistoryStore,
        importHistory: Bool = true
    ) -> ImportSummaryResult {
        var failures: [String] = []
        let imported = importHTMLBookmarks(from: fileURL, source: browserSource)
        
        if imported.isEmpty {
            failures.append("No valid HTTP/HTTPS bookmarks found in file.")
        }
        
        var createdFolders = Set<String>()
        var importedBookmarkCount = 0
        var importedHistoryCount = 0
        
        for item in imported {
            guard let url = URL(string: item.urlString) else {
                failures.append("Invalid URL: \(item.urlString)")
                continue
            }
            
            let folderName = item.folderName ?? "Imported"
            createdFolders.insert(folderName)
            
            // Insert bookmark into BookmarkManager
            bookmarkManager.addBookmark(title: item.title, url: url, folderName: folderName)
            importedBookmarkCount += 1
            
            // Insert into HistoryStore if history option selected
            if importHistory {
                historyStore.addEntry(url: url, title: item.title, isPrivate: false)
                importedHistoryCount += 1
            }
        }
        
        return ImportSummaryResult(
            bookmarksCount: importedBookmarkCount,
            foldersCreatedCount: createdFolders.count,
            historyCount: importedHistoryCount,
            failures: failures,
            sourceBrowser: browserSource
        )
    }
}
