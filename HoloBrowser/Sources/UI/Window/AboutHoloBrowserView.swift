import SwiftUI

/// Native macOS About panel for Holo Browser, shown via the Holo Browser → About menu item.
public struct AboutHoloBrowserView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(systemName: "globe.americas.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 12, y: 4)
            
            // App Name
            Text("Holo Browser")
                .font(.system(size: 22, weight: .bold, design: .default))
            
            // Version & Build
            VStack(spacing: 4) {
                Text("Version \(BuildConfiguration.appVersion)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Build \(BuildConfiguration.buildNumber)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            // Beta Badge
            if BuildConfiguration.isBeta {
                Text("PRIVATE BETA")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(6)
            }
            
            Divider()
                .frame(width: 200)
            
            // Copyright
            VStack(spacing: 2) {
                Text("© 2026 Holo Browser Project")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("Built with SwiftUI & WebKit")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(30)
        .frame(width: 320)
    }
}
