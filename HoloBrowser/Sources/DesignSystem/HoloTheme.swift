import SwiftUI
import AppKit

/// Unified theme palette and dynamic glass design tokens for Holo Browser.
public enum HoloTheme {
    
    // MARK: - Holographic Accent Palette
    public enum Palette {
        public static let holoCyan = Color(hex: "67E8F9")
        public static let holoBlue = Color(hex: "60A5FA")
        public static let holoPurple = Color(hex: "C084FC")
        public static let holoMagenta = Color(hex: "F472B6")
        public static let holoEmerald = Color(hex: "34D399")
        public static let holoAmber = Color(hex: "FBBF24")
        
        public static let primaryAccent = holoCyan
        
        public static let heroGradient = LinearGradient(
            colors: [holoCyan, holoBlue, holoPurple, holoMagenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let glassBorderGradient = LinearGradient(
            colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Core Backgrounds
    public enum Backgrounds {
        public static let deep = Color(hex: "050508")
        public static let base = Color(hex: "0A0A0F")
        public static let elevated = Color(hex: "12121A")
        public static let panel = Color(hex: "1A1A24")
    }
    
    // MARK: - Text
    public enum Text {
        public static let primary = Color(hex: "F5F5F7")
        public static let secondary = Color(hex: "A1A1AA")
        public static let tertiary = Color(hex: "71717A")
    }
    
    // MARK: - Glass Materials
    public enum Glass {
        public static let fill = Color(red: 18/255, green: 18/255, blue: 26/255, opacity: 0.55)
        public static let fillStrong = Color(red: 26/255, green: 26/255, blue: 36/255, opacity: 0.72)
        public static let border = Color.white.opacity(0.10)
        public static let borderHover = Color.white.opacity(0.18)
        public static let highlight = Color.white.opacity(0.06)
        
        public static let backgroundUltraThin = fill
        public static let backgroundThin = fill
        public static let backgroundRegular = fillStrong
        public static let borderSubtle = border
        public static let borderFocused = borderHover
        public static let hoverHighlight = highlight
        public static let shadowColor = Color.black.opacity(0.65) // Deep shadow base
    }
    
    // MARK: - Glows
    public enum Glow {
        public static let cyan = Color(red: 103/255, green: 232/255, blue: 249/255, opacity: 0.25)
        public static let purple = Color(red: 192/255, green: 132/255, blue: 252/255, opacity: 0.25)
    }
    
    // MARK: - Motion & Physics Animations
    public enum Animations {
        public static let springSnappy = Animation.spring(response: 0.22, dampingFraction: 0.72)
        public static let springSmooth = Animation.spring(response: 0.35, dampingFraction: 0.82)
        public static let springBouncy = Animation.spring(response: 0.45, dampingFraction: 0.68)
        public static let easeOutFast = Animation.easeOut(duration: 0.15)
        public static let opticalTracking = Animation.interactiveSpring(response: 0.15, dampingFraction: 0.86)
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
