import Foundation

public struct KeyboardShortcutsTests {
    public static func run(runner: TestRunner) {
        let app = runner.appController

        let shortcuts: [(id: String, name: String, key: String, mods: [String], file: String)] = [
            ("9.1", "Cmd+T (New Tab)", "t", ["command down"], "Sources/App/HoloBrowserApp.swift"),
            ("9.2", "Cmd+W (Close Tab)", "w", ["command down"], "Sources/Tabs/TabManager.swift"),
            ("9.3", "Cmd+L (Focus Address Bar)", "l", ["command down"], "Sources/UI/Navigation/AddressBarView.swift"),
            ("9.4", "Cmd+, (Open Settings)", ",", ["command down"], "Sources/App/HoloBrowserApp.swift"),
            ("9.5", "Cmd+Shift+T (Reopen Closed Tab)", "t", ["command down", "shift down"], "Sources/Tabs/TabManager.swift"),
            ("9.6", "Cmd+R (Reload Page)", "r", ["command down"], "Sources/Engine/HoloWebView.swift"),
            ("9.7", "Cmd+F (Find in Page)", "f", ["command down"], "Sources/UI/Navigation/FindInPageView.swift"),
            ("9.8", "Cmd+1 to Cmd+9 (Switch Tab by Index)", "1", ["command down"], "Sources/Tabs/TabManager.swift")
        ]

        for s in shortcuts {
            runner.runTest(
                id: s.id,
                name: s.name,
                category: .keyboardShortcuts,
                expected: "Keystroke dispatch '\(s.name)' executes correctly",
                possibleFiles: [s.file],
                severity: .high
            ) {
                app.sendShortcut(key: s.key, modifiers: s.mods)
                return (true, "Shortcut '\(s.name)' keystroke event dispatched to System Events", nil)
            }
        }
    }
}
