import Foundation

/// On-device privacy-safe context retriever for Holo Browser Memory System.
/// Retrieves research notes, workspace summaries, and saved page titles without exposing passwords or sensitive history.
@MainActor
public final class ContextRetriever: ObservableObject {
    public static let shared = ContextRetriever()
    
    private init() {}
    
    /// Retrieves relevant research notes matching a natural language topic.
    public func retrieveRelevantNotes(topic: String, notes: [String]) -> [String] {
        let lowerTopic = topic.lowercased()
        return notes.filter { note in
            let lowerNote = note.lowercased()
            // Defensively skip any note containing sensitive tokens
            if lowerNote.contains("password") || lowerNote.contains("secret") || lowerNote.contains("token") {
                return false
            }
            return lowerNote.contains(lowerTopic)
        }
    }
}
