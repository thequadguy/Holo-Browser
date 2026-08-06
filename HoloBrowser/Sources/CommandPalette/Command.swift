import Foundation

public enum CommandCategory: String, CaseIterable {
    case navigation = "Navigation"
    case tabs = "Tabs"
    case preferences = "Preferences"
    case system = "System"
}

/// Data model representing a executable command in the Cmd+K Command Palette.
public struct Command: Identifiable {
    public let id: UUID
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let category: CommandCategory
    public let action: () -> Void
    
    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        icon: String,
        category: CommandCategory,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
        self.action = action
    }
}
