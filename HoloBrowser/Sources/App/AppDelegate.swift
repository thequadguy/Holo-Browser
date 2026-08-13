import AppKit

/// Application Delegate for Holo Browser.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the main window for Liquid Glass chrome appearance.
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notif in
            guard let window = notif.object as? NSWindow,
                  !(window is NSPanel) else { return }
            // Keep window opaque — NSVisualEffectView handles its own
            // behind-window sampling regardless of window opacity.
            // Setting isOpaque=false makes ALL SwiftUI content transparent.
            window.titlebarAppearsTransparent = true
            window.hasShadow = true
            window.isMovableByWindowBackground = true
        }

        
        // Wire crash loop detection — increment crash counter on every launch.
        // If 3+ consecutive launches crash before the 10s stability timer fires,
        // RecoveryManager enters safe mode and quarantines corrupted session data.
        RecoveryManager.shared.registerAppLaunch()
        
        // After 10 seconds of stable execution, clear the crash counter.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            RecoveryManager.shared.registerStableExecution()
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
