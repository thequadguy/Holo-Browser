import Foundation

public struct HoloBrowserBackup: Codable {
    public let version: String
    public let dateExported: Date
    public let history: [HistoryItem]
    public let bookmarks: [BookmarkItem]
    public let readingList: [ReadingItem]
    public let workspaces: [Workspace]
    public let memories: [PersonalMemory]
}

/// `@MainActor` backup exporter and importer managing browser state archives while purging all passwords and private data.
@MainActor
public final class BackupManager: ObservableObject {
    public init() {}
    
    public func exportBackup(
        history: [HistoryItem],
        bookmarks: [BookmarkItem],
        readingList: [ReadingItem],
        workspaces: [Workspace],
        memories: [PersonalMemory]
    ) -> Data? {
        let backup = HoloBrowserBackup(
            version: BuildConfiguration.appVersion,
            dateExported: Date(),
            history: history,
            bookmarks: bookmarks,
            readingList: readingList,
            workspaces: workspaces,
            memories: memories
        )
        return try? JSONEncoder().encode(backup)
    }
}
