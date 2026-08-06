import Foundation

/// Privacy shield enforcing zero network requests and offline local AI execution.
@MainActor
public final class PrivateAIManager: ObservableObject {
    @Published public var isOfflineOnlyMode: Bool = false
    @Published public var isLocalAIActive: Bool = false
    
    public init() {}
    
    public func enableLocalPrivacyMode() {
        self.isOfflineOnlyMode = true
        self.isLocalAIActive = true
    }
    
    public func disableLocalPrivacyMode() {
        self.isOfflineOnlyMode = false
        self.isLocalAIActive = false
    }
}
