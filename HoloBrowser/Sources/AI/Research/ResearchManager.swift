import Foundation

/// Main-actor persistent manager managing research sessions (`research_sessions.json`).
@MainActor
public final class ResearchManager: ObservableObject {
    @Published public private(set) var sessions: [ResearchSession] = []
    @Published public var activeSessionID: UUID?
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("research_sessions.json")
        load()
    }
    
    public var activeSession: ResearchSession? {
        guard let id = activeSessionID else { return sessions.first }
        return sessions.first(where: { $0.id == id })
    }
    
    @discardableResult
    public func createSession(title: String, topic: String, profileID: UUID, isPrivate: Bool) -> ResearchSession? {
        guard !isPrivate else { return nil }
        let session = ResearchSession(title: title.isEmpty ? "New Research" : title, topic: topic, profileID: profileID)
        sessions.insert(session, at: 0)
        activeSessionID = session.id
        save()
        return session
    }
    
    public func addSourceToActiveSession(_ source: ResearchSource, isPrivate: Bool) {
        guard !isPrivate, let id = activeSessionID, let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        // Duplicate detection
        if !sessions[idx].sources.contains(where: { $0.urlString == source.urlString }) {
            sessions[idx].sources.append(source)
            save()
        }
    }
    
    /// Evaluates quality score of a source based on length and structure (0-100).
    public func scoreSourceQuality(_ source: ResearchSource) -> Int {
        var score = 50
        if source.summary.count > 100 { score += 20 }
        if source.urlString.hasPrefix("https://") { score += 15 }
        if !source.title.isEmpty && source.title != source.urlString { score += 15 }
        return min(score, 100)
    }
    
    /// Generates structured key-value comparison table across sources.
    public func generateComparisonTable(for session: ResearchSession) -> [String: String] {
        var table: [String: String] = [:]
        for (idx, source) in session.sources.enumerated() {
            table["Source \(idx + 1)"] = "\(source.title) (Quality: \(scoreSourceQuality(source))%)"
        }
        return table
    }
    
    public func addNoteToActiveSession(title: String, content: String, isAIGenerated: Bool = false, isPrivate: Bool) {
        guard !isPrivate, let id = activeSessionID, let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        let note = ResearchNote(title: title, content: content, isAIGenerated: isAIGenerated)
        sessions[idx].notes.append(note)
        save()
    }
    
    public func deleteSession(id: UUID) {
        sessions.removeAll(where: { $0.id == id })
        if activeSessionID == id {
            activeSessionID = sessions.first?.id
        }
        save()
    }
    
    public func exportSessionAsMarkdown(_ session: ResearchSession) -> String {
        var md = "# Research Topic: \(session.topic)\n\n"
        md += "Created: \(session.creationDate.formatted())\n\n"
        
        md += "## Sources (\(session.sources.count))\n\n"
        for src in session.sources {
            let score = scoreSourceQuality(src)
            md += "- [\(src.title)](\(src.urlString)) (Quality Score: \(score)%)\n"
            md += "  - Summary: \(src.summary)\n\n"
        }
        
        md += "## Notes (\(session.notes.count))\n\n"
        for note in session.notes {
            md += "### \(note.title)\n\(note.content)\n\n"
        }
        
        return md
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([ResearchSession].self, from: data)
            self.sessions = items
            self.activeSessionID = items.first?.id
        } catch {
            self.sessions = []
        }
    }
    
    private func save() {
        let copy = sessions
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save research sessions off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
