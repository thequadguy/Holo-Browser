import Foundation

/// Privacy-preserving anonymous event metrics tracker for Holo Browser V1.7.
/// Zero tracking IDs, zero browsing telemetry, 100% on-device aggregation.
@MainActor
public final class HoloMetrics: ObservableObject {
    public static let shared = HoloMetrics()
    
    @Published public private(set) var launchCount: Int = 0
    @Published public private(set) var navigationCount: Int = 0
    @Published public private(set) var aiCommandCount: Int = 0
    @Published public private(set) var missionCount: Int = 0
    
    private init() {}
    
    public func recordLaunch() {
        launchCount += 1
    }
    
    public func recordNavigation() {
        navigationCount += 1
    }
    
    public func recordAICommand() {
        aiCommandCount += 1
    }
    
    public func recordMissionTrigger() {
        missionCount += 1
    }
}
