import SwiftUI
import AppKit

/// Central design system tokens for Holo Browser (Colors, Typography, Spacing, Animations).
public enum HoloDesign {
    
    // MARK: - Color Tokens
    public enum Colors {
        public static let glassBackground = Color(NSColor.windowBackgroundColor).opacity(0.75)
        public static let glassBorder = Color.gray.opacity(0.2)
        public static let glassHover = Color.gray.opacity(0.12)
        public static let activeTabGlow = Color.accentColor.opacity(0.8)
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        public static let badgeBackground = Color.accentColor.opacity(0.15)
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
    
    // MARK: - Animation Constants
    public enum Animations {
        public static let springFast = Animation.spring(response: 0.25, dampingFraction: 0.75)
        public static let springNormal = Animation.spring(response: 0.35, dampingFraction: 0.8)
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
