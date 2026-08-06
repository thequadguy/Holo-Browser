import Foundation

/// Enum representing browser operating modes in Holo Browser.
public enum BrowserMode: String, CaseIterable, Identifiable {
    /// Standard browsing mode with full toolbar and tab bar visible.
    case normal = "Normal"
    /// Minimalist mode hiding toolbar chrome for distraction-free reading.
    case focus = "Focus"
    /// Centered reader mode layout.
    case reading = "Reading"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .normal: return "sidebar.leading"
        case .focus: return "eye.slash"
        case .reading: return "doc.plaintext"
        }
    }
}
