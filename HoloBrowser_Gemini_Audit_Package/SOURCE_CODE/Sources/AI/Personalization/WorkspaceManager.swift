import Foundation

/// Main-actor persistent manager managing workspaces/projects (`workspaces.json`).
@MainActor
public final class WorkspaceManager: ObservableObject {
    @Published public private(set) var workspaces: [Workspace] = []
    @Published public var activeWorkspaceID: UUID?
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("workspaces.json")
        load()
    }
    
    public var activeWorkspace: Workspace? {
        guard let id = activeWorkspaceID else { return workspaces.first }
        return workspaces.first(where: { $0.id == id })
    }
    
    @discardableResult
    public func createWorkspace(name: String, iconName: String = "folder", profileID: UUID, isPrivate: Bool) -> Workspace? {
        guard !isPrivate else { return nil }
        let ws = Workspace(name: name.isEmpty ? "New Workspace" : name, iconName: iconName, profileID: profileID)
        workspaces.insert(ws, at: 0)
        activeWorkspaceID = ws.id
        save()
        return ws
    }
    
    public func deleteWorkspace(id: UUID) {
        workspaces.removeAll(where: { $0.id == id })
        if activeWorkspaceID == id {
            activeWorkspaceID = workspaces.first?.id
        }
        save()
    }
    
    public func workspaces(for profileID: UUID) -> [Workspace] {
        return workspaces.filter { $0.profileID == profileID }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([Workspace].self, from: data)
            self.workspaces = items
            self.activeWorkspaceID = items.first?.id
        } catch {
            self.workspaces = []
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(workspaces)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save workspaces: \(error.localizedDescription)")
        }
    }
}
