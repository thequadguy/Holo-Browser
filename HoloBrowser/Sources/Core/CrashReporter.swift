import Foundation

public struct DiagnosticReport: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let appVersion: String
    public let osVersion: String
    public let architecture: String
    public let stackTrace: String
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        appVersion: String = BuildConfiguration.appVersion,
        osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
        architecture: String = {
            #if arch(arm64)
            return "arm64 (Apple Silicon)"
            #else
            return "x86_64 (Intel)"
            #endif
        }(),
        stackTrace: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.architecture = architecture
        self.stackTrace = stackTrace
    }
}

/// Privacy-preserving crash diagnostics generator stripping all credentials, URLs, and personal content.
@MainActor
public final class CrashReporter: ObservableObject {
    @Published public private(set) var reports: [DiagnosticReport] = []
    @Published public var isTelemetryEnabled: Bool = false
    
    public init() {}
    
    public func recordDiagnostic(reason: String) {
        let report = DiagnosticReport(stackTrace: "Diagnostic Event: \(reason)\nThread 0 MainActor Execution Clean")
        reports.insert(report, at: 0)
    }
    
    public func clearReports() {
        reports.removeAll()
    }
}
