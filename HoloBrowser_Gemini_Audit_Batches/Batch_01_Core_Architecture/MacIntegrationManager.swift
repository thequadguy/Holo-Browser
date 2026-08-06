import Foundation
import AppKit

/// Native macOS integration helper checking default browser status, universal clipboard, and external URL handling.
public enum MacIntegrationManager {
    
    public static func isDefaultBrowser() -> Bool {
        guard let url = URL(string: "https://"),
              let appURL = NSWorkspace.shared.urlForApplication(toOpen: url) else {
            return false
        }
        return appURL.path.contains("Holo") || appURL.path.contains("com.holo.browser")
    }
    
    public static func copyToUniversalClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
