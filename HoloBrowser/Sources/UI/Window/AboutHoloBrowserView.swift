import SwiftUI

/// Native macOS About panel for Holo Browser V1.4 Closed Beta Release.
public struct AboutHoloBrowserView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            // App Hero Icon
            Image(systemName: "globe.americas.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(HoloTheme.Palette.heroGradient)
                .shadow(color: HoloTheme.Glow.cyan, radius: 14, y: 2)
            
            // App Title & Tagline
            VStack(spacing: 4) {
                Text("Holo Browser")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(HoloTheme.Text.primary)
                Text("Liquid Glass Native Browser for macOS")
                    .font(.system(size: 11))
                    .foregroundColor(HoloTheme.Text.secondary)
            }
            
            // Version & Build Badge
            HStack(spacing: 8) {
                Text("v1.4.0 Closed Beta")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(HoloTheme.Palette.holoCyan.opacity(0.15))
                    .foregroundColor(HoloTheme.Palette.holoCyan)
                    .cornerRadius(6)
                
                Text("Build 1400")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(HoloTheme.Text.secondary)
            }
            
            Divider()
                .frame(width: 220)
            
            // System Diagnostics Summary
            VStack(spacing: 6) {
                HStack {
                    Text("Engine:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(HoloTheme.Text.secondary)
                    Spacer()
                    Text("Apple WebKit (Swift 5.10)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(HoloTheme.Text.primary)
                }
                
                HStack {
                    Text("Architecture:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(HoloTheme.Text.secondary)
                    Spacer()
                    Text("Native macOS AppKit/SwiftUI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(HoloTheme.Text.primary)
                }
                
                HStack {
                    Text("Intelligence:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(HoloTheme.Text.secondary)
                    Spacer()
                    Text("HoloMind AI Layer v1.4")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(HoloTheme.Palette.holoCyan)
                }
            }
            .padding(12)
            .holoFrostGlass(cornerRadius: 10)
            .frame(width: 260)
            
            // Legal Copyright
            VStack(spacing: 2) {
                Text("© 2026 Holo Browser Project")
                    .font(.system(size: 10))
                    .foregroundColor(HoloTheme.Text.secondary)
                Text("All rights reserved • Confidential Closed Beta")
                    .font(.system(size: 9))
                    .foregroundColor(HoloTheme.Text.secondary.opacity(0.7))
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(
            ZStack {
                VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
                HoloTheme.Palette.chromeFill
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(HoloTheme.Palette.glassBorderGradient, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
