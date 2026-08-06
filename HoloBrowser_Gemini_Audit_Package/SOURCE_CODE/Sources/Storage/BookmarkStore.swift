import Foundation

/// Data model representing a bookmark entry.
public struct BookmarkItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let title: String
    public let urlString: String
    public let dateAdded: Date
    
    public init(id: UUID = UUID(), title: String, urlString: String, dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.dateAdded = dateAdded
    }
}

/// Local JSON persistence store for bookmarks with non-blocking background I/O.
@MainActor
public final class BookmarkStore: ObservableObject {
    @Published public private(set) var bookmarks: [BookmarkItem] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("bookmarks.json")
        load()
    }
    
    /// Adds a bookmark.
    public func addBookmark(title: String, urlString: String) {
        guard !isBookmarked(urlString: urlString) else { return }
        let displayTitle = title.isEmpty ? urlString : title
        let item = BookmarkItem(title: displayTitle, urlString: urlString)
        bookmarks.insert(item, at: 0)
        saveAsync()
    }
    
    /// Removes a bookmark by ID.
    public func removeBookmark(id: UUID) {
        bookmarks.removeAll(where: { $0.id == id })
        saveAsync()
    }
    
    /// Checks if a URL string is bookmarked.
    public func isBookmarked(urlString: String) -> Bool {
        return bookmarks.contains(where: { $0.urlString == urlString })
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([BookmarkItem].self, from: data)
            self.bookmarks = items
        } catch {
            self.bookmarks = []
        }
    }
    
    private func saveAsync() {
        let itemsCopy = self.bookmarks
        let url = self.fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(itemsCopy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save bookmarks off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
