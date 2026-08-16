import Foundation

/// Lightweight, value-type context abstraction representing browser context for HoloMind.
/// Strictly decoupled from heavyweight UI objects (WKWebView, NSView, TabManager, etc.)
///
/// SERIALIZATION POLICY:
/// `HoloContext` conforms to `Codable` for session/memory persistence.
/// `visualContext` is INTENTIONALLY EXCLUDED from serialization — screenshot JPEG data is
/// transient and must never be written to disk, JSON session state, HoloMind memory,
/// analytics, debug reports, or any other persistent store.
/// The explicit `CodingKeys` enum below enforces this boundary.
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

    /// Transient visual context. NOT serialized — see SERIALIZATION POLICY above.
    /// This property is populated at runtime for the current AI request only and is
    /// always nil when a HoloContext is decoded from disk.
    public let visualContext: HoloVisualContext?

    // MARK: - Explicit CodingKeys (screenshot data excluded)

    /// Only the persistent, text-based fields are coded.
    /// `visualContext` is intentionally absent — JPEG bytes must not reach disk.
    private enum CodingKeys: String, CodingKey {
        case currentPage
        case selectedText
        case relevantTabs
        case activeSpaceName
        case isPrivateBrowsing
        // visualContext is NOT listed here — it is never encoded or decoded.
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentPage      = try container.decodeIfPresent(CurrentPage.self, forKey: .currentPage)
        selectedText     = try container.decodeIfPresent(String.self, forKey: .selectedText)
        relevantTabs     = try container.decode([RelevantTab].self, forKey: .relevantTabs)
        activeSpaceName  = try container.decodeIfPresent(String.self, forKey: .activeSpaceName)
        isPrivateBrowsing = try container.decode(Bool.self, forKey: .isPrivateBrowsing)
        visualContext    = nil  // Always nil on decode — screenshots are never persisted.
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(currentPage, forKey: .currentPage)
        try container.encodeIfPresent(selectedText, forKey: .selectedText)
        try container.encode(relevantTabs, forKey: .relevantTabs)
        try container.encodeIfPresent(activeSpaceName, forKey: .activeSpaceName)
        try container.encode(isPrivateBrowsing, forKey: .isPrivateBrowsing)
        // visualContext is intentionally NOT encoded. See SERIALIZATION POLICY above.
    }

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
///
/// TRANSIENCE CONTRACT:
/// This type is intentionally NOT Codable. Screenshot JPEG data is in-memory only.
/// It must be cleared after the AI request completes (success or failure) and must
/// never be written to disk, session state, HoloMind memory, analytics, or logs.
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
///
/// `buildSanitizedContext` is `@MainActor` because `AIPrivacyManager.sanitizeContextForAI`
/// is a `@MainActor`-isolated method (it reads `@Published var privacyMode`).
/// All callers of this builder are already on the MainActor, so this boundary is correct
/// and requires no unsafe escapes.
public enum HoloContextBuilder {
    /// Maximum character length permitted for extracted active webpage text.
    public static let maxPageTextLength = 4000
    /// Maximum character length permitted for user-selected text snippet.
    public static let maxSelectedTextLength = 1000
    /// Maximum number of background relevant tabs included in AI context.
    public static let maxRelevantTabsCount = 5
    /// Maximum character length permitted for each background tab snippet.
    public static let maxTabSnippetLength = 800
    /// Maximum byte size permitted for visual screenshot payload (500 KB limit).
    public static let maxImagePayloadBytes = 500 * 1024 // 500 KB hard limit

    /// Bounds and sanitizes raw text fields and visual context for HoloContext.
    @MainActor
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
        let sanitizedCurrentPage = sanitizeCurrentPage(
            title: currentPageTitle,
            url: currentPageURL,
            rawText: rawPageText,
            headings: headings,
            isPrivate: isPrivateBrowsing,
            privacyManager: privacyManager
        )
        let boundedSelectedText = sanitizeSelectedText(selectedText, privacyManager: privacyManager)
        let boundedTabs = sanitizeTabs(tabs, isPrivate: isPrivateBrowsing, privacyManager: privacyManager)
        let safeVisualContext = sanitizeVisualContext(visualContext, isPrivate: isPrivateBrowsing)

        return HoloContext(
            currentPage: sanitizedCurrentPage,
            selectedText: boundedSelectedText,
            relevantTabs: boundedTabs,
            activeSpaceName: activeSpaceName,
            isPrivateBrowsing: isPrivateBrowsing,
            visualContext: safeVisualContext
        )
    }

    @MainActor
    private static func sanitizeCurrentPage(
        title: String?,
        url: String?,
        rawText: String?,
        headings: [String],
        isPrivate: Bool,
        privacyManager: AIPrivacyManager
    ) -> HoloContext.CurrentPage? {
        guard let title = title, !title.isEmpty else { return nil }
        let urlString = isPrivate ? "[URL Redacted — Private Browsing]" : (url ?? "")
        let host = isPrivate ? nil : (URL(string: url ?? "")?.host)
        let sanitizedText = privacyManager.sanitizeContextForAI(rawText ?? "")
        let boundedText = String(sanitizedText.prefix(maxPageTextLength))

        return HoloContext.CurrentPage(
            title: title,
            urlString: urlString,
            domainHost: host,
            extractedText: boundedText,
            headings: Array(headings.prefix(10))
        )
    }

    @MainActor
    private static func sanitizeSelectedText(_ text: String?, privacyManager: AIPrivacyManager) -> String? {
        guard let sel = text, !sel.isEmpty else { return nil }
        let sanitizedSel = privacyManager.sanitizeContextForAI(sel)
        return String(sanitizedSel.prefix(maxSelectedTextLength))
    }

    @MainActor
    private static func sanitizeTabs(
        _ tabs: [HoloContext.RelevantTab],
        isPrivate: Bool,
        privacyManager: AIPrivacyManager
    ) -> [HoloContext.RelevantTab] {
        return Array(tabs.prefix(maxRelevantTabsCount).map { tab in
            let sanitizedSnippet = tab.snippet.map { privacyManager.sanitizeContextForAI($0) }
            let boundedSnippet = sanitizedSnippet.map { String($0.prefix(maxTabSnippetLength)) }
            let urlString = isPrivate ? "[URL Redacted]" : tab.urlString
            let host = isPrivate ? nil : tab.domainHost

            return HoloContext.RelevantTab(
                id: tab.id,
                title: tab.title,
                urlString: urlString,
                domainHost: host,
                snippet: boundedSnippet,
                isPinned: tab.isPinned
            )
        })
    }

    private static func sanitizeVisualContext(_ visual: HoloVisualContext?, isPrivate: Bool) -> HoloVisualContext? {
        guard let visual = visual, !isPrivate, visual.imageData.count <= maxImagePayloadBytes else {
            return nil
        }
        return visual
    }
}
