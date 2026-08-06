import Foundation
import Combine

/// Main-actor observable manager for controlling browser mode transitions.
@MainActor
public final class ModeManager: ObservableObject {
    @Published public private(set) var currentMode: BrowserMode = .normal
    
    public init() {}
    
    public func setMode(_ mode: BrowserMode) {
        currentMode = mode
    }
    
    public func toggleFocusMode() {
        if currentMode == .focus {
            currentMode = .normal
        } else {
            currentMode = .focus
        }
    }
}
