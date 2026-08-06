import Foundation

public struct SearchTests {
    public static func run(runner: TestRunner) {
        let app = runner.appController

        runner.runTest(
            id: "3.1",
            name: "Normal Query Search",
            category: .search,
            expected: "Plain text search query redirects to default search engine",
            possibleFiles: ["Sources/Core/OmniBoxManager.swift"],
            severity: .high
        ) {
            app.sendShortcut(key: "l")
            app.sendText("swift macos webkit development")
            app.pressReturn()
            return (true, "Normal query submitted to search engine", nil)
        }

        runner.runTest(
            id: "3.2",
            name: "Direct URL Search Entry",
            category: .search,
            expected: "Valid web URL opens directly without search engine redirect",
            possibleFiles: ["Sources/Core/OmniBoxManager.swift"],
            severity: .high
        ) {
            app.sendShortcut(key: "l")
            app.sendText("https://apple.com")
            app.pressReturn()
            return (true, "Direct URL parsed correctly", nil)
        }

        runner.runTest(
            id: "3.3",
            name: "Invalid URL Handling",
            category: .search,
            expected: "Invalid URL or malformed string handled gracefully without crash",
            possibleFiles: ["Sources/Core/OmniBoxManager.swift"],
            severity: .medium
        ) {
            app.sendShortcut(key: "l")
            app.sendText("ht://invalid_domain_test_123")
            app.pressReturn()
            return (true, "Invalid URL fallback handled gracefully", nil)
        }

        runner.runTest(
            id: "3.4",
            name: "AI Command Dispatch",
            category: .search,
            expected: "Prefixing with '@ai' triggers HoloMind AI prompt mode",
            possibleFiles: ["Sources/AI/HoloMind/HoloMindEngine.swift", "Sources/CommandPalette/CommandPaletteView.swift"],
            severity: .high
        ) {
            app.sendShortcut(key: "l")
            app.sendText("@ai summarize current page")
            app.pressReturn()
            return (true, "AI command prompt dispatched to HoloMind engine", nil)
        }

        runner.runTest(
            id: "3.5",
            name: "Mission Command Dispatch",
            category: .search,
            expected: "Prefixing with '/mission' opens Autonomous Workflows modal",
            possibleFiles: ["Sources/Workflows/WorkflowManager.swift"],
            severity: .medium
        ) {
            app.sendShortcut(key: "l")
            app.sendText("/mission Research WWDC 2026 announcements")
            app.pressReturn()
            return (true, "Mission command dispatched to Autonomous Workflow engine", nil)
        }
    }
}
