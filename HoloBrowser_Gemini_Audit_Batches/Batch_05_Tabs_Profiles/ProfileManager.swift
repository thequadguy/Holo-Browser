import Foundation
import WebKit
import Combine

/// Main-actor observable manager orchestrating browser profiles and WKWebsiteDataStore data isolation.
@MainActor
public final class ProfileManager: ObservableObject {
    @Published public private(set) var profiles: [BrowserProfile] = []
    @Published public private(set) var activeProfile: BrowserProfile
    
    private let storage = ProfileStorage()
    private var dataStoreMap: [UUID: WKWebsiteDataStore] = [:]
    
    public init() {
        let loaded = storage.loadProfiles()
        self.profiles = loaded
        let initial = loaded.first ?? BrowserProfile(name: "Personal", colorHex: "#007AFF")
        self.activeProfile = initial
    }
    
    /// Returns the isolated WKWebsiteDataStore instance for the specified profile.
    public func websiteDataStore(for profile: BrowserProfile) -> WKWebsiteDataStore {
        if let existing = dataStoreMap[profile.id] {
            return existing
        }
        
        let store: WKWebsiteDataStore
        if profile.isPrivate {
            store = .nonPersistent()
        } else {
            if #available(macOS 14.0, *) {
                store = WKWebsiteDataStore(forIdentifier: profile.id)
            } else {
                store = .default()
            }
        }
        
        dataStoreMap[profile.id] = store
        return store
    }
    
    /// Returns the isolated WKWebsiteDataStore instance for the specified profile ID.
    public func websiteDataStore(for profileID: UUID) -> WKWebsiteDataStore? {
        guard let profile = profiles.first(where: { $0.id == profileID }) else { return nil }
        return websiteDataStore(for: profile)
    }
    
    /// Returns the data store for active profile.
    public var activeWebsiteDataStore: WKWebsiteDataStore {
        return websiteDataStore(for: activeProfile)
    }

    
    /// Creates and persists a new browser profile.
    @discardableResult
    public func createProfile(name: String, colorHex: String = "#007AFF", isPrivate: Bool = false) -> BrowserProfile {
        let profile = BrowserProfile(name: name, colorHex: colorHex, isPrivate: isPrivate)
        profiles.append(profile)
        storage.saveProfiles(profiles)
        selectProfile(id: profile.id)
        return profile
    }
    
    /// Switches the active profile.
    public func selectProfile(id: UUID) {
        guard let target = profiles.first(where: { $0.id == id }) else { return }
        var updatedTarget = target
        updatedTarget.lastUsedDate = Date()
        
        if let idx = profiles.firstIndex(where: { $0.id == id }) {
            profiles[idx] = updatedTarget
        }
        
        activeProfile = updatedTarget
        storage.saveProfiles(profiles)
    }
    
    /// Deletes a profile and clears its isolated data store.
    public func deleteProfile(id: UUID) {
        guard profiles.count > 1 else { return } // Keep at least 1 profile
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        
        let target = profiles[index]
        profiles.remove(at: index)
        dataStoreMap.removeValue(forKey: target.id)
        storage.saveProfiles(profiles)
        
        if activeProfile.id == id, let first = profiles.first {
            selectProfile(id: first.id)
        }
    }
}
