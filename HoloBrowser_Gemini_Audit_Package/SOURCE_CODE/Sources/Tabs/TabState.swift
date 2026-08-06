import Foundation

/// Lifecycle states for an individual Holo Browser tab.
public enum TabState: String, Codable, Equatable {
    /// Active tab currently displayed in the main window view.
    case active
    /// Loaded tab running in the background.
    case background
    /// Resource-released tab preserving URL/title metadata for lazy restoration.
    case suspended
    /// Tab marked for destruction and resource deallocation.
    case closed
}
