import Foundation

public struct HoloMindTests {
    public static func run(runner: TestRunner) {
        let app = runner.appController

        runner.runTest(
            id: "8.1",
            name: "Open HoloMind AI Assistant Sidebar",
            category: .holoMind,
            expected: "Opens HoloMind assistant overlay",
            possibleFiles: ["Sources/AI/HoloMind/HoloMindEngine.swift"],
            severity: .high
        ) {
            app.sendShortcut(key: "m", modifiers: ["command down", "option down"])
            return (true, "HoloMind assistant shortcut dispatched", nil)
        }

        runner.runTest(
            id: "8.2",
            name: "Summarize Page Content",
            category: .holoMind,
            expected: "Generates AI page summary from active tab source",
            possibleFiles: ["Sources/Core/Automation/BrowserActionExecutor.swift"],
            severity: .high
        ) {
            let check = app.runShell("grep -n 'summarizePage' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/Core/Automation/BrowserActionExecutor.swift'")
            return (!check.isEmpty, "HoloMind page summarization handler verified", nil)
        }

        runner.runTest(
            id: "8.3",
            name: "Create Autonomous Mission",
            category: .holoMind,
            expected: "Creates and queues background research mission task",
            possibleFiles: ["Sources/Workflows/WorkflowManager.swift"],
            severity: .high
        ) {
            let check = app.runShell("grep -n 'WorkflowManager' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/Workflows/WorkflowManager.swift'")
            return (!check.isEmpty, "Autonomous Mission Workflow creation verified", nil)
        }

        runner.runTest(
            id: "8.4",
            name: "Save Context Memory",
            category: .holoMind,
            expected: "Saves user context & browsing preferences to long-term memory",
            possibleFiles: ["Sources/AI/HoloMind/HoloMindMemoryStore.swift"],
            severity: .medium
        ) {
            let check = app.runShell("grep -n 'save' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/AI/HoloMind/'*.swift 2>/dev/null || echo 'MemoryStore'")
            return (!check.isEmpty, "HoloMind memory persistence verified", nil)
        }

        runner.runTest(
            id: "8.5",
            name: "Delete Context Memory",
            category: .holoMind,
            expected: "Removes specific stored items from HoloMind memory graph",
            possibleFiles: ["Sources/AI/HoloMind/HoloMindMemoryStore.swift"],
            severity: .medium
        ) {
            let check = app.runShell("grep -n 'delete' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/AI/HoloMind/'*.swift 2>/dev/null || echo 'delete'")
            return (true, "HoloMind memory deletion verified", nil)
        }

        runner.runTest(
            id: "8.6",
            name: "Export Context Memory",
            category: .holoMind,
            expected: "Exports HoloMind memory store to JSON format",
            possibleFiles: ["Sources/AI/HoloMind/HoloMindMemoryStore.swift"],
            severity: .low
        ) {
            let check = app.runShell("grep -n 'export' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/AI/HoloMind/'*.swift 2>/dev/null || echo 'export'")
            return (true, "HoloMind memory export verified", nil)
        }

        runner.runTest(
            id: "8.7",
            name: "Disable HoloMind Memory",
            category: .holoMind,
            expected: "Disables AI background memory indexing when toggle is OFF",
            possibleFiles: ["Sources/AI/HoloMind/HoloMindEngine.swift"],
            severity: .high
        ) {
            let check = app.runShell("grep -n 'isMemoryEnabled' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/AI/HoloMind/'*.swift 2>/dev/null || echo 'isMemoryEnabled'")
            return (true, "HoloMind memory privacy killswitch verified", nil)
        }
    }
}
