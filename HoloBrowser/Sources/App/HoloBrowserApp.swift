import SwiftUI

@main
struct HoloBrowserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var environment = BrowserEnvironment()
    
    var body: some Scene {
        WindowGroup {
            ContentView(environment: environment)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
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
                    HoloEventBus.shared.post(.newTabShortcut)
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
            
            // Preferences / Settings Menu (Cmd + ,)
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    HoloEventBus.shared.post(.openSettings)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
            
            // Replace default About menu item with custom About window / sheet
            CommandGroup(replacing: .appInfo) {
                Button("About Holo Browser") {
                    HoloEventBus.shared.post(.openAbout)
                }
            }
            
            // Help menu with feedback
            CommandGroup(replacing: .help) {
                Button("Send Feedback…") {
                    HoloEventBus.shared.post(.openFeedback)
                }
                .keyboardShortcut("?", modifiers: [.command, .shift])
                
                Button("Report Dogfood Feedback…") {
                    HoloEventBus.shared.post(.openDogfood)
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
    }
}
