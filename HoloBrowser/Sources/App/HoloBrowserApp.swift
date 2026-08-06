import SwiftUI

@main
struct HoloBrowserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showAbout = false
    @State private var showFeedback = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // File > New
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    if let url = URL(string: "holo://new") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("New Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("HoloNewTabShortcut"), object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
            
            // Preferences / Settings Menu (Cmd + ,)
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    NotificationCenter.default.post(name: NSNotification.Name("HoloOpenSettings"), object: nil)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
            
            // Replace default About menu item with custom About window / sheet
            CommandGroup(replacing: .appInfo) {
                Button("About Holo Browser") {
                    NotificationCenter.default.post(name: NSNotification.Name("HoloOpenAbout"), object: nil)
                }
            }
            
            // Help menu with feedback
            CommandGroup(replacing: .help) {
                Button("Send Feedback…") {
                    NotificationCenter.default.post(name: NSNotification.Name("HoloOpenFeedback"), object: nil)
                }
                .keyboardShortcut("?", modifiers: [.command, .shift])
                
                Button("Report Dogfood Feedback…") {
                    NotificationCenter.default.post(name: NSNotification.Name("HoloOpenDogfood"), object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .option])
                
                Divider()
                
                Button("Holo Browser Help") {
                    if let url = URL(string: "https://holobrowser.com/help") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        
        Settings {
            PreferencesView()
        }
        
        // About Window
        Window("About Holo Browser", id: "about") {
            AboutHoloBrowserView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
