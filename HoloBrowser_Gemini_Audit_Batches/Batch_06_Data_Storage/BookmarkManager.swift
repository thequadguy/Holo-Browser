import Foundation

/// Persistent store managing bookmark folders and bookmarks hierarchy with non-blocking disk I/O.
@MainActor
public final class BookmarkManager: ObservableObject {
    @Published public private(set) var folders: [BookmarkFolder] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("bookmark_folders.json")
        load()
    }
    
    public func createFolder(name: String, parentID: UUID? = nil) -> BookmarkFolder {
        let folder = BookmarkFolder(name: name, parentID: parentID)
        folders.append(folder)
        saveAsync()
        return folder
    }
    
    public func deleteFolder(id: UUID) {
        folders.removeAll(where: { $0.id == id })
        saveAsync()
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let favorites = BookmarkFolder(name: "Favorites Bar")
            folders = [favorites]
            saveAsync()
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([BookmarkFolder].self, from: data)
            self.folders = items
        } catch {
            self.folders = []
        }
    }
    
    private func saveAsync() {
        let foldersCopy = self.folders
        let url = self.fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(foldersCopy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save bookmark folders off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
