import Foundation

/// Main-actor manager coordinating personal memory persistence (`personal_memory.json`) and cross-system intelligence.
@MainActor
public final class BrowserIntelligenceManager: ObservableObject {
    @Published public private(set) var memories: [PersonalMemory] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("personal_memory.json")
        load()
    }
    
    public func addMemory(category: MemoryCategory, content: String, profileID: UUID, isPrivate: Bool) {
        guard MemoryPrivacyManager.isSafeToStore(content: content, isPrivate: isPrivate) else { return }
        let mem = PersonalMemory(category: category, content: content, profileID: profileID)
        memories.insert(mem, at: 0)
        save()
    }
    
    public func deleteMemory(id: UUID) {
        memories.removeAll(where: { $0.id == id })
        save()
    }
    
    public func clearAll(for profileID: UUID) {
        memories.removeAll(where: { $0.profileID == profileID })
        save()
    }
    
    public func memories(for profileID: UUID) -> [PersonalMemory] {
        return memories.filter { $0.profileID == profileID }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([PersonalMemory].self, from: data)
            self.memories = items
        } catch {
            self.memories = []
        }
    }
    
    private func save() {
        let copy = memories
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save personal memories off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
