import Foundation

/// Explicit security permission scopes for Holo Browser extensions.
public enum ExtensionPermission: String, Codable, CaseIterable, Identifiable {
    case websiteAccess = "Website Access"
    case scriptInjection = "UserScript Injection"
    case storageAccess = "Isolated Storage"
    case commandExecution = "Command Palette Integration"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .websiteAccess:
            return "Read webpage title and address for current active tab."
        case .scriptInjection:
            return "Inject custom JavaScript styling and behavior into web pages."
        case .storageAccess:
            return "Save isolated key-value settings data locally."
        case .commandExecution:
            return "Register quick action shortcuts into the Cmd+K Command Palette."
        }
    }
}
