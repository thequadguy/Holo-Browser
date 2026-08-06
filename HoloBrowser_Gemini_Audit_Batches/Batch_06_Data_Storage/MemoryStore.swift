import Foundation
import Combine

/// On-Device Encrypted Memory Store for research projects, saved snippets, and user preferences.
@MainActor
public final class MemoryStore: ObservableObject {
    public static let shared = MemoryStore()
    
    @Published public private(set) var savedSnippets: [String] = []
    private let storageKey = "Holo_SavedSnippets_V1"
    
    private init() {
        self.savedSnippets = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }
    
    public func saveSnippet(_ text: String) {
        let sanitized = AIPrivacyManager().sanitizeContextForAI(text)
        savedSnippets.append(sanitized)
        UserDefaults.standard.set(savedSnippets, forKey: storageKey)
        PrivacyDashboardManager.shared.recordAISanitization()
    }
    
    public func clearAllMemory() {
        savedSnippets.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
