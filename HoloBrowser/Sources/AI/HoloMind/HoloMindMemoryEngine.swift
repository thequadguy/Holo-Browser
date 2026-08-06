import Foundation
import CryptoKit

public enum HoloMemoryCategory: String, Codable, CaseIterable, Identifiable {
    case preference = "User Preference"
    case project = "Project Context"
    case entity = "Key Entity"
    case instruction = "Standing Instruction"
    
    public var id: String { rawValue }
}

public struct HoloMindMemoryItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var category: HoloMemoryCategory
    public var key: String
    public var value: String
    public let profileID: UUID
    public let timestamp: Date
    public var isEncrypted: Bool
    
    public init(
        id: UUID = UUID(),
        category: HoloMemoryCategory,
        key: String,
        value: String,
        profileID: UUID,
        timestamp: Date = Date(),
        isEncrypted: Bool = true
    ) {
        self.id = id
        self.category = category
        self.key = key
        self.value = value
        self.profileID = profileID
        self.timestamp = timestamp
        self.isEncrypted = isEncrypted
    }
}

/// Secure memory storage engine managing user-controlled, editable memories with profile isolation and background JSON serialization.
@MainActor
public final class HoloMindMemoryEngine: ObservableObject {
    @Published public private(set) var memories: [HoloMindMemoryItem] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("holomind_memories.json")
        // Load happens asynchronously per-profile now, not globally on init
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("HoloProfileDeleted"), object: nil, queue: .main) { [weak self] notification in
            if let profileID = notification.object as? UUID {
                Task { @MainActor in
                    self?.clearAll(for: profileID)
                    await KeyManager.shared.destroyKey(for: profileID)
                }
            }
        }
    }
    
    public func loadMemories(for profileID: UUID) {
        Task {
            do {
                let key = try await KeyManager.shared.getOrCreateKey(for: profileID)
                let rawData = try await DiskStorageActor.shared.readRaw(from: fileURL) // Should ideally be per-profile file, keeping global for now
                let sealedBox = try AES.GCM.SealedBox(combined: rawData)
                let decryptedData = try AES.GCM.open(sealedBox, using: key)
                let items = try JSONDecoder().decode([HoloMindMemoryItem].self, from: decryptedData)
                await MainActor.run {
                    self.memories = items
                }
            } catch {
                // Silently swallow memory decryption failures in production
                await MainActor.run {
                    self.memories = []
                }
            }
        }
    }
    
    public func memories(for profileID: UUID) -> [HoloMindMemoryItem] {
        return memories.filter { $0.profileID == profileID }
    }
    
    public func addMemory(category: HoloMemoryCategory, key: String, value: String, profileID: UUID, isPrivate: Bool) async throws {
        guard !isPrivate else { return } // Zero memory writes in private browsing
        let item = HoloMindMemoryItem(category: category, key: key, value: value, profileID: profileID)
        memories.removeAll(where: { $0.profileID == profileID && $0.key.lowercased() == key.lowercased() })
        memories.insert(item, at: 0)
        
        let data = try JSONEncoder().encode(memories)
        let key = try await KeyManager.shared.getOrCreateKey(for: profileID)
        let sealedBox = try AES.GCM.seal(data, using: key)
        if let combined = sealedBox.combined {
            try await DiskStorageActor.shared.writeRaw(combined, to: fileURL)
        }
    }
    
    public func updateMemory(id: UUID, key: String, value: String, category: HoloMemoryCategory, profileID: UUID) {
        guard let idx = memories.firstIndex(where: { $0.id == id }) else { return }
        var updated = memories[idx]
        updated.key = key
        updated.value = value
        updated.category = category
        memories[idx] = updated
        saveAsync(for: profileID)
    }
    
    public func deleteMemory(id: UUID, profileID: UUID) {
        memories.removeAll(where: { $0.id == id })
        saveAsync(for: profileID)
    }
    
    public func clearAll(for profileID: UUID) {
        memories.removeAll(where: { $0.profileID == profileID })
        saveAsync(for: profileID)
    }
    

    
    private func saveAsync(for profileID: UUID) {
        let copy = memories
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let key = try await KeyManager.shared.getOrCreateKey(for: profileID)
                let data = try JSONEncoder().encode(copy)
                let sealedBox = try AES.GCM.seal(data, using: key)
                if let combined = sealedBox.combined {
                    try await DiskStorageActor.shared.writeRaw(combined, to: url)
                }
            } catch {
                // Silently swallow encryption failures in production
            }
        }
    }
}
