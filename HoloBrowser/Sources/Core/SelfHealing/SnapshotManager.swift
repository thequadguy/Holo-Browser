import Foundation

public struct RecoverySnapshot: Identifiable, Codable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let label: String
    public let appVersion: String
    public let historyCount: Int
    public let bookmarkCount: Int
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), label: String, appVersion: String, historyCount: Int, bookmarkCount: Int) {
        self.id = id
        self.timestamp = timestamp
        self.label = label
        self.appVersion = appVersion
        self.historyCount = historyCount
        self.bookmarkCount = bookmarkCount
    }
}

/// `@MainActor` snapshot manager creating atomic state backups and restoring safe states.
@MainActor
public final class SnapshotManager: ObservableObject {
    public static let shared = SnapshotManager()
    
    @Published public private(set) var availableSnapshots: [RecoverySnapshot] = []
    
    private let snapshotsFolder: URL
    private let maxSnapshots = 5
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        self.snapshotsFolder = holoFolder.appendingPathComponent("Snapshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: snapshotsFolder, withIntermediateDirectories: true)
        loadSnapshotsIndex()
    }
    
    /// Creates an atomic snapshot backup of current browser state.
    @discardableResult
    public func createSnapshot(label: String = "Manual Recovery Point") -> RecoverySnapshot {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        
        let snapshotID = UUID()
        let snapshotDir = snapshotsFolder.appendingPathComponent(snapshotID.uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: snapshotDir, withIntermediateDirectories: true)
        
        let filesToCopy = ["session.json", "history.json", "bookmarks.json", "profiles.json"]
        var historyCount = 0
        var bookmarkCount = 0
        
        for file in filesToCopy {
            let src = holoFolder.appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: src.path) {
                let dst = snapshotDir.appendingPathComponent(file)
                try? FileManager.default.copyItem(at: src, to: dst)
                
                if file == "history.json", let data = try? Data(contentsOf: src), let items = try? JSONDecoder().decode([HistoryItem].self, from: data) {
                    historyCount = items.count
                }
                if file == "bookmarks.json", let data = try? Data(contentsOf: src), let items = try? JSONDecoder().decode([BookmarkItem].self, from: data) {
                    bookmarkCount = items.count
                }
            }
        }
        
        let snapshot = RecoverySnapshot(
            id: snapshotID,
            timestamp: Date(),
            label: label,
            appVersion: BuildConfiguration.appVersion,
            historyCount: historyCount,
            bookmarkCount: bookmarkCount
        )
        
        availableSnapshots.insert(snapshot, at: 0)
        
        // Enforce max 5 snapshots
        if availableSnapshots.count > maxSnapshots {
            let removed = availableSnapshots.suffix(from: maxSnapshots)
            for oldSnap in removed {
                let oldDir = snapshotsFolder.appendingPathComponent(oldSnap.id.uuidString)
                try? FileManager.default.removeItem(at: oldDir)
            }
            availableSnapshots = Array(availableSnapshots.prefix(maxSnapshots))
        }
        
        saveSnapshotsIndex()
        return snapshot
    }
    
    /// Restores browser state from a specific snapshot.
    public func restoreSnapshot(id: UUID) -> Bool {
        guard let snap = availableSnapshots.first(where: { $0.id == id }) else { return false }
        let snapshotDir = snapshotsFolder.appendingPathComponent(snap.id.uuidString, isDirectory: true)
        guard FileManager.default.fileExists(atPath: snapshotDir.path) else { return false }
        
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        
        let filesToRestore = ["session.json", "history.json", "bookmarks.json", "profiles.json"]
        for file in filesToRestore {
            let src = snapshotDir.appendingPathComponent(file)
            let dst = holoFolder.appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: src.path) {
                try? FileManager.default.removeItem(at: dst)
                try? FileManager.default.copyItem(at: src, to: dst)
            }
        }
        return true
    }
    
    private func loadSnapshotsIndex() {
        let indexFile = snapshotsFolder.appendingPathComponent("snapshots_index.json")
        guard FileManager.default.fileExists(atPath: indexFile.path),
              let data = try? Data(contentsOf: indexFile),
              let list = try? JSONDecoder().decode([RecoverySnapshot].self, from: data) else {
            self.availableSnapshots = []
            return
        }
        self.availableSnapshots = list
    }
    
    private func saveSnapshotsIndex() {
        let indexFile = snapshotsFolder.appendingPathComponent("snapshots_index.json")
        let listCopy = self.availableSnapshots
        Task {
            try? await DiskStorageActor.shared.write(listCopy, to: indexFile)
        }
    }
}
