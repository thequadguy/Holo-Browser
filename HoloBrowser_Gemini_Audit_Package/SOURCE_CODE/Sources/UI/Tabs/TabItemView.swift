import SwiftUI

/// Component representing an individual tab item in the tab bar strip.
public struct TabItemView: View {
    @ObservedObject var tab: Tab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(tab: Tab, isActive: Bool, onSelect: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.tab = tab
        self.isActive = isActive
        self.onSelect = onSelect
        self.onClose = onClose
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            // Loading indicator or globe icon
            if tab.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: tab.state == .suspended ? "moon.fill" : "globe")
                    .font(.system(size: 11))
                    .foregroundColor(isActive ? .accentColor : .secondary)
            }
            
            // Title
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
                .lineLimit(1)
                .foregroundColor(isActive ? .primary : .secondary)
                .frame(maxWidth: 140, alignment: .leading)
            
            // Close Button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isHovered || isActive ? .secondary : .clear)
                    .padding(3)
                    .background(
                        Circle()
                            .fill(isHovered ? Color.gray.opacity(0.2) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(NSColor.controlBackgroundColor) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.gray.opacity(0.25) : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
