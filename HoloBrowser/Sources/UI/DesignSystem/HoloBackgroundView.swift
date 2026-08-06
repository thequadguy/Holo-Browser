import SwiftUI

/// Phase 9: Dynamic Holo Background (True Liquid Glass Engine)
/// Provides behind-window optical translucency, environmental vibrancy, and subtle holographic light fields.
public struct HoloBackgroundView: View {
    @ObservedObject private var visualEngine = HoloVisualEngine.shared
    
    @State private var gradientRotation: Double = 0
    @State private var orbXOffset: CGFloat = -100
    @State private var orbYOffset: CGFloat = -50
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. True Behind-Window Optical Vibrancy (Allows Desktop Wallpapers & Background Windows to bleed through)
            VisualEffectViewWrapper(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            // 2. Ultra-sheer glass refraction tint (0.02 opacity for crystal optical clarity)
            Color.white.opacity(0.02)
                .ignoresSafeArea()
            
            // 3. Environment Light Fields (Subtle Holographic Caustics)
            if visualEngine.effectsLevel != .reduced {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    
                    ZStack {
                        // Ambient Spectral Cyan Light Field
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [HoloTheme.Palette.holoCyan.opacity(0.08), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: width * 0.4
                                )
                            )
                            .frame(width: width * 0.8)
                            .offset(x: orbXOffset, y: orbYOffset)
                            .blur(radius: 60)
                        
                        // Ambient Iridescent Purple Specular Field
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [HoloTheme.Palette.holoPurple.opacity(0.06), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: width * 0.35
                                )
                            )
                            .frame(width: width * 0.6)
                            .offset(x: width - orbXOffset - (width * 0.4), y: height - orbYOffset - (height * 0.4))
                            .blur(radius: 50)
                        
                        // Rotating Specular Caustics Overlay
                        if visualEngine.effectsLevel == .maximum {
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    HoloTheme.Palette.holoCyan.opacity(0.05),
                                    HoloTheme.Palette.holoBlue.opacity(0.06),
                                    HoloTheme.Palette.holoMagenta.opacity(0.04),
                                    .clear
                                ]),
                                center: .center,
                                angle: .degrees(gradientRotation)
                            )
                            .blur(radius: 30)
                            .blendMode(.screen)
                        }
                    }
                    .onAppear {
                        startAnimations(in: proxy.size)
                    }
                    .onChange(of: visualEngine.shouldAnimateContinuous) { _, animate in
                        if animate {
                            startAnimations(in: proxy.size)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func startAnimations(in size: CGSize) {
        guard visualEngine.shouldAnimateContinuous else { return }
        if visualEngine.effectsLevel == .reduced { return }
        
        let rotationDuration: Double = visualEngine.effectsLevel == .maximum ? 30 : 50
        let orbDuration: Double = visualEngine.effectsLevel == .maximum ? 20 : 35
        
        withAnimation(.linear(duration: rotationDuration).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
        
        withAnimation(.easeInOut(duration: orbDuration).repeatForever(autoreverses: true)) {
            orbXOffset = size.width * 0.25
            orbYOffset = size.height * 0.18
        }
    }
}
