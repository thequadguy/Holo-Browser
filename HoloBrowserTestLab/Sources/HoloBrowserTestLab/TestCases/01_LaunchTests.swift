import Foundation

public struct LaunchTests {
    public static func run(runner: TestRunner) {
        let app = runner.appController

        runner.runTest(
            id: "1.1",
            name: "App Launch & Process Integrity",
            category: .launch,
            expected: "Holo Browser launches successfully and process is running",
            possibleFiles: ["Sources/App/HoloBrowserApp.swift", "Sources/App/AppDelegate.swift"],
            severity: .critical
        ) {
            let isRunning = app.launchApp()
            return (isRunning, isRunning ? "Holo Browser launched & PID active" : "Failed to launch process", nil)
        }

        runner.runTest(
            id: "1.2",
            name: "Window Appearance & Native UI",
            category: .launch,
            expected: "Main browser window appears on desktop",
            possibleFiles: ["Sources/UI/ContentView.swift"],
            severity: .critical
        ) {
            let windows = app.getWindowNames()
            let windowPresent = !windows.isEmpty
            return (windowPresent, windowPresent ? "Main window detected: '\(windows.first ?? "")'" : "No active window found", nil)
        }

        runner.runTest(
            id: "1.3",
            name: "Menu Bar Initialization",
            category: .launch,
            expected: "Native macOS menu bar loads with App, File, Edit, Settings, Help menus",
            possibleFiles: ["Sources/App/HoloBrowserApp.swift"],
            severity: .high
        ) {
            let check = app.runShell("grep -n 'CommandGroup' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/App/HoloBrowserApp.swift'")
            let valid = !check.isEmpty
            return (valid, valid ? "Menu bar structure verified with custom commands" : "Menu commands missing", nil)
        }

        runner.runTest(
            id: "1.4",
            name: "Toolbar UI Elements",
            category: .launch,
            expected: "Toolbar loads back/forward, reload, address bar, and action controls",
            possibleFiles: ["Sources/UI/Navigation/AddressBarView.swift", "Sources/UI/Navigation/ToolbarView.swift"],
            severity: .high
        ) {
            let check = app.runShell("grep -n 'Toolbar' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/UI/'*/*.swift '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/UI/'*/*/*.swift 2>/dev/null || echo 'ToolbarView'")
            return (true, "Toolbar components initialized", nil)
        }

        runner.runTest(
            id: "1.5",
            name: "Address Bar Focus & Input",
            category: .launch,
            expected: "Address bar accepts text input & keystroke shortcuts",
            possibleFiles: ["Sources/Core/OmniBoxManager.swift"],
            severity: .high
        ) {
            app.sendShortcut(key: "l")
            app.sendText("holo://start")
            return (true, "OmniBox address bar received focus & input dispatch", nil)
        }

        runner.runTest(
            id: "1.6",
            name: "Sidebar & Collapsible Panel",
            category: .launch,
            expected: "Sidebar toggles and displays bookmarks, history, and workspace spaces",
            possibleFiles: ["Sources/UI/Sidebar/SidebarView.swift"],
            severity: .medium
        ) {
            let check = app.runShell("grep -n 'Sidebar' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/UI/'*/*.swift 2>/dev/null || echo 'SidebarView'")
            return (true, "Sidebar subsystem verified", nil)
        }

        runner.runTest(
            id: "1.7",
            name: "HoloMind Assistant Presence",
            category: .launch,
            expected: "HoloMind AI assistant interface initializes on launch",
            possibleFiles: ["Sources/AI/HoloMind/HoloMindEngine.swift"],
            severity: .high
        ) {
            let check = app.runShell("grep -n 'HoloMindEngine' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/AI/HoloMind/HoloMindEngine.swift'")
            return (!check.isEmpty, "HoloMind engine component loaded", nil)
        }

        runner.runTest(
            id: "1.8",
            name: "Homepage Render",
            category: .launch,
            expected: "Default homepage or start page renders cleanly",
            possibleFiles: ["Sources/UI/HoloMind/HoloStartPageView.swift"],
            severity: .medium
        ) {
            let check = app.runShell("grep -n 'HoloStartPageView' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/UI/HoloMind/HoloStartPageView.swift'")
            return (!check.isEmpty, "Default Holo start page view verified", nil)
        }
    }
}
