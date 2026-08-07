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
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("session.json")
        
        let previous = loadPreviousSession()
        if let prev = previous, !prev.tabs.isEmpty {
            self.hasRecoverableSession = true
            self.lastSavedSession = prev
        }
    }
    
    private var pendingSaveTask: Task<Void, Never>? = nil
    
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
        
        // Debounce: Cancel previous pending save and schedule new save after 500ms
        pendingSaveTask?.cancel()
        pendingSaveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            try? await DiskStorageActor.shared.write(session, to: url)
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
        Task {
            await DiskStorageActor.shared.delete(at: url)
        }
        hasRecoverableSession = false
        lastSavedSession = nil
    }
}
