import Foundation

/// Persistent store managing reading list items and read/unread status.
@MainActor
public final class ReadingListManager: ObservableObject {
    @Published public private(set) var items: [ReadingItem] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("reading_list.json")
        load()
    }
    
    public func items(for profileID: UUID) -> [ReadingItem] {
        return items.filter { $0.profileID == profileID }
    }
    
    public func addItem(title: String, urlString: String, profileID: UUID) {
        guard !urlString.isEmpty else { return }
        let newTitle = title.isEmpty ? urlString : title
        let item = ReadingItem(title: newTitle, urlString: urlString, profileID: profileID)
        items.insert(item, at: 0)
        save()
    }
    
    public func toggleReadStatus(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isRead.toggle()
        save()
    }
    
    public func removeItem(id: UUID) {
        items.removeAll(where: { $0.id == id })
        save()
    }
    
    public func search(query: String, profileID: UUID) -> [ReadingItem] {
        let profileItems = items(for: profileID)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return profileItems }
        return profileItems.filter {
            $0.title.lowercased().contains(trimmed) || $0.urlString.lowercased().contains(trimmed)
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([ReadingItem].self, from: data)
            self.items = items
        } catch {
            self.items = []
        }
    }
    
    private func save() {
        let copy = items
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save reading list off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
