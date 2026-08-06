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
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("history.json")
        load()
    }
    
    /// Appends a new item to browsing history.
    public func addEntry(url: URL, title: String) {
        guard !url.absoluteString.isEmpty && url.scheme != "about" else { return }
        let displayTitle = title.isEmpty ? url.absoluteString : title
        let newItem = HistoryItem(urlString: url.absoluteString, title: displayTitle)
        
        historyItems.removeAll(where: { $0.urlString == newItem.urlString })
        historyItems.insert(newItem, at: 0)
        saveAsync()
    }
    
    /// Clears all stored browsing history records.
    public func clearAll() {
        historyItems.removeAll()
        saveAsync()
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([HistoryItem].self, from: data)
            self.historyItems = items
        } catch {
            self.historyItems = []
        }
    }
    
    /// Non-blocking background save off @MainActor
    private func saveAsync() {
        let itemsCopy = self.historyItems
        let url = self.fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(itemsCopy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save history off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
