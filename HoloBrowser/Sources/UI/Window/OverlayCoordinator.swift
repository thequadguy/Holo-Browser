import SwiftUI
import Combine

/// Dedicated coordinator managing sheet presentations, modals, and overlay routing for Holo Browser.
@MainActor
public final class OverlayCoordinator: ObservableObject {
    @Published public var showWelcomeSheet: Bool = false
    @Published public var showFeedbackSheet: Bool = false
    @Published public var showImportWizardSheet: Bool = false
    @Published public var showAboutSheet: Bool = false
    @Published public var showDogfoodSheet: Bool = false
    
    public init() {}
    
    public func dismissAll() {
        showWelcomeSheet = false
        showFeedbackSheet = false
        showImportWizardSheet = false
        showAboutSheet = false
        showDogfoodSheet = false
    }
}
