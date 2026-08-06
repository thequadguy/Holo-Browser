import Foundation

public struct ImportedBookmark: Equatable {
    public let title: String
    public let urlString: String
    public let folderName: String?
}

/// Read-only bookmark importer for Safari, Chrome, and Firefox exports. Zero password access.
public enum BrowserImportManager {
    
    /// Parses an exported HTML bookmark file (Chrome/Firefox format).
    public static func importHTMLBookmarks(from url: URL) -> [ImportedBookmark] {
        guard let html = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var results: [ImportedBookmark] = []

        
        let pattern = "<A [^>]*HREF=\"([^\"]+)\"[^>]*>([^<]+)</A>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let href = nsString.substring(with: match.range(at: 1))
                let title = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !href.isEmpty && !title.isEmpty {
                    results.append(ImportedBookmark(title: title, urlString: href, folderName: "Imported"))
                }
            }
        }
        
        return results
    }
}
