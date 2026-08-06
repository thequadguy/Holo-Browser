import Foundation

/// Persistent JSON file storage for browser profiles metadata with non-blocking disk I/O.
@MainActor
public final class ProfileStorage {
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("profiles.json")
    }
    
    public func loadProfiles() -> [BrowserProfile] {
        let loaded = SafeJSONDecoder.decodeWithFallbackSync([BrowserProfile].self, from: fileURL, fallback: [])
        if loaded.isEmpty {
            let defaultProfile = BrowserProfile(id: UUID(), name: "Personal", colorHex: "#007AFF")
            saveProfiles([defaultProfile])
            return [defaultProfile]
        }
        return loaded
    }
    
    public func saveProfiles(_ profiles: [BrowserProfile]) {
        let copy = profiles
        let url = fileURL
        Task {
            try? await DiskStorageActor.shared.write(copy, to: url)
        }
    }
}
