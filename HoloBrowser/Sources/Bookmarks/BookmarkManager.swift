import Foundation

/// Persistent store managing bookmark items, folders, and hierarchy with non-blocking disk I/O.
@MainActor
public final class BookmarkManager: ObservableObject {
    @Published public private(set) var bookmarks: [BookmarkItem] = []
    @Published public private(set) var folders: [BookmarkFolder] = []
    
    private let bookmarksFileURL: URL
    private let foldersFileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.bookmarksFileURL = holoFolder.appendingPathComponent("bookmarks.json")
        self.foldersFileURL = holoFolder.appendingPathComponent("bookmark_folders.json")
        load()
    }
    
    public func createFolder(name: String, parentID: UUID? = nil) -> BookmarkFolder {
        let folder = BookmarkFolder(name: name, parentID: parentID)
        folders.append(folder)
        saveAsync()
        return folder
    }
    
    @discardableResult
    public func addBookmark(
        title: String,
        url: URL,
        folderName: String = "Favorites Bar",
        isFavorite: Bool = false
    ) -> BookmarkItem {
        let targetFolderName = folderName.isEmpty ? "Favorites Bar" : folderName
        var folder = folders.first(where: { $0.name.lowercased() == targetFolderName.lowercased() })
        if folder == nil {
            folder = createFolder(name: targetFolderName)
        }
        
        let item = BookmarkItem(
            title: title.isEmpty ? url.absoluteString : title,
            urlString: url.absoluteString,
            folderID: folder?.id,
            isFavorite: isFavorite
        )
        
        // Prevent duplicate URL additions in the same folder
        bookmarks.removeAll(where: { $0.urlString == item.urlString && $0.folderID == item.folderID })
        bookmarks.insert(item, at: 0)
        
        if let folderID = folder?.id, let idx = folders.firstIndex(where: { $0.id == folderID }) {
            if !folders[idx].bookmarkIDs.contains(item.id) {
                folders[idx].bookmarkIDs.append(item.id)
            }
        }
        
        saveAsync()
        return item
    }
    
    public func deleteBookmark(id: UUID) {
        bookmarks.removeAll(where: { $0.id == id })
        for idx in folders.indices {
            folders[idx].bookmarkIDs.removeAll(where: { $0 == id })
        }
        saveAsync()
    }
    
    public func toggleFavorite(id: UUID) {
        if let idx = bookmarks.firstIndex(where: { $0.id == id }) {
            bookmarks[idx].isFavorite.toggle()
            saveAsync()
        }
    }
    
    public func deleteFolder(id: UUID) {
        folders.removeAll(where: { $0.id == id })
        bookmarks.removeAll(where: { $0.folderID == id })
        saveAsync()
    }
    
    public func searchBookmarks(query: String) -> [BookmarkItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return bookmarks }
        return bookmarks.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.urlString.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    public var favoriteBookmarks: [BookmarkItem] {
        return bookmarks.filter { $0.isFavorite }
    }
    
    private func load() {
        Task { @MainActor in
            let defaultFolders = [BookmarkFolder(name: "Favorites Bar"), BookmarkFolder(name: "Imported")]
            self.folders = await SafeJSONDecoder.decodeWithFallbackAsync([BookmarkFolder].self, from: foldersFileURL, fallback: defaultFolders)
            self.bookmarks = await SafeJSONDecoder.decodeWithFallbackAsync([BookmarkItem].self, from: bookmarksFileURL, fallback: [])
        }
    }
    
    private var saveTask: Task<Void, Never>?
    
    private func saveAsync() {
        saveTask?.cancel()
        let bookmarksCopy = self.bookmarks
        let foldersCopy = self.folders
        let bURL = self.bookmarksFileURL
        let fURL = self.foldersFileURL
        
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            try? await DiskStorageActor.shared.write(bookmarksCopy, to: bURL)
            try? await DiskStorageActor.shared.write(foldersCopy, to: fURL)
        }
    }
}
