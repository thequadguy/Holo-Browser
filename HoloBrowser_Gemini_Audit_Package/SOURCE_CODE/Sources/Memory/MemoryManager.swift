import Foundation

/// Persistent store managing local browser memory and semantic page summaries.
@MainActor
public final class MemoryManager: ObservableObject {
    @Published public private(set) var memories: [VisitedPageMemory] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("memory.json")
        load()
    }
    
    public func savePageSummary(title: String, urlString: String, summary: String) {
        guard !urlString.isEmpty else { return }
        let memory = VisitedPageMemory(title: title, urlString: urlString, summary: summary)
        memories.removeAll(where: { $0.urlString == urlString })
        memories.insert(memory, at: 0)
        save()
    }
    
    public func search(query: String) -> [VisitedPageMemory] {
        return MemorySearch.search(query, in: memories)
    }
    
    public func clearAll() {
        memories.removeAll()
        save()
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([VisitedPageMemory].self, from: data)
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
                print("Failed to save memory off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
