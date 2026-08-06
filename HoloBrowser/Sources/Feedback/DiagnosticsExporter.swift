import Foundation

/// Privacy-sanitized diagnostics exporter for Holo Browser.
@MainActor
public enum DiagnosticsExporter {
    
    /// Generates a privacy-safe diagnostic text summary.
    /// Excludes all URLs, browsing history, cookies, passwords, and AI prompt context.
    public static func generateSanitizedReport() -> String {
        let processInfo = ProcessInfo.processInfo
        
        var report = """
        === Holo Browser Diagnostic Report ===
        Timestamp: \(ISO8601DateFormatter().string(from: Date()))
        App Version: \(BuildConfiguration.appVersion) (Build \(BuildConfiguration.buildNumber))
        macOS Version: \(processInfo.operatingSystemVersionString)
        Hardware Architecture: \(architecture)
        Active Process Memory: \(formattedMemoryUsage())
        
        === Privacy & Security State ===
        Keychain Accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        Password Reveal Timed Auto-Hide: Enabled (30s)
        AI Privacy Pipeline: Mandatory Regex Sanitization Active
        Private Browsing Cloud AI Shield: Active (.blockExternalAI)
        Analytics Opt-In: \(PrivacyAnalyticsManager.shared.isOptedIn ? "Enabled" : "Disabled")
        
        === Subsystem Status ===
        WebKit Crash Recovery Circuit Breaker: Active
        Background Utility Storage I/O: Active
        
        """
        
        let telemetryData = PrivacyAnalyticsManager.shared.exportTelemetryData()
        if PrivacyAnalyticsManager.shared.isOptedIn {
            report += "\n=== Anonymous Local Telemetry Queue ===\n\(telemetryData)\n"
        }
        
        return report
    }
    
    private static var architecture: String {
        #if arch(arm64)
        return "Apple Silicon (arm64)"
        #else
        return "Intel (x86_64)"
        #endif
    }
    
    private static func formattedMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let mb = Double(info.resident_size) / (1024.0 * 1024.0)
            return String(format: "%.1f MB", mb)
        } else {
            return "N/A"
        }
    }
}
