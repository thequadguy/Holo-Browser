import Foundation

/// Data model representing a persistent contextual workspace (Space) in Holo Browser.
public struct HoloSpace: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public let profileID: UUID
    public var tabIDs: [UUID]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        colorHex: String = "38BDF8",
        profileID: UUID,
        tabIDs: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.profileID = profileID
        self.tabIDs = tabIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Helper checking whether a specific tab ID belongs to this Space.
    public func containsTab(id: UUID) -> Bool {
        return tabIDs.contains(id)
    }
}
