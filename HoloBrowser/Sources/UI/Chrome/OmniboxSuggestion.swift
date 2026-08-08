import Foundation
import SwiftUI

public enum OmniboxSuggestionType: Equatable {
    case navigation(url: URL)
    case search(query: String)
    case history(url: URL)
    case bookmark(url: URL)
    case holomind(prompt: String)
    case mission(goal: String)
}

public struct OmniboxSuggestion: Identifiable, Equatable {
    public let id = UUID()
    public let type: OmniboxSuggestionType
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let iconColor: Color
    
    public init(type: OmniboxSuggestionType, title: String, subtitle: String? = nil, icon: String, iconColor: Color = .primary) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
    }
    
    public static func == (lhs: OmniboxSuggestion, rhs: OmniboxSuggestion) -> Bool {
        return lhs.type == rhs.type && lhs.title == rhs.title
    }
}
