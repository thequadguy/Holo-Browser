import SwiftUI
import AppKit

/// Unified Apple Liquid Glass theme palette, 6-level elevation system, and sheer translucency tokens for Holo Browser V1.5.1.
/// Calibrated for Apple Vision Pro spatial materials and macOS Sequoia Liquid Glass standards.
public enum HoloTheme {
    
    // MARK: - Apple Liquid Glass & Holographic Accent Palette
    public enum Palette {
        public static let crystalWhite = Color(hex: "FFFFFF")
        public static let frostWhite = Color(hex: "F8FAFC")
        public static let iceBlue = Color(hex: "E0F2FE")
        public static let softPearl = Color(hex: "FAFAFA")
        
        public static let appleBlue = Color(hex: "007AFF")
        public static let holoBlue = appleBlue
        public static let holoCyan = Color(hex: "38BDF8")
        public static let holoViolet = Color(hex: "A855F7")
        public static let holoPink = Color(hex: "EC4899")
        public static let holoEmerald = Color(hex: "34D399")
        public static let holoAmber = Color(hex: "FBBF24")
        
        public static let primaryAccent = appleBlue
        
        /// Soft spectral hero gradient reflecting crystal light
        public static let heroGradient = LinearGradient(
            colors: [appleBlue, holoCyan, holoViolet, holoPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Pure white specular glass border gradient with soft prismatic iridescence
        public static let glassBorderGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.85),
                Color.white.opacity(0.45),
                holoCyan.opacity(0.30),
                holoViolet.opacity(0.20),
                Color.white.opacity(0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Pure Apple Vision Pro crystal specular rim gradient (quiet, white light highlight with subtle ice blue sheen)
        public static let crystalSpecularGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.92),
                Color.white.opacity(0.50),
                iceBlue.opacity(0.35),
                holoCyan.opacity(0.18),
                Color.white.opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Backward compatibility alias
        public static let rainbowIridescentGradient = crystalSpecularGradient
    }
    
    // MARK: - 6-Level Elevation Hierarchy System (Apple Sheer Spatial Glass Standard)
    public enum Elevation {
        /// Level 0: Desktop Wallpapers / Canvas Background
        public static let level0Blur: CGFloat = 0
        public static let level0Opacity: Double = 0.04
        public static let level0ShadowRadius: CGFloat = 0
        
        /// Level 1: Main Browser Canvas Shell
        public static let level1Blur: CGFloat = 18
        public static let level1Opacity: Double = 0.12
        public static let level1ShadowRadius: CGFloat = 4
        
        /// Level 2: Toolbar, Sidebar, Floating Tab Bar (Crystal & Clear Glass)
        public static let level2Blur: CGFloat = 28
        public static let level2Opacity: Double = 0.18
        public static let level2ShadowRadius: CGFloat = 8
        
        /// Level 3: Cards, Panels, Settings Surfaces (Frost Glass)
        public static let level3Blur: CGFloat = 42
        public static let level3Opacity: Double = 0.32
        public static let level3ShadowRadius: CGFloat = 14
        
        /// Level 4: Popovers, Context Menus, Dropdowns (Deep Glass)
        public static let level4Blur: CGFloat = 54
        public static let level4Opacity: Double = 0.48
        public static let level4ShadowRadius: CGFloat = 20
        
        /// Level 5: Dialogs, Modal Sheets, HoloMind Spatial Overlay (Holo Glass)
        public static let level5Blur: CGFloat = 66
        public static let level5Opacity: Double = 0.62
        public static let level5ShadowRadius: CGFloat = 28
    }
    
    // MARK: - Unified Studio Lighting Tokens
    public enum Lighting {
        public static let keySpecularHighlight = Color.white.opacity(0.80)
        public static let ambientTint = Color.white.opacity(0.18)
        public static let rimCyanShimmer = Palette.holoCyan.opacity(0.30)
        public static let rimVioletShimmer = Palette.holoViolet.opacity(0.20)
        public static let rimPinkShimmer = Palette.holoPink.opacity(0.15)
        public static let elevationShadow = Color.black.opacity(0.04) // Delicate, soft elevation drop shadow
    }
    
    // MARK: - Core Luminous Translucent Backgrounds (Sheer Spatial Translucency)
    public enum Backgrounds {
        public static let deep = Color.white.opacity(0.06)
        public static let base = Color.white.opacity(0.12)
        public static let elevated = Color.white.opacity(0.22)
        public static let panel = Color.white.opacity(0.35)
    }
    
    // MARK: - Glass Materials
    public enum Glass {
        public static let fill = Color.white.opacity(0.16)
        public static let fillStrong = Color.white.opacity(0.36)
        public static let border = Color.white.opacity(0.35)
        public static let borderHover = Color.white.opacity(0.65)
        public static let highlight = Color.white.opacity(0.50)
        
        public static let backgroundUltraThin = fill
        public static let backgroundThin = fill
        public static let backgroundRegular = fillStrong
        public static let borderSubtle = border
        public static let borderFocused = borderHover
        public static let hoverHighlight = highlight
        public static let shadowColor = Color.black.opacity(0.04)
    }
    
    // MARK: - Soft Spectral Glows
    public enum Glow {
        public static let cyan = Palette.holoCyan.opacity(0.20)
        public static let purple = Palette.holoViolet.opacity(0.18)
        public static let white = Color.white.opacity(0.30)
    }
    
    // MARK: - Text
    public enum Text {
        public static let primary = Color(NSColor.labelColor)
        public static let secondary = Color(NSColor.secondaryLabelColor)
        public static let tertiary = Color(NSColor.tertiaryLabelColor)
    }
    
    // MARK: - Motion & Physics Animations
    public enum Animations {
        public static let springSnappy = Animation.spring(response: 0.24, dampingFraction: 0.78)
        public static let springSmooth = Animation.spring(response: 0.38, dampingFraction: 0.85)
        public static let springBouncy = Animation.spring(response: 0.48, dampingFraction: 0.72)
        public static let easeOutFast = Animation.easeOut(duration: 0.18)
        public static let opticalTracking = Animation.interactiveSpring(response: 0.18, dampingFraction: 0.88)
    }
}

public extension Color {
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hexClean.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
