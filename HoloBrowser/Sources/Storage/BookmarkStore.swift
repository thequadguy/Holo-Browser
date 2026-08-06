import Foundation

/// Local JSON persistence store for bookmarks with non-blocking background I/O.
@MainActor
public final class BookmarkStore: ObservableObject {
    @Published public private(set) var bookmarks: [BookmarkItem] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
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
        Task { @MainActor in
            self.bookmarks = await SafeJSONDecoder.decodeWithFallbackAsync([BookmarkItem].self, from: fileURL, fallback: [])
        }
    }
    
    private func saveAsync() {
        let itemsCopy = self.bookmarks
        let url = self.fileURL
        Task {
            try? await DiskStorageActor.shared.write(itemsCopy, to: url)
        }
    }
}
