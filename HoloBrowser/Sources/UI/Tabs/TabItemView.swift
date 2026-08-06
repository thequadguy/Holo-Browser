import SwiftUI

/// Component representing an individual tab item in the tab bar strip with hover preview popover and dynamic glass feedback.
public struct TabItemView: View {
    @ObservedObject var tab: Tab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var showPreviewPopover: Bool = false
    
    public init(tab: Tab, isActive: Bool, onSelect: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.tab = tab
        self.isActive = isActive
        self.onSelect = onSelect
        self.onClose = onClose
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            // Pinned indicator or Favicon SF Symbol or Loading Spinner
            if tab.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
            } else if tab.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: tab.faviconSymbol)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .accentColor : (tab.state == .suspended ? .purple : .secondary))
            }
            
            // Tab Title
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
                .lineLimit(1)
                .foregroundColor(isActive ? .primary : .secondary)
                .frame(maxWidth: tab.isPinned ? 90 : 140, alignment: .leading)
            
            // Close Button (hidden for pinned tabs to prevent accidental closure)
            if !tab.isPinned {
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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Group {
                if isActive {
                    VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.gray.opacity(0.12) : Color.clear)
                }
            }
        )
        .holoGlow(color: .accentColor, radius: 8, isActive: isActive)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? HoloTheme.Glass.borderFocused : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovered && !isActive ? 1.02 : 1.0)
        .animation(HoloTheme.Animations.springSnappy, value: isHovered)
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if self.isHovered && !self.isActive {
                        self.showPreviewPopover = true
                    }
                }
            } else {
                self.showPreviewPopover = false
            }
        }
        .popover(isPresented: $showPreviewPopover, arrowEdge: .bottom) {
            TabHoverPreviewCard(tab: tab)
        }
    }
}

/// Floating preview card popover rendered on tab hover.
private struct TabHoverPreviewCard: View {
    @ObservedObject var tab: Tab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: tab.faviconSymbol)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title.isEmpty ? "New Tab" : tab.title)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                    
                    Text(tab.domainHost ?? tab.url?.absoluteString ?? "Local Canvas")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Divider()
            
            HStack {
                HoloBadge(tab.state.rawValue.capitalized, color: tab.state == .suspended ? .purple : .blue)
                
                Spacer()
                
                Text(tab.lastAccessedDate, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 220)
        .holoFloatingGlass(cornerRadius: 12)
    }
}
