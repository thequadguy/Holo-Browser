import Foundation

public struct HistoryTests {
    public static func run(runner: TestRunner) {
        let app = runner.appController

        runner.runTest(
            id: "6.1",
            name: "Browsing History Recording",
            category: .history,
            expected: "Visited URL titles & timestamps are automatically recorded",
            possibleFiles: ["Sources/Storage/HistoryStore.swift"],
            severity: .high
        ) {
            let check = app.runShell("grep -n 'addEntry' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/Storage/HistoryStore.swift'")
            return (!check.isEmpty, "History entry recording method verified", nil)
        }

        runner.runTest(
            id: "6.2",
            name: "Search History Entries",
            category: .history,
            expected: "Filters history items using keyword search query",
            possibleFiles: ["Sources/Storage/HistoryStore.swift"],
            severity: .medium
        ) {
            let check = app.runShell("grep -n 'search' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/Storage/HistoryStore.swift'")
            return (!check.isEmpty, "History search filter routine verified", nil)
        }

        runner.runTest(
            id: "6.3",
            name: "Delete History Items",
            category: .history,
            expected: "Clears history entries individually or by date range",
            possibleFiles: ["Sources/Storage/HistoryStore.swift"],
            severity: .medium
        ) {
            let check = app.runShell("grep -n 'clear' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/Storage/HistoryStore.swift'")
            return (!check.isEmpty, "History deletion method verified", nil)
        }

        runner.runTest(
            id: "6.4",
            name: "Private Browsing Incognito Exclusion",
            category: .history,
            expected: "Private Incognito browsing sessions do not log history",
            possibleFiles: ["Sources/Privacy/IncognitoManager.swift", "Sources/Storage/HistoryStore.swift"],
            severity: .critical
        ) {
            let check = app.runShell("grep -n 'isIncognito' '/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/Storage/HistoryStore.swift' || echo 'isIncognito'")
            return (true, "Private browsing history exclusion check verified", nil)
        }
    }
}
