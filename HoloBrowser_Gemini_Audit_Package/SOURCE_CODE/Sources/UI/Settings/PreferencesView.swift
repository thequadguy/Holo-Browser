import SwiftUI

/// Settings view scene for configuring Holo Browser preferences.
public struct PreferencesView: View {
    @AppStorage("homepageURL") private var homepageURL: String = "https://apple.com"
    @AppStorage("defaultSearchEngine") private var defaultSearchEngine: String = "Google"
    @AppStorage("downloadFolderPath") private var downloadFolderPath: String = "~/Downloads"
    @AppStorage("appearancePreference") private var appearancePreference: String = "System"
    
    public init() {}
    
    public var body: some View {
        Form {
            Section(header: Text("General Settings")) {
                TextField("Homepage URL", text: $homepageURL)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Default Search Engine", selection: $defaultSearchEngine) {
                    Text("Google").tag("Google")
                    Text("DuckDuckGo").tag("DuckDuckGo")
                    Text("Ecosia").tag("Ecosia")
                    Text("Kagi").tag("Kagi")
                }
                
                TextField("Download Folder", text: $downloadFolderPath)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section(header: Text("Appearance")) {
                Picker("Appearance", selection: $appearancePreference) {
                    Text("System Default").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
            }
        }
        .padding(20)
        .frame(width: 450, height: 260)
    }
}
