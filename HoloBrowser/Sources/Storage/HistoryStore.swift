import Foundation

/// Data model representing a browsing history entry.
public struct HistoryItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let urlString: String
    public let title: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), urlString: String, title: String, timestamp: Date = Date()) {
        self.id = id
        self.urlString = urlString
        self.title = title
        self.timestamp = timestamp
    }
}

/// Local JSON persistence store for browsing history with non-blocking background disk I/O.
@MainActor
public final class HistoryStore: ObservableObject {
    @Published public private(set) var historyItems: [HistoryItem] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("history.json")
        load()
    }
    
    /// Appends a new item to browsing history.
    public func addEntry(url: URL, title: String, isPrivate: Bool = false) {
        guard !isPrivate else { return }
        guard !url.absoluteString.isEmpty && url.scheme != "about" else { return }
        let displayTitle = title.isEmpty ? url.absoluteString : title
        let newItem = HistoryItem(urlString: url.absoluteString, title: displayTitle)
        
        historyItems.removeAll(where: { $0.urlString == newItem.urlString })
        historyItems.insert(newItem, at: 0)
        
        if historyItems.count > 10000 {
            historyItems.removeLast(historyItems.count - 10000)
        }
        
        saveAsync()
    }
    
    /// Clears all stored browsing history records.
    public func clearAll() {
        historyItems.removeAll()
        saveAsync()
    }
    
    // MARK: - Advanced History Management (Phase 4)
    
    public func searchHistory(query: String) -> [HistoryItem] {
        if query.isEmpty { return historyItems }
        return historyItems.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.urlString.localizedCaseInsensitiveContains(query) }
    }
    
    public func groupHistoryByDate() -> [Date: [HistoryItem]] {
        return Dictionary(grouping: historyItems, by: { Calendar.current.startOfDay(for: $0.timestamp) })
    }
    
    public func deleteItems(ids: Set<UUID>) {
        historyItems.removeAll(where: { ids.contains($0.id) })
        saveAsync()
    }
    
    private func load() {
        Task { @MainActor in
            self.historyItems = await SafeJSONDecoder.decodeWithFallbackAsync([HistoryItem].self, from: fileURL, fallback: [])
        }
    }
    
    private var saveTask: Task<Void, Never>?
    
    /// Non-blocking background save using DiskStorageActor for FIFO serial writes with debouncing
    private func saveAsync() {
        saveTask?.cancel()
        let itemsCopy = self.historyItems
        let url = self.fileURL
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            guard !Task.isCancelled else { return }
            try? await DiskStorageActor.shared.write(itemsCopy, to: url)
        }
    }
}
