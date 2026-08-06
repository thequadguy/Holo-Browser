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
        let initial = loaded.first ?? BrowserProfile(name: "Personal", colorHex: "#007AFF", iconName: "person.fill", purpose: .personal)
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
                // Strict isolation requirement
                NotificationCenter.default.post(name: NSNotification.Name("HoloSecurityAlert"), object: "Full profile isolation requires macOS 14+. Falling back to isolated non-persistent stores.")
                store = .nonPersistent()
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
    
    /// Creates and persists a new browser profile with custom icon, purpose, and AI memory settings.
    @discardableResult
    public func createProfile(
        name: String,
        colorHex: String = "#007AFF",
        iconName: String = "person.fill",
        purpose: ProfilePurpose = .personal,
        aiMemoryEnabled: Bool = true,
        isPrivate: Bool = false
    ) -> BrowserProfile {
        let profile = BrowserProfile(
            name: name,
            colorHex: colorHex,
            iconName: iconName,
            purpose: purpose,
            aiMemoryEnabled: aiMemoryEnabled,
            isPrivate: isPrivate
        )
        profiles.append(profile)
        storage.saveProfiles(profiles)
        selectProfile(id: profile.id)
        return profile
    }
    
    /// Updates an existing profile's configuration.
    public func updateProfile(
        id: UUID,
        name: String,
        colorHex: String,
        iconName: String,
        purpose: ProfilePurpose,
        aiMemoryEnabled: Bool
    ) {
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        var updated = profiles[idx]
        updated.name = name
        updated.colorHex = colorHex
        updated.iconName = iconName
        updated.purpose = purpose
        updated.aiMemoryEnabled = updated.isPrivate ? false : aiMemoryEnabled
        
        profiles[idx] = updated
        if activeProfile.id == id {
            activeProfile = updated
        }
        storage.saveProfiles(profiles)
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
        
        // OMEGA FIX: Ensure website data is destroyed.
        clearProfileBrowsingData(id: id)
        
        profiles.remove(at: index)
        dataStoreMap.removeValue(forKey: target.id)
        storage.saveProfiles(profiles)
        
        // Phase 1D: Broadcast deletion so all managers can clean up their records
        NotificationCenter.default.post(name: NSNotification.Name("HoloProfileDeleted"), object: target.id)
        
        if activeProfile.id == id, let first = profiles.first {
            selectProfile(id: first.id)
        }
    }
    
    /// Clears isolated browsing data (cookies, HTTP cache, localStorage) for a given profile.
    public func clearProfileBrowsingData(id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        let store = websiteDataStore(for: profile)
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date(timeIntervalSince1970: 0)
        store.removeData(ofTypes: dataTypes, modifiedSince: dateFrom) {}
    }
}
