import Foundation

/// Main-actor manager coordinating personal memory persistence (`personal_memory.json`) and cross-system intelligence.
@MainActor
public final class BrowserIntelligenceManager: ObservableObject {
    @Published public private(set) var memories: [PersonalMemory] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("personal_memory.json")
        loadAsync()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("HoloProfileDeleted"), object: nil, queue: .main) { [weak self] notification in
            if let profileID = notification.object as? UUID {
                Task { @MainActor in
                    self?.clearAll(for: profileID)
                }
            }
        }
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
    
    private func loadAsync() {
        Task {
            do {
                let data = try await DiskStorageActor.shared.readRaw(from: fileURL)
                let items = try JSONDecoder().decode([PersonalMemory].self, from: data)
                    await MainActor.run {
                    self.memories = items
                }
            } catch {
                await MainActor.run {
                    self.memories = []
                }
            }
        }
    }
    
    private func save() {
        let copy = memories
        let url = fileURL
        Task {
            do {
                try await DiskStorageActor.shared.write(copy, to: url)
            } catch {
                print("Failed to save personal memories off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
