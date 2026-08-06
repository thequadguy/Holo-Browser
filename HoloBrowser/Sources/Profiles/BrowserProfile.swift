import Foundation
import SwiftUI

public enum ProfilePurpose: String, Codable, CaseIterable, Identifiable {
    case personal = "Personal"
    case work = "Work"
    case research = "Research"
    case guest = "Guest"
    case privateBrowsing = "Private"
    
    public var id: String { rawValue }
    
    public var defaultIcon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .research: return "atom"
        case .guest: return "person.crop.circle.badge.questionmark"
        case .privateBrowsing: return "shield.slash.fill"
        }
    }
    
    public var defaultColorHex: String {
        switch self {
        case .personal: return "#007AFF"
        case .work: return "#34C759"
        case .research: return "#AF52DE"
        case .guest: return "#FF9500"
        case .privateBrowsing: return "#FF2D55"
        }
    }
}

/// Data model representing a browser profile with per-profile data store isolation and preference customization.
public struct BrowserProfile: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    public var iconName: String
    public var purposeRaw: String
    public var aiMemoryEnabled: Bool
    public let creationDate: Date
    public var lastUsedDate: Date
    public let storageIdentifier: String
    public let isPrivate: Bool
    
    public var purpose: ProfilePurpose {
        get { ProfilePurpose(rawValue: purposeRaw) ?? .personal }
        set { purposeRaw = newValue.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        iconName: String = "person.fill",
        purpose: ProfilePurpose = .personal,
        aiMemoryEnabled: Bool = true,
        creationDate: Date = Date(),
        lastUsedDate: Date = Date(),
        storageIdentifier: String? = nil,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.purposeRaw = purpose.rawValue
        self.aiMemoryEnabled = isPrivate ? false : aiMemoryEnabled
        self.creationDate = creationDate
        self.lastUsedDate = lastUsedDate
        self.storageIdentifier = storageIdentifier ?? id.uuidString
        self.isPrivate = isPrivate
    }
}
