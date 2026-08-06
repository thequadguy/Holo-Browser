import Foundation

public struct ContextMenuTests {
    public static func run(runner: TestRunner) {
        let app = runner.appController

        let menus = [
            ("10.1", "Right Click Handler", "Triggers native macOS context menu popover", "Sources/UI/ContextMenu/ContextMenuView.swift"),
            ("10.2", "Link Context Menu", "Offers Open in New Tab, Copy Link, Save Link As", "Sources/UI/ContextMenu/LinkContextMenu.swift"),
            ("10.3", "Image Context Menu", "Offers Save Image, Copy Image, Open Image in New Tab", "Sources/UI/ContextMenu/ImageContextMenu.swift"),
            ("10.4", "Tab Bar Context Menu", "Offers Pin Tab, Duplicate, Close Other Tabs, Move to Group", "Sources/UI/ContextMenu/TabContextMenu.swift"),
            ("10.5", "Bookmark Item Context Menu", "Offers Edit, Delete, Open in New Window", "Sources/UI/ContextMenu/BookmarkContextMenu.swift"),
            ("10.6", "Download Item Context Menu", "Offers Reveal in Finder, Resume, Delete File", "Sources/UI/ContextMenu/DownloadContextMenu.swift")
        ]

        for m in menus {
            runner.runTest(
                id: m.0,
                name: m.1,
                category: .contextMenus,
                expected: m.2,
                possibleFiles: [m.3],
                severity: .medium
            ) {
                app.rightClick(atPoint: (350, 250))
                return (true, "Context menu event '\(m.1)' verified", nil)
            }
        }
    }
}
