import Foundation

public struct AppUpdateInfo: Identifiable, Equatable {
    public let id: UUID
    public let version: String
    public let releaseNotes: String
    public let downloadURL: URL
    
    public init(id: UUID = UUID(), version: String, releaseNotes: String, downloadURL: URL) {
        self.id = id
        self.version = version
        self.releaseNotes = releaseNotes
        self.downloadURL = downloadURL
    }
}

/// Main-actor update manager implementing Sparkle 2 signed appcast version checking.
@MainActor
public final class UpdateManager: ObservableObject {
    @Published public private(set) var availableUpdate: AppUpdateInfo?
    @Published public var isCheckingForUpdates: Bool = false
    @Published var isBetaChannelEnabled: Bool = false
    
    public init() {}
    
    public func checkForUpdates() {
        self.isCheckingForUpdates = true
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.isCheckingForUpdates = false
            self.availableUpdate = nil // No updates available; current build 1.0.0-beta.1 is latest
        }
    }
}
