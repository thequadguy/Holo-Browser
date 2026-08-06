import Foundation

/// Per-extension isolated storage provider. Extensions cannot access main filesystem or other extensions' data.
@MainActor
public final class ExtensionStorage {
    private let storageFolder: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        self.storageFolder = holoFolder.appendingPathComponent("extensions_storage", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageFolder, withIntermediateDirectories: true)
    }
    
    private func fileURL(for extensionID: UUID) -> URL {
        return storageFolder.appendingPathComponent("\(extensionID.uuidString).json")
    }
    
    public func setValue(_ value: String, forKey key: String, extensionID: UUID) {
        var dict = loadDict(for: extensionID)
        dict[key] = value
        saveDict(dict, for: extensionID)
    }
    
    public func getValue(forKey key: String, extensionID: UUID) -> String? {
        let dict = loadDict(for: extensionID)
        return dict[key]
    }
    
    public func removeStorage(for extensionID: UUID) {
        let url = fileURL(for: extensionID)
        try? FileManager.default.removeItem(at: url)
    }
    
    private func loadDict(for extensionID: UUID) -> [String: String] {
        let url = fileURL(for: extensionID)
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            return [:]
        }
    }
    
    private func saveDict(_ dict: [String: String], for extensionID: UUID) {
        let url = fileURL(for: extensionID)
        let copy = dict
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save extension storage off-main-thread: \(error.localizedDescription)")
            }
        }
    }

}
