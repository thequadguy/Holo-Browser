import Foundation
import Darwin

/// Real-time performance monitor measuring application cold launch latency, RSS memory footprint, and system metrics.
@MainActor
public final class PerformanceMonitor: ObservableObject {
    public static let startTime = ProcessInfo.processInfo.systemUptime
    
    @Published public private(set) var launchTimeMs: Double = 0.0
    @Published public private(set) var idleMemoryMB: Double = 0.0
    
    public init() {
        measureMetrics()
    }
    
    /// Measures real process resident set size (RSS RAM) and cold launch duration.
    public func measureMetrics() {
        // Calculate cold launch duration
        let now = ProcessInfo.processInfo.systemUptime
        let elapsedMs = (now - Self.startTime) * 1000.0
        self.launchTimeMs = max(elapsedMs, 10.0)
        
        // Measure real RSS memory footprint using Darwin mach_task_basic_info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryBytes = Double(info.resident_size)
            self.idleMemoryMB = memoryBytes / (1024.0 * 1024.0)
        } else {
            self.idleMemoryMB = 0.0 // Display 0.0 if unavailable instead of fake values
        }
    }
    
    public func recordMetrics(launchMs: Double, memoryMB: Double) {
        self.launchTimeMs = launchMs
        self.idleMemoryMB = memoryMB
    }
}
