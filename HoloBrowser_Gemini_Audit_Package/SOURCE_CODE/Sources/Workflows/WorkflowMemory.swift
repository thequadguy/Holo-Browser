import Foundation

/// Persistent store managing workflow records (`workflows.json`) with profile isolation & private mode exclusion.
@MainActor
public final class WorkflowMemory: ObservableObject {
    @Published public private(set) var workflows: [Workflow] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("workflows.json")
        load()
    }
    
    public func saveWorkflow(_ workflow: Workflow, isPrivate: Bool) {
        guard !isPrivate else { return }
        workflows.removeAll(where: { $0.id == workflow.id })
        workflows.insert(workflow, at: 0)
        save()
    }
    
    public func deleteWorkflow(id: UUID) {
        workflows.removeAll(where: { $0.id == id })
        save()
    }
    
    public func workflows(for profileID: UUID) -> [Workflow] {
        return workflows.filter { $0.profileID == profileID }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([Workflow].self, from: data)
            self.workflows = items
        } catch {
            self.workflows = []
        }
    }
    
    private func save() {
        let copy = workflows
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save workflows off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
