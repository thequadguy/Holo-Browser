import SwiftUI
import AppKit

/// Central design system tokens for Holo Browser (Colors, Typography, Spacing, Animations).
public enum HoloDesign {
    
    // MARK: - Liquid Glass Tier System (Apple visionOS & macOS Sonoma Calibrated)
    public enum GlassTier {
        case holoClear
        case holoGlass
        case holoFrost
        case holoSolid
        
        public var opacity: Double {
            switch self {
            case .holoClear: return 0.04
            case .holoGlass: return 0.08
            case .holoFrost: return 0.14
            case .holoSolid: return 0.32
            }
        }
        
        public var blurRadius: CGFloat {
            switch self {
            case .holoClear: return 16
            case .holoGlass: return 28
            case .holoFrost: return 40
            case .holoSolid: return 52
            }
        }
        
        public var saturation: Double {
            switch self {
            case .holoClear: return 1.40
            case .holoGlass: return 1.60
            case .holoFrost: return 1.25
            case .holoSolid: return 1.05
            }
        }
        
        public var brightness: Double {
            switch self {
            case .holoClear: return 1.15
            case .holoGlass: return 1.08
            case .holoFrost: return 1.02
            case .holoSolid: return 0.98
            }
        }
        
        public var material: NSVisualEffectView.Material {
            switch self {
            case .holoClear: return .hudWindow
            case .holoGlass: return .sidebar
            case .holoFrost: return .popover
            case .holoSolid: return .menu
            }
        }
        
        public var borderColor: Color {
            switch self {
            case .holoClear: return Color.white.opacity(0.35)
            case .holoGlass: return Color.white.opacity(0.40)
            case .holoFrost: return Color.white.opacity(0.45)
            case .holoSolid: return Color.white.opacity(0.50)
            }
        }
        
        public var specularRimGradient: LinearGradient {
            switch self {
            case .holoClear:
                return LinearGradient(
                    colors: [Color.white.opacity(0.65), Color.white.opacity(0.20), Color.cyan.opacity(0.30), Color.white.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .holoGlass:
                return LinearGradient(
                    colors: [Color.white.opacity(0.70), Color.cyan.opacity(0.35), Color.purple.opacity(0.25), Color.white.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .holoFrost:
                return LinearGradient(
                    colors: [Color.white.opacity(0.75), Color.cyan.opacity(0.40), HoloTheme.Palette.holoMagenta.opacity(0.30), Color.white.opacity(0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .holoSolid:
                return LinearGradient(
                    colors: [Color.white.opacity(0.80), Color.white.opacity(0.35), Color.cyan.opacity(0.25), Color.white.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        public var shadowColor: Color {
            switch self {
            case .holoClear: return Color.black.opacity(0.12)
            case .holoGlass: return Color.black.opacity(0.18)
            case .holoFrost: return Color.black.opacity(0.30)
            case .holoSolid: return Color.black.opacity(0.45)
            }
        }
        
        public var shadowRadius: CGFloat {
            switch self {
            case .holoClear: return 8
            case .holoGlass: return 18
            case .holoFrost: return 28
            case .holoSolid: return 40
            }
        }
    }
    
    // MARK: - Color Tokens
    public enum Colors {
        public static let glassBackground = Color(NSColor.windowBackgroundColor).opacity(0.40)
        public static let glassBorder = Color.white.opacity(0.30)
        public static let glassHover = Color.white.opacity(0.15)
        public static let activeTabGlow = Color(hex: "67E8F9").opacity(0.8)
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        public static let badgeBackground = Color(hex: "67E8F9").opacity(0.15)
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
    
    // MARK: - Animation Constants (visionOS Calibrated)
    public enum Animations {
        public static let springFast = Animation.spring(response: 0.22, dampingFraction: 0.72)
        public static let springNormal = Animation.spring(response: 0.28, dampingFraction: 0.78)
        public static let springBouncy = Animation.spring(response: 0.38, dampingFraction: 0.65)
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
