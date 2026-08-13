import SwiftUI

/// Apple Vision Pro Spatial Liquid Glass Background Engine for Holo Browser V1.8.
/// Provides behind-window optical vibrancy, desktop wallpaper translucency, and quiet ice blue caustics.
public struct HoloBackgroundView: View {
    @ObservedObject private var visualEngine = HoloVisualEngine.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. Deep Neutral Charcoal Foundation
            Color(hex: "0B0C10")
                .ignoresSafeArea()
            
            // 2. True Behind-Window Optical Vibrancy (Vibrant Dark)
            VisualEffectViewWrapper(material: .underWindowBackground, blendingMode: .behindWindow, appearance: NSAppearance(named: .vibrantDark))
                .ignoresSafeArea()
            
            // 3. Subtle Cool Blue-Violet Atmospheric Illumination
            if visualEngine.effectsLevel != .reduced {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    
                    RadialGradient(
                        colors: [
                            Color(hex: "38BDF8").opacity(0.18),
                            Color(hex: "1E293B").opacity(0.10),
                            Color(hex: "0F172A").opacity(0.04),
                            .clear
                        ],
                        center: UnitPoint(x: 0.3, y: 0.25),
                        startRadius: 0,
                        endRadius: max(width, height) * 0.75
                    )
                    .blendMode(.screen)
                }
                .ignoresSafeArea()
            }
        }
    }
}
