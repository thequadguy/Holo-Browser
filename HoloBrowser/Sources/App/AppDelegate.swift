import AppKit

/// Application Delegate for Holo Browser.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Enable window translucency & behind-window vibrancy for Liquid Glass
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notif in
            if let window = notif.object as? NSWindow {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.hasShadow = true
                window.isMovableByWindowBackground = true
                window.invalidateShadow()
            }
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
