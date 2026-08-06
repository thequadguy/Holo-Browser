import Foundation

/// Persistent JSON file storage managing installed extension metadata index.
@MainActor
public final class ExtensionRegistry {
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("extensions_registry.json")
    }
    
    public func loadExtensions() -> [Extension] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // Default sample extensions
            let sampleScript = Extension(
                name: "Dark Canvas Stylizer",
                version: "1.0.0",
                author: "Holo Labs",
                enabled: true,
                type: .userScript,
                permissions: [.scriptInjection, .websiteAccess],
                userScriptSource: "document.body.style.filter = 'contrast(1.05)';"
            )
            saveExtensions([sampleScript])
            return [sampleScript]
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Extension].self, from: data)
        } catch {
            return []
        }
    }
    
    public func saveExtensions(_ extensions: [Extension]) {
        let copy = extensions
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save extensions registry off-main-thread: \(error.localizedDescription)")
            }
        }
    }

}
