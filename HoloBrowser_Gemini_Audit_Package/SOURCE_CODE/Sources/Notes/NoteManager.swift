import Foundation

/// Persistent store managing webpage notes and annotations.
@MainActor
public final class NoteManager: ObservableObject {
    @Published public private(set) var notes: [Note] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("notes.json")
        load()
    }
    
    public func addNote(pageTitle: String, urlString: String, content: String, annotations: [Annotation] = []) {
        let note = Note(pageTitle: pageTitle, urlString: urlString, content: content, annotations: annotations)
        notes.insert(note, at: 0)
        save()
    }
    
    public func deleteNote(id: UUID) {
        notes.removeAll(where: { $0.id == id })
        save()
    }
    
    public func searchNotes(query: String) -> [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return notes }
        return notes.filter {
            $0.pageTitle.lowercased().contains(trimmed) ||
            $0.content.lowercased().contains(trimmed) ||
            $0.urlString.lowercased().contains(trimmed)
        }
    }
    
    public func exportMarkdown(_ note: Note) -> String {
        var md = "# Note: \(note.pageTitle)\n"
        md += "**URL**: [\(note.urlString)](\(note.urlString))\n"
        md += "**Date**: \(note.timestamp.formatted())\n\n"
        md += "## Content\n\(note.content)\n\n"
        if !note.annotations.isEmpty {
            md += "## Highlights & Annotations\n"
            for ann in note.annotations {
                md += "> \"\(ann.highlightedText)\"\n"
                if !ann.comment.isEmpty {
                    md += "*Note: \(ann.comment)*\n"
                }
                md += "\n"
            }
        }
        return md
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([Note].self, from: data)
            self.notes = items
        } catch {
            self.notes = []
        }
    }
    
    private func save() {
        let copy = notes
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save notes off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
