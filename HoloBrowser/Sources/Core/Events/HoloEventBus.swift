import Foundation
import Combine

/// Compiler-safe event definitions replacing raw string-based NotificationCenter notifications.
public enum HoloEvent: Equatable {
    case openSettings
    case openAbout
    case openFeedback
    case openDogfood
    case openImportWizard
    case newTabShortcut
    case focusAddressBar
    case quickActionSummarize
    case quickActionSaveMemory
    case smartSearchAI(query: String)
    case smartSearchMission(query: String)
    case profileDeleted(profileID: UUID)
    case securityAlert(message: String)
}

/// Thread-safe central event bus for Holo Browser decoupled event dispatching.
@MainActor
public final class HoloEventBus: ObservableObject {
    public static let shared = HoloEventBus()
    
    public let publisher = PassthroughSubject<HoloEvent, Never>()
    
    private init() {}
    
    /// Dispatches a typed HoloEvent across the application.
    public func post(_ event: HoloEvent) {
        publisher.send(event)
    }
}
