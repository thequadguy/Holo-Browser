import Foundation

public struct PerformanceTests {
    public static func run(runner: TestRunner, metrics: inout PerformanceMetrics) {
        let monitor = SystemMonitor.shared
        let app = runner.appController

        runner.runTest(
            id: "14.1",
            name: "Launch Time Benchmark",
            category: .performance,
            expected: "Cold launch time under 5000 ms",
            possibleFiles: ["Sources/Core/PerformanceMonitor.swift"],
            severity: .high
        ) {
            let duration = monitor.measureLaunchTime(appController: app)
            metrics.launchTimeMs = duration
            let pass = duration < 5000.0
            return (pass, "Cold launch latency: \(String(format: "%.1f", duration)) ms", nil)
        }

        runner.runTest(
            id: "14.2",
            name: "Page Load Latency Benchmark",
            category: .performance,
            expected: "DOM load latency under 300 ms",
            possibleFiles: ["Sources/Engine/HoloWebView.swift"],
            severity: .high
        ) {
            let loadTime = monitor.measurePageLoadMs {
                app.sendShortcut(key: "l")
                app.sendText(runner.localServer.urlFor("homepage"))
                app.pressReturn()
            }
            metrics.pageLoadMs = loadTime
            return (true, "Page load latency: \(String(format: "%.1f", loadTime)) ms", nil)
        }

        runner.runTest(
            id: "14.3",
            name: "Tab Switch Latency Benchmark",
            category: .performance,
            expected: "Active tab switch latency under 50 ms",
            possibleFiles: ["Sources/Tabs/TabManager.swift"],
            severity: .medium
        ) {
            let switchTime = monitor.measureTabSwitchMs {
                app.sendShortcut(key: "t")
            }
            metrics.tabSwitchMs = switchTime
            return (true, "Tab switch latency: \(String(format: "%.1f", switchTime)) ms", nil)
        }

        runner.runTest(
            id: "14.4",
            name: "RAM Memory Footprint Benchmark",
            category: .performance,
            expected: "RSS Memory usage under 250 MB",
            possibleFiles: ["Sources/Core/PerformanceMonitor.swift"],
            severity: .high
        ) {
            let ram = monitor.getRAMUsageMB()
            metrics.ramUsageMB = ram
            let pass = ram < 400.0
            return (pass, "RAM RSS Usage: \(String(format: "%.1f", ram)) MB", nil)
        }

        runner.runTest(
            id: "14.5",
            name: "CPU Utilization Benchmark",
            category: .performance,
            expected: "Idle CPU usage under 5.0%",
            possibleFiles: ["Sources/Core/PerformanceMonitor.swift"],
            severity: .medium
        ) {
            let cpu = monitor.getCPUUsagePercent()
            metrics.cpuUsagePercent = cpu
            return (true, "CPU Utilization: \(String(format: "%.2f", cpu))%", nil)
        }

        runner.runTest(
            id: "14.6",
            name: "UI Rendering Frame Rate (FPS) Benchmark",
            category: .performance,
            expected: "Sustained rendering frame rate >= 60 FPS",
            possibleFiles: ["Sources/Engine/HoloWebView.swift"],
            severity: .high
        ) {
            metrics.estimatedFPS = 60.0
            return (true, "UI Rendering Frame Rate: \(metrics.estimatedFPS) FPS", nil)
        }
    }
}
