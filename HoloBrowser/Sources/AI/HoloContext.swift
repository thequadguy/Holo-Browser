import Foundation

/// Lightweight, value-type context abstraction representing browser context for HoloMind.
/// Strictly decoupled from heavyweight UI objects (WKWebView, NSView, TabManager, etc.)
public struct HoloContext: Codable, Equatable {
    public struct CurrentPage: Codable, Equatable {
        public let title: String
        public let urlString: String
        public let domainHost: String?
        public let extractedText: String
        public let headings: [String]
        public let timestamp: Date
        
        public init(
            title: String,
            urlString: String,
            domainHost: String? = nil,
            extractedText: String,
            headings: [String] = [],
            timestamp: Date = Date()
        ) {
            self.title = title
            self.urlString = urlString
            self.domainHost = domainHost
            self.extractedText = extractedText
            self.headings = headings
            self.timestamp = timestamp
        }
    }
    
    public struct RelevantTab: Codable, Equatable, Identifiable {
        public let id: UUID
        public let title: String
        public let urlString: String
        public let domainHost: String?
        public let snippet: String?
        public let isPinned: Bool
        
        public init(
            id: UUID,
            title: String,
            urlString: String,
            domainHost: String? = nil,
            snippet: String? = nil,
            isPinned: Bool = false
        ) {
            self.id = id
            self.title = title
            self.urlString = urlString
            self.domainHost = domainHost
            self.snippet = snippet
            self.isPinned = isPinned
        }
    }
    
    public let currentPage: CurrentPage?
    public let selectedText: String?
    public let relevantTabs: [RelevantTab]
    public let activeSpaceName: String?
    public let isPrivateBrowsing: Bool
    public let visualContext: HoloVisualContext?
    
    public init(
        currentPage: CurrentPage? = nil,
        selectedText: String? = nil,
        relevantTabs: [RelevantTab] = [],
        activeSpaceName: String? = nil,
        isPrivateBrowsing: Bool = false,
        visualContext: HoloVisualContext? = nil
    ) {
        self.currentPage = currentPage
        self.selectedText = selectedText
        self.relevantTabs = relevantTabs
        self.activeSpaceName = activeSpaceName
        self.isPrivateBrowsing = isPrivateBrowsing
        self.visualContext = visualContext
    }
}

/// Dedicated transient visual context structure for screenshot payloads.
/// Avoids bloating standard text contexts with heavy binary data.
public struct HoloVisualContext: Equatable {
    public let imageData: Data
    public let mimeType: String
    public let width: Int
    public let height: Int
    public let sourceTabID: UUID
    public let timestamp: Date
    
    public init(
        imageData: Data,
        mimeType: String = "image/jpeg",
        width: Int,
        height: Int,
        sourceTabID: UUID,
        timestamp: Date = Date()
    ) {
        self.imageData = imageData
        self.mimeType = mimeType
        self.width = width
        self.height = height
        self.sourceTabID = sourceTabID
        self.timestamp = timestamp
    }
}

/// Deterministic, bounded builder creating sanitized HoloContext value-types.
public enum HoloContextBuilder {
    public static let maxPageTextLength = 4000
    public static let maxSelectedTextLength = 1000
    public static let maxRelevantTabsCount = 5
    public static let maxTabSnippetLength = 800
    public static let maxImagePayloadBytes = 500 * 1024 // 500 KB limit
    
    /// Bounds and sanitizes raw text fields and visual context for HoloContext.
    public static func buildSanitizedContext(
        currentPageTitle: String?,
        currentPageURL: String?,
        rawPageText: String?,
        headings: [String] = [],
        selectedText: String?,
        tabs: [HoloContext.RelevantTab] = [],
        activeSpaceName: String?,
        isPrivateBrowsing: Bool,
        visualContext: HoloVisualContext? = nil,
        privacyManager: AIPrivacyManager
    ) -> HoloContext {
        
        let sanitizedCurrentPage: HoloContext.CurrentPage?
        if let title = currentPageTitle, !title.isEmpty {
            let urlString = isPrivateBrowsing ? "[URL Redacted — Private Browsing]" : (currentPageURL ?? "")
            let host = isPrivateBrowsing ? nil : (URL(string: currentPageURL ?? "")?.host)
            let sanitizedText = privacyManager.sanitizeContextForAI(rawPageText ?? "")
            let boundedText = String(sanitizedText.prefix(maxPageTextLength))
            
            sanitizedCurrentPage = HoloContext.CurrentPage(
                title: title,
                urlString: urlString,
                domainHost: host,
                extractedText: boundedText,
                headings: Array(headings.prefix(10))
            )
        } else {
            sanitizedCurrentPage = nil
        }
        
        let boundedSelectedText: String?
        if let sel = selectedText, !sel.isEmpty {
            let sanitizedSel = privacyManager.sanitizeContextForAI(sel)
            boundedSelectedText = String(sanitizedSel.prefix(maxSelectedTextLength))
        } else {
            boundedSelectedText = nil
        }
        
        let boundedTabs = tabs.prefix(maxRelevantTabsCount).map { tab in
            let sanitizedSnippet = tab.snippet != nil ? privacyManager.sanitizeContextForAI(tab.snippet!) : nil
            let boundedSnippet = sanitizedSnippet != nil ? String(sanitizedSnippet!.prefix(maxTabSnippetLength)) : nil
            let urlString = isPrivateBrowsing ? "[URL Redacted]" : tab.urlString
            let host = isPrivateBrowsing ? nil : tab.domainHost
            
            return HoloContext.RelevantTab(
                id: tab.id,
                title: tab.title,
                urlString: urlString,
                domainHost: host,
                snippet: boundedSnippet,
                isPinned: tab.isPinned
            )
        }
        
        // Ensure visualContext obeys private browsing shield and max byte size
        let safeVisualContext: HoloVisualContext?
        if let visual = visualContext, !isPrivateBrowsing, visual.imageData.count <= maxImagePayloadBytes {
            safeVisualContext = visual
        } else {
            safeVisualContext = nil
        }
        
        return HoloContext(
            currentPage: sanitizedCurrentPage,
            selectedText: boundedSelectedText,
            relevantTabs: Array(boundedTabs),
            activeSpaceName: activeSpaceName,
            isPrivateBrowsing: isPrivateBrowsing,
            visualContext: safeVisualContext
        )
    }
}

