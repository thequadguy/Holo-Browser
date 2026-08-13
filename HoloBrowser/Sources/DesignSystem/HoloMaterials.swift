import SwiftUI
import AppKit

// MARK: - 6-Layer Apple Sheer Crystal Liquid Glass Multi-Layer Pipeline

/// Interactive Glass Card Modifier featuring continuous cursor light tracking, sheer translucency (22-38%),
/// top-left white specular highlights, and dynamic prismatic rainbow edge dispersion.
public struct HoloGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isHoveredBase: Bool
    let padding: CGFloat
    
    @ObservedObject private var lightingEngine = HoloGlassLightingEngine.shared
    @State private var mousePosition: CGPoint? = nil
    @State private var isHovering: Bool = false

    public func body(content: Content) -> some View {
        let hover = isHovering || isHoveredBase
        
        content
            .padding(padding)
            .background(
                ZStack {
                    // Layer 1: Background Blur Layer (Behind-Window Vibrancy)
                    VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                    
                    // Layer 2: Sheer Neutral Optical Fill (Quiet translucent fill)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(hover ? Color.white.opacity(0.04) : Color.white.opacity(0.01))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                // Layer 3: Quiet Neutral Specular Edge
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        hover ?
                        LinearGradient(
                            colors: [Color.white.opacity(0.30), Color.white.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            // Layer 4: Soft Neutral Elevation Shadow
            .shadow(
                color: hover ? Color.black.opacity(0.08) : Color.black.opacity(0.03),
                radius: hover ? 8 : 4,
                x: 0,
                y: hover ? 3 : 1
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    withAnimation(HoloTheme.Animations.opticalTracking) {
                        mousePosition = point
                        isHovering = true
                    }
                case .ended:
                    withAnimation(HoloTheme.Animations.easeOutFast) {
                        isHovering = false
                    }
                }
            }
    }
}

public struct HoloGlassBackgroundModifier: ViewModifier {
    let material: NSVisualEffectView.Material
    let cornerRadius: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectViewWrapper(material: material, blendingMode: .behindWindow)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.02))
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
            )
    }
}

// MARK: - View Extension Glass Modifiers (5 Sheer Apple Crystal Material Tiers)

public extension View {
    func holoGlassCard(cornerRadius: CGFloat = 12, isHovered: Bool = false, padding: CGFloat = 12) -> some View {
        self.modifier(HoloGlassCardModifier(cornerRadius: cornerRadius, isHoveredBase: isHovered, padding: padding))
    }
    
    func holoGlassBackground(material: NSVisualEffectView.Material = .popover, cornerRadius: CGFloat = 10) -> some View {
        self.modifier(HoloGlassBackgroundModifier(material: material, cornerRadius: cornerRadius))
    }
    
    /// Tier 1: Crystal Glass (Toolbar, Tab Bar, Navigation surfaces — Level 2, 14% fill)
    func holoCrystalGlass(cornerRadius: CGFloat = 12) -> some View {
        let tier = HoloDesign.MaterialTier.crystalGlass
        return self.background(
            ZStack {
                VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(tier.opacity))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(tier.specularRimGradient, lineWidth: 1)
            )
            .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 2)
        )
    }
    
    /// Tier 2: Clear Glass (Buttons, Small controls, Floating controls — Level 2/3, 20% fill)
    func holoClearGlass(cornerRadius: CGFloat = 12) -> some View {
        let tier = HoloDesign.MaterialTier.clearGlass
        return self.background(
            ZStack {
                VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(tier.opacity))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(tier.specularRimGradient, lineWidth: 1.0)
            )
            .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 2)
        )
    }
    
    /// Tier 3: Frost Glass (Sidebars, Cards, Settings panels — Level 3, 32% fill)
    func holoFrostGlass(cornerRadius: CGFloat = 16) -> some View {
        let tier = HoloDesign.MaterialTier.frostGlass
        return self.background(
            ZStack {
                VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(tier.opacity))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(tier.specularRimGradient, lineWidth: 1.0)
            )
            .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 4)
        )
    }
    
    /// Tier 4: Deep Glass (Popovers, Context Menus, Dropdowns — Level 4, 48% fill)
    func holoDeepGlass(cornerRadius: CGFloat = 18) -> some View {
        let tier = HoloDesign.MaterialTier.deepGlass
        return self.background(
            ZStack {
                VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(tier.opacity))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(tier.specularRimGradient, lineWidth: 1.0)
            )
            .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 6)
        )
    }
    
    /// Tier 5: Holo Glass (HoloMind surfaces & Vision Pro spatial cards — Level 5, optical crystal fill)
    func holoHoloGlass(cornerRadius: CGFloat = 18) -> some View {
        let tier = HoloDesign.MaterialTier.holoGlass
        return self.background(
            ZStack {
                VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.04))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(tier.specularRimGradient, lineWidth: 0.5)
            )
            .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 6)
        )
    }
    
    func holoFloatingGlass(cornerRadius: CGFloat = 12, isHovered: Bool = false) -> some View {
        self.modifier(HoloGlassCardModifier(cornerRadius: cornerRadius, isHoveredBase: isHovered, padding: 0))
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(HoloTheme.Animations.springSnappy, value: isHovered)
    }
    
    func holoDarkGlass(cornerRadius: CGFloat = 12) -> some View {
        self.holoFrostGlass(cornerRadius: cornerRadius)
    }
    
    func holoGlassTier(cornerRadius: CGFloat = 14, isHovered: Bool = false) -> some View {
        let tier = HoloDesign.MaterialTier.crystalGlass
        return self.background(
            ZStack {
                VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered ? Color.white.opacity(0.32) : Color.white.opacity(tier.opacity))
                
                if isHovered {
                    RadialGradient(
                        colors: [Color.white.opacity(0.45), HoloTheme.Palette.holoCyan.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                    .blendMode(.screen)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHovered ? HoloTheme.Palette.glassBorderGradient : tier.specularRimGradient, lineWidth: 1.0)
            )
            .shadow(color: isHovered ? HoloTheme.Glow.cyan.opacity(0.20) : tier.shadowColor, radius: isHovered ? 12 : tier.shadowRadius, y: isHovered ? 2 : 1)
        )
    }
    
    func holoSolidGlass(cornerRadius: CGFloat = 18) -> some View {
        self.holoDeepGlass(cornerRadius: cornerRadius)
    }
}
