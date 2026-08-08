import SwiftUI

/// Apple Vision Pro Spatial Liquid Glass Background Engine for Holo Browser V1.8.
/// Provides behind-window optical vibrancy, desktop wallpaper translucency, and quiet ice blue caustics.
public struct HoloBackgroundView: View {
    @ObservedObject private var visualEngine = HoloVisualEngine.shared
    
    @State private var orbXOffset: CGFloat = -100
    @State private var orbYOffset: CGFloat = -50
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. True Behind-Window Optical Vibrancy (Desktop Wallpapers bleed through)
            VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            // 2. Soft Crystal White Tint Fills
            Color.white.opacity(0.02)
                .ignoresSafeArea()
            
            // 3. Quiet Environment Light Fields (Soft Ice Blue & Soft Cyan Specular Caustics)
            if visualEngine.effectsLevel != .reduced {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    
                    ZStack {
                        // Soft Ice Blue Specular Light Field
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [HoloTheme.Palette.iceBlue.opacity(0.35), HoloTheme.Palette.holoCyan.opacity(0.12), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: width * 0.40
                                )
                            )
                            .frame(width: width * 0.75)
                            .offset(x: orbXOffset, y: orbYOffset)
                            .blur(radius: 50)
                            .blendMode(.screen)
                        
                        // Soft Pearl Violet Specular Light Field
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [HoloTheme.Palette.holoViolet.opacity(0.08), HoloTheme.Palette.softPearl.opacity(0.05), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: width * 0.35
                                )
                            )
                            .frame(width: width * 0.60)
                            .offset(x: width - orbXOffset - (width * 0.35), y: height - orbYOffset - (height * 0.35))
                            .blur(radius: 45)
                            .blendMode(.screen)
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
}
