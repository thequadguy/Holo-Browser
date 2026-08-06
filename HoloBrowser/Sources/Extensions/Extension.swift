import Foundation

public enum ExtensionType: String, Codable, CaseIterable {
    case command = "Command Extension"
    case userScript = "UserScript"
    case contentModifier = "Content Modifier"
}

/// Data model representing an installed Holo Browser extension.
public struct Extension: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let version: String
    public let author: String
    public var enabled: Bool
    public let type: ExtensionType
    public let permissions: [ExtensionPermission]
    public let userScriptSource: String?
    public let targetDomain: String?
    public let iconName: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        version: String = "1.0.0",
        author: String = "Holo Community",
        enabled: Bool = true,
        type: ExtensionType,
        permissions: [ExtensionPermission],
        userScriptSource: String? = nil,
        targetDomain: String? = nil,
        iconName: String = "puzzlepiece.extension"
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.enabled = enabled
        self.type = type
        self.permissions = permissions
        self.userScriptSource = userScriptSource
        self.targetDomain = targetDomain
        self.iconName = iconName
    }
}
