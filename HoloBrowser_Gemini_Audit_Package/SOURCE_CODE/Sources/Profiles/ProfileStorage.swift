import Foundation

/// Persistent JSON file storage for browser profiles metadata with non-blocking disk I/O.
@MainActor
public final class ProfileStorage {
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("profiles.json")
    }
    
    public func loadProfiles() -> [BrowserProfile] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let defaultProfile = BrowserProfile(id: UUID(), name: "Personal", colorHex: "#007AFF")
            saveProfiles([defaultProfile])
            return [defaultProfile]
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([BrowserProfile].self, from: data)
        } catch {
            let defaultProfile = BrowserProfile(id: UUID(), name: "Personal", colorHex: "#007AFF")
            return [defaultProfile]
        }
    }
    
    public func saveProfiles(_ profiles: [BrowserProfile]) {
        let copy = profiles
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save profiles off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
