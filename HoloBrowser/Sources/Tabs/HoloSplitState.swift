import Foundation

public enum SplitPane: String, Codable {
    case primary
    case secondary
}

/// State model managing dual-pane Split View mode without duplicating Tab objects.
public struct HoloSplitState: Codable, Equatable {
    public var isActive: Bool
    public var primaryTabID: UUID?
    public var secondaryTabID: UUID?
    public var activePane: SplitPane
    public var dividerRatio: Double
    
    public init(
        isActive: Bool = false,
        primaryTabID: UUID? = nil,
        secondaryTabID: UUID? = nil,
        activePane: SplitPane = .primary,
        dividerRatio: Double = 0.5
    ) {
        self.isActive = isActive
        self.primaryTabID = primaryTabID
        self.secondaryTabID = secondaryTabID
        self.activePane = activePane
        self.dividerRatio = dividerRatio
    }
}
