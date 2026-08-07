import SwiftUI

/// Reusable Liquid Glass Empty State Component for Holo Browser V1.4.
/// Displays a clean icon, title, message, and optional call-to-action button when lists or search results are empty.
public struct HoloEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    public init(
        icon: String = "tray",
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(HoloTheme.Palette.holoCyan.opacity(0.8))
                .frame(width: 72, height: 72)
                .background(Circle().fill(HoloTheme.Palette.holoCyan.opacity(0.12)))
                .shadow(color: HoloTheme.Glow.cyan.opacity(0.2), radius: 12)
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HoloTheme.Text.primary)
                
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(HoloTheme.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 320)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(HoloPrimaryButtonStyle())
                .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
