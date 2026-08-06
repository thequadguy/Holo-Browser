import Foundation

/// Primary model representing an AI workspace/project.
public struct Workspace: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var tabURLs: [String]
    public var noteIDs: [UUID]
    public var researchSessionIDs: [UUID]
    public let profileID: UUID
    
    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "folder",
        colorHex: String = "#007AFF",
        tabURLs: [String] = [],
        noteIDs: [UUID] = [],
        researchSessionIDs: [UUID] = [],
        profileID: UUID
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.tabURLs = tabURLs
        self.noteIDs = noteIDs
        self.researchSessionIDs = researchSessionIDs
        self.profileID = profileID
    }
}
