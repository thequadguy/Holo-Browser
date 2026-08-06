import Foundation

public enum ActionType: String, Codable, CaseIterable {
    case navigateToURL
    case openNewTab
    case summarizePage
    case collectSource
    case createNote
    case extractInformation
    case scrollToSection
    case submitForm // Blocked
    case purchaseProduct // Blocked
    case modifyAccount // Blocked
}

/// Representation of a single proposed browser action.
public struct AIAction: Identifiable, Codable, Equatable {
    public let id: UUID
    public let type: ActionType
    public let name: String
    public let description: String
    public let riskLevel: AIActionPermission
    public let parameters: [String: String]
    public let requiresConfirmation: Bool
    
    public init(
        id: UUID = UUID(),
        type: ActionType,
        name: String,
        description: String,
        riskLevel: AIActionPermission,
        parameters: [String: String] = [:],
        requiresConfirmation: Bool
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.riskLevel = riskLevel
        self.parameters = parameters
        self.requiresConfirmation = requiresConfirmation
    }
}
