import Foundation

/// Main-actor reliability manager monitoring WebKit process crashes and recovering terminated tabs cleanly.
/// P0-A Fix: ReliabilityManager is now purely a state tracker.
/// The single authoritative reload is performed by NavigationManager.webViewWebContentProcessDidTerminate.
/// A second reload here was a regression that caused a double-load on every crash.
@MainActor
public final class ReliabilityManager: ObservableObject {
    @Published public private(set) var crashCount: Int = 0
    @Published public private(set) var lastRecoveredURLString: String?
    
    // OMEGA BETA: Observability Telemetry
    public private(set) var sessionStartTime: Date
    public private(set) var appStartDurationMS: Double = 0
    private var telemetryLogURL: URL

    public init() {
        self.sessionStartTime = Date()
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        self.telemetryLogURL = holoFolder.appendingPathComponent("beta_telemetry.json")
    }
    
    public func recordStartupCompletion(durationMS: Double) {
        self.appStartDurationMS = durationMS
        logTelemetry(event: "startup_completed", metadata: ["duration_ms": "\(durationMS)"])
    }

    /// Called after NavigationManager has already reloaded the crashed webview.
    /// Increments crash telemetry and records the URL for UI display.
    /// Does NOT call webView.reload() — NavigationManager is the single owner of crash recovery.
    public func handleWebContentProcessTermination(tab: Tab) {
        self.crashCount += 1
        self.lastRecoveredURLString = tab.url?.absoluteString
        logTelemetry(event: "webcontent_crash", metadata: ["crash_number": "\(self.crashCount)"])
    }
    
    private func logTelemetry(event: String, metadata: [String: String] = [:]) {
        // Enforce absolute privacy: No URLs, no IP addresses, no user content.
        // Purely functional performance metrics.
        let entry: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "event": event,
            "metadata": metadata
        ]
        
        // In a real beta, this would securely batch upload. 
        // For OMEGA validation, we write it to a local diagnostic file.
        Task {
            do {
                let existingData = try? await DiskStorageActor.shared.readRaw(from: telemetryLogURL)
                var logs: [[String: Any]] = []
                if let data = existingData,
                   let decoded = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    logs = decoded
                }
                logs.append(entry)
                let newData = try JSONSerialization.data(withJSONObject: logs)
                try await DiskStorageActor.shared.writeRaw(newData, to: telemetryLogURL)
            } catch {
                // Silently swallow telemetry write failures in production to avoid console spam.
            }
        }
    }
}
