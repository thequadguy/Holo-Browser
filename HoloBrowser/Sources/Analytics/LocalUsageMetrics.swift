import Foundation
import Combine

public struct MetricEvent: Identifiable, Codable {
    public let id: UUID
    public let category: String
    public let name: String
    public let timestamp: Date
    public let durationMs: Double?
    
    public init(id: UUID = UUID(), category: String, name: String, timestamp: Date = Date(), durationMs: Double? = nil) {
        self.id = id
        self.category = category
        self.name = name
        self.timestamp = timestamp
        self.durationMs = durationMs
    }
}

/// `@MainActor` privacy-preserving local usage metrics manager.
///
/// **PRIVACY ASSURANCE**:
/// - NEVER collects URLs, domain names, search queries, webpage titles, or body text.
/// - NEVER collects passwords, Keychain items, cookies, or user identity data.
/// - Metrics are stored ONLY locally in Application Support and never transmitted to external cloud servers.
@MainActor
public final class LocalUsageMetrics: ObservableObject {
    public static let shared = LocalUsageMetrics()
    
    @Published public private(set) var events: [MetricEvent] = []
    @Published public private(set) var featureCounters: [String: Int] = [:]
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("local_metrics.json")
        loadLocalMetrics()
    }
    
    /// Increments feature usage counter locally.
    public func recordFeatureUsage(name: String) {
        let count = featureCounters[name, default: 0] + 1
        featureCounters[name] = count
        
        let event = MetricEvent(category: "FeatureUsage", name: name)
        appendEvent(event)
    }
    
    /// Records performance timing locally (e.g. app launch, tab switch duration).
    public func recordPerformanceTiming(name: String, durationMs: Double) {
        let event = MetricEvent(category: "Performance", name: name, durationMs: durationMs)
        appendEvent(event)
    }
    
    /// Records crash recovery event locally.
    public func recordCrashRecoveryEvent(name: String) {
        let event = MetricEvent(category: "CrashRecovery", name: name)
        appendEvent(event)
    }
    
    /// Purges all stored local telemetry data.
    public func clearAllMetrics() {
        events.removeAll()
        featureCounters.removeAll()
        let url = fileURL
        Task {
            await DiskStorageActor.shared.delete(at: url)
        }
    }
    
    private func appendEvent(_ event: MetricEvent) {
        events.insert(event, at: 0)
        if events.count > 500 {
            events = Array(events.prefix(500))
        }
        saveLocalMetricsAsync()
    }
    
    private func loadLocalMetrics() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let list = try? JSONDecoder().decode([MetricEvent].self, from: data) else {
            return
        }
        self.events = list
        for ev in list where ev.category == "FeatureUsage" {
            featureCounters[ev.name, default: 0] += 1
        }
    }
    
    private func saveLocalMetricsAsync() {
        let copy = self.events
        let url = self.fileURL
        Task {
            try? await DiskStorageActor.shared.write(copy, to: url)
        }
    }
}
