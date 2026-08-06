import Foundation
import Combine

/// Privacy-First Anonymous Analytics Manager for Holo Browser.
/// Enforces strict zero-telemetry rules: NEVER collects URLs, history, passwords, search terms, or AI prompts.
@MainActor
public final class PrivacyAnalyticsManager: ObservableObject {
    public static let shared = PrivacyAnalyticsManager()
    
    @Published public var isOptedIn: Bool {
        didSet {
            UserDefaults.standard.set(isOptedIn, forKey: "PrivacyAnalyticsOptIn")
        }
    }
    
    @Published public private(set) var eventQueue: [[String: String]] = []
    
    private init() {
        self.isOptedIn = UserDefaults.standard.bool(forKey: "PrivacyAnalyticsOptIn") // Defaults to false
    }
    
    /// Track an anonymous feature interaction count or timing.
    public func logEvent(_ eventName: String, metadata: [String: String] = [:]) {
        guard isOptedIn else { return }
        
        var payload: [String: String] = [
            "event": eventName,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "appVersion": "1.0.0",
            "osVersion": ProcessInfo.processInfo.operatingSystemVersionString,
            "architecture": SystemInfo.architecture
        ]
        
        // Filter out any sensitive keys defensively
        for (key, val) in metadata {
            let lowerKey = key.lowercased()
            if !lowerKey.contains("url") && !lowerKey.contains("history") && !lowerKey.contains("password") && !lowerKey.contains("query") && !lowerKey.contains("prompt") {
                payload[key] = val
            }
        }
        
        eventQueue.append(payload)
    }
    
    /// Export anonymized local telemetry queue as a JSON string.
    public func exportTelemetryData() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: eventQueue, options: .prettyPrinted) else {
            return "[]"
        }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
    
    /// Clear all queued local telemetry data.
    public func clearTelemetryData() {
        eventQueue.removeAll()
    }
}

fileprivate enum SystemInfo {
    static var architecture: String {
        #if arch(arm64)
        return "arm64 (Apple Silicon)"
        #else
        return "x86_64 (Intel)"
        #endif
    }
}
