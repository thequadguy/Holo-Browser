import Foundation
import Combine

/// Main-actor manager preserving open window sessions and crash recovery state with non-blocking disk I/O.
@MainActor
public final class SessionManager: ObservableObject {
    @Published public private(set) var hasRecoverableSession: Bool = false
    @Published public var showRecoveryPrompt: Bool = false
    
    private let fileURL: URL
    private var lastSavedSession: Session? = nil
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("session.json")
        
        let previous = loadPreviousSession()
        if let prev = previous, !prev.tabs.isEmpty {
            self.hasRecoverableSession = true
            self.lastSavedSession = prev
        }
    }
    
    public func saveActiveSession(tabs: [Tab], activeTabIndex: Int, profileID: UUID, isPrivate: Bool) {
        guard !isPrivate else { return } // Never save private sessions
        
        let savedItems = tabs.map { tab -> SavedTabItem in
            return SavedTabItem(
                urlString: tab.url?.absoluteString ?? "about:blank",
                title: tab.title,
                isPinned: tab.isPinned
            )
        }
        
        let session = Session(
            profileID: profileID,
            tabs: savedItems,
            activeTabIndex: activeTabIndex,
            isPrivate: false
        )
        
        self.lastSavedSession = session
        let url = self.fileURL
        
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(session)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save session off-main-thread: \(error.localizedDescription)")
            }
        }
    }
    
    public func loadPreviousSession() -> Session? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(Session.self, from: data)
        } catch {
            return nil
        }
    }
    
    public func clearSavedSession() {
        let url = self.fileURL
        Task.detached(priority: .utility) {
            try? FileManager.default.removeItem(at: url)
        }
        hasRecoverableSession = false
        lastSavedSession = nil
    }
}
