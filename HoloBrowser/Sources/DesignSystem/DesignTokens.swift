import SwiftUI
import AppKit

/// Central design system tokens for Holo Browser (5 Sheer Apple Crystal Material Tiers, Typography, Spacing, Animations).
public enum HoloDesign {
    
    // MARK: - 5 Sheer Apple Crystal Material Tiers (Apple Vision Pro Spatial Standards)
    public enum MaterialTier {
        case crystalGlass  // Level 2: Toolbar, Tab bar, Navigation surfaces (14% fill)
        case clearGlass    // Level 2/3: Buttons, Small controls, Floating controls (20% fill)
        case frostGlass    // Level 3: Sidebars, Cards, Settings panels (32% fill)
        case deepGlass     // Level 4: Popovers, Context Menus, Dropdowns (48% fill)
        case holoGlass     // Level 5: HoloMind AI surfaces & Vision Pro spatial cards (58% fill)
        
        public var opacity: Double {
            switch self {
            case .crystalGlass: return 0.02
            case .clearGlass: return 0.05
            case .frostGlass: return 0.08
            case .deepGlass: return 0.12
            case .holoGlass: return 0.15
            }
        }
        
        public var blurRadius: CGFloat {
            switch self {
            case .crystalGlass: return 20
            case .clearGlass: return 28
            case .frostGlass: return 42
            case .deepGlass: return 54
            case .holoGlass: return 66
            }
        }
        
        public var material: NSVisualEffectView.Material {
            switch self {
            case .crystalGlass: return .popover
            case .clearGlass: return .titlebar
            case .frostGlass: return .popover
            case .deepGlass: return .popover
            case .holoGlass: return .menu
            }
        }
        
        public var specularRimGradient: LinearGradient {
            switch self {
            case .crystalGlass:
                return LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.08), Color.white.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .clearGlass:
                return LinearGradient(
                    colors: [Color.white.opacity(0.20), Color.white.opacity(0.10), Color.white.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .frostGlass:
                return LinearGradient(
                    colors: [Color.white.opacity(0.22), Color.white.opacity(0.12), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .deepGlass:
                return LinearGradient(
                    colors: [Color.white.opacity(0.24), Color.white.opacity(0.14), Color.white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .holoGlass:
                return LinearGradient(
                    colors: [Color.white.opacity(0.28), HoloTheme.Palette.holoCyan.opacity(0.15), Color.white.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        public var shadowColor: Color {
            switch self {
            case .crystalGlass: return Color.black.opacity(0.03)
            case .clearGlass: return Color.black.opacity(0.04)
            case .frostGlass: return Color.black.opacity(0.05)
            case .deepGlass: return Color.black.opacity(0.07)
            case .holoGlass: return Color.black.opacity(0.10)
            }
        }
        
        public var shadowRadius: CGFloat {
            switch self {
            case .crystalGlass: return 6
            case .clearGlass: return 10
            case .frostGlass: return 14
            case .deepGlass: return 20
            case .holoGlass: return 28
            }
        }
    }
    
    // Legacy compatibility mapping
    public typealias GlassTier = MaterialTier
    
    // MARK: - Color Tokens
    public enum Colors {
        public static let glassBackground = Color.white.opacity(0.25)
        public static let glassBorder = Color.white.opacity(0.45)
        public static let glassHover = Color.white.opacity(0.35)
        public static let activeTabGlow = HoloTheme.Palette.holoCyan.opacity(0.35)
        public static let textPrimary = Color(NSColor.labelColor)
        public static let textSecondary = Color(NSColor.secondaryLabelColor)
        public static let badgeBackground = HoloTheme.Palette.appleBlue.opacity(0.12)
    }
    
    // MARK: - Spacing Grid Tokens
    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }
    
    // MARK: - Typography System
    public enum Typography {
        public static let title = Font.system(size: 14, weight: .semibold, design: .default)
        public static let body = Font.system(size: 13, weight: .regular, design: .default)
        public static let addressBar = Font.system(size: 13, weight: .regular, design: .monospaced)
        public static let tabTitle = Font.system(size: 12, weight: .medium, design: .default)
        public static let caption = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Motion Physics Animations
    public enum Animations {
        public static let springFast = Animation.spring(response: 0.22, dampingFraction: 0.76)
        public static let springNormal = Animation.spring(response: 0.32, dampingFraction: 0.82)
        public static let springBouncy = Animation.spring(response: 0.42, dampingFraction: 0.68)
        public static let easeSmooth = Animation.easeInOut(duration: 0.2)
    }
    
    // MARK: - Corner Radius Tokens
    public enum CornerRadius {
        public static let small: CGFloat = 6
        public static let medium: CGFloat = 10
        public static let large: CGFloat = 14
        public static let pill: CGFloat = 20
    }
}
