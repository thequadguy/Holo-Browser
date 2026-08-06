import SwiftUI

/// Reusable glassmorphic UI elements for Holo Browser.

public struct HoloGlassButton: View {
    let title: String
    let icon: String?
    let isProminent: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(
        title: String,
        icon: String? = nil,
        isProminent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isProminent = isProminent
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Group {
                    if isProminent {
                        HoloTheme.Palette.heroGradient
                    } else {
                        isHovered ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
                    }
                }
            )
            .foregroundColor(isProminent ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isProminent ? Color.white.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(HoloTheme.Animations.springSnappy, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Standardized Holo Buttons

public struct HoloPrimaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(HoloTheme.Palette.heroGradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: isHovered ? HoloTheme.Glow.cyan.opacity(0.5) : Color.black.opacity(0.3), radius: isHovered ? 8 : 4, y: 2)
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .animation(HoloTheme.Animations.springSnappy, value: isHovered)
            .animation(HoloTheme.Animations.easeOutFast, value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct HoloSecondaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.white.opacity(0.3) : Color.white.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(HoloTheme.Animations.springSnappy, value: isHovered)
            .animation(HoloTheme.Animations.easeOutFast, value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct HoloBadge: View {
    let text: String
    let color: Color
    
    public init(_ text: String, color: Color = .accentColor) {
        self.text = text
        self.color = color
    }
    
    public var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.16))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

public struct HoloShortcutBadge: View {
    let shortcut: String
    
    public init(_ shortcut: String) {
        self.shortcut = shortcut
    }
    
    public var body: some View {
        Text(shortcut)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.gray.opacity(0.18))
            .foregroundColor(.secondary)
            .cornerRadius(4)
    }
}
