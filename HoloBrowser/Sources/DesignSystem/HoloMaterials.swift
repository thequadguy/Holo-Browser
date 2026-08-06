import SwiftUI
import AppKit

// MARK: - Liquid Glass Multi-Layer Rendering Pipeline (Apple visionOS & macOS Sonoma Standard)

/// Interactive Glass Card Modifier featuring continuous mouse tracking, optical refraction, specular rim lighting, and chromatic caustics.
public struct HoloGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isHoveredBase: Bool
    let padding: CGFloat
    
    @State private var mousePosition: CGPoint? = nil
    @State private var isHovering: Bool = false

    public func body(content: Content) -> some View {
        let hover = isHovering || isHoveredBase
        
        content
            .padding(padding)
            .background(
                GeometryReader { proxy in
                    let bounds = proxy.size
                    let mx = mousePosition?.x ?? bounds.width / 2
                    let my = mousePosition?.y ?? bounds.height / 2
                    
                    ZStack {
                        // 1. Native macOS Behind-Window Vibrancy Layer
                        VisualEffectViewWrapper(material: .sidebar, blendingMode: .behindWindow)
                        
                        // 2. Optical Glass Fill (Sheer 0.08 opacity for crystal visibility)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(hover ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                        
                        // 3. Dynamic Interactive Refraction Beam on Hover
                        if hover {
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    HoloTheme.Palette.holoCyan.opacity(0.15),
                                    .clear
                                ]),
                                center: UnitPoint(x: mx / max(bounds.width, 1), y: my / max(bounds.height, 1)),
                                startRadius: 0,
                                endRadius: max(bounds.width, bounds.height) * 0.75
                            )
                            .blendMode(.screen)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                GeometryReader { proxy in
                    let bounds = proxy.size
                    let mx = mousePosition?.x ?? bounds.width / 2
                    let my = mousePosition?.y ?? bounds.height / 2
                    let dx = (mx - bounds.width / 2) / max(bounds.width, 1)
                    let dy = (my - bounds.height / 2) / max(bounds.height, 1)
                    let chromaticX = hover ? dx * 2.0 : 0
                    let chromaticY = hover ? dy * 2.0 : 0
                    
                    ZStack {
                        // 4. Top-Left Specular Light Rim Catch (Simulates studio light reflecting on physical glass edge)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                hover ?
                                LinearGradient(
                                    colors: [Color.white.opacity(0.85), Color.cyan.opacity(0.50), Color.purple.opacity(0.35), Color.white.opacity(0.20)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.45), Color.white.opacity(0.15), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                        
                        // 5. Chromatic Dispersion Prism Sheen on Mouse Interaction
                        if hover {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(HoloTheme.Palette.holoCyan.opacity(0.35), lineWidth: 0.5)
                                .offset(x: chromaticX, y: chromaticY)
                                .blendMode(.screen)
                            
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(HoloTheme.Palette.holoMagenta.opacity(0.35), lineWidth: 0.5)
                                .offset(x: -chromaticX, y: -chromaticY)
                                .blendMode(.screen)
                        }
                    }
                }
            )
            .shadow(
                color: hover ? HoloTheme.Glow.cyan.opacity(0.5) : Color.black.opacity(0.18),
                radius: hover ? 20 : 10,
                x: 0,
                y: hover ? 6 : 3
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
                        .fill(Color.white.opacity(0.06))
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.45), Color.white.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            )
    }
}

// MARK: - View Extension Glass Modifiers

public extension View {
    func holoGlassCard(cornerRadius: CGFloat = 12, isHovered: Bool = false, padding: CGFloat = 12) -> some View {
        self.modifier(HoloGlassCardModifier(cornerRadius: cornerRadius, isHoveredBase: isHovered, padding: padding))
    }
    
    func holoGlassBackground(material: NSVisualEffectView.Material = .sidebar, cornerRadius: CGFloat = 10) -> some View {
        self.modifier(HoloGlassBackgroundModifier(material: material, cornerRadius: cornerRadius))
    }
    
    func holoUltraGlass(cornerRadius: CGFloat = 12) -> some View {
        let tier = HoloDesign.GlassTier.holoClear
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
    
    func holoCrystalGlass(cornerRadius: CGFloat = 12) -> some View {
        let tier = HoloDesign.GlassTier.holoGlass
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
            .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 4)
        )
    }
    
    func holoFloatingGlass(cornerRadius: CGFloat = 12, isHovered: Bool = false) -> some View {
        self.modifier(HoloGlassCardModifier(cornerRadius: cornerRadius, isHoveredBase: isHovered, padding: 0))
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(HoloTheme.Animations.springSnappy, value: isHovered)
    }
    
    func holoDarkGlass(cornerRadius: CGFloat = 12) -> some View {
        let tier = HoloDesign.GlassTier.holoFrost
        return self.background(
            ZStack {
                VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(tier.opacity))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(tier.specularRimGradient, lineWidth: 1)
            )
            .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 6)
        )
    }
    
    // MARK: - 4-Tier Liquid Glass Modifiers (Apple visionOS & macOS Sonoma Standard)
    
    /// Tier 1: HoloClear (Ultra-clear optical glass lens for Address Bar & Search Pills)
    func holoClearGlass(cornerRadius: CGFloat = 12) -> some View {
        let tier = HoloDesign.GlassTier.holoClear
        return self
            .background(
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
    
    /// Tier 2: HoloGlass (Main UI Chrome material for Floating Tab Bar, Navigation Toolbar, Floating Panels)
    func holoGlassTier(cornerRadius: CGFloat = 14, isHovered: Bool = false) -> some View {
        let tier = HoloDesign.GlassTier.holoGlass
        return self
            .background(
                ZStack {
                    VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isHovered ? Color.white.opacity(0.14) : Color.white.opacity(tier.opacity))
                    
                    if isHovered {
                        RadialGradient(
                            colors: [HoloTheme.Palette.holoCyan.opacity(0.20), .clear],
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
                .shadow(color: isHovered ? HoloTheme.Glow.cyan.opacity(0.4) : tier.shadowColor, radius: isHovered ? 20 : tier.shadowRadius, y: isHovered ? 6 : 4)
            )
    }
    
    /// Tier 3: HoloFrost (High-contrast control surfaces for Sidebars, Popovers, Dock Cards)
    func holoFrostGlass(cornerRadius: CGFloat = 16) -> some View {
        let tier = HoloDesign.GlassTier.holoFrost
        return self
            .background(
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
    
    /// Tier 4: HoloSolid (Elevated Dialogs, Settings Windows, Modal Cards)
    func holoSolidGlass(cornerRadius: CGFloat = 18) -> some View {
        let tier = HoloDesign.GlassTier.holoSolid
        return self
            .background(
                ZStack {
                    VisualEffectViewWrapper(material: tier.material, blendingMode: .behindWindow)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.black.opacity(tier.opacity))
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(tier.specularRimGradient, lineWidth: 1.0)
                )
                .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 10)
            )
    }
}
