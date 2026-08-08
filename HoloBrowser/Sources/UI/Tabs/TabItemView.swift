import SwiftUI

/// Component representing an individual tab item in the tab bar strip with hover preview popover and dynamic Liquid Glass feedback.
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
                    .foregroundColor(HoloTheme.Palette.holoAmber)
            } else if tab.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: tab.faviconSymbol)
                    .font(.system(size: 11, weight: isActive ? .bold : .regular))
                    .foregroundColor(isActive ? HoloTheme.Palette.holoCyan : (tab.state == .suspended ? HoloTheme.Palette.holoViolet : .secondary))
            }
            
            // Tab Title
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .lineLimit(1)
                .foregroundColor(isActive ? HoloTheme.Text.primary : HoloTheme.Text.secondary)
                .frame(maxWidth: tab.isPinned ? 90 : 140, alignment: .leading)
            
            // Close Button (hidden for pinned tabs to prevent accidental closure)
            if !tab.isPinned {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isHovered || isActive ? HoloTheme.Text.secondary : .clear)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                        .background(
                            Circle()
                                .fill(isHovered ? Color.white.opacity(0.3) : Color.clear)
                                .frame(width: 16, height: 16)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            Group {
                if isActive {
                    ZStack {
                        VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.10))
                            
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.60), Color.white.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.02))
                        
                        if isHovered {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        }
                    }
                }
            }
        )
        .shadow(
            color: isActive ? Color.black.opacity(0.15) : (isHovered ? Color.black.opacity(0.05) : Color.clear),
            radius: isActive ? 6 : 3,
            x: 0,
            y: isActive ? 3 : 1
        )
        // Ensure active tab casts a subtle depth shadow onto lower components
        .zIndex(isActive ? 1 : 0)
        .scaleEffect(isHovered && !isActive ? 1.01 : 1.0)
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
                    .foregroundColor(HoloTheme.Palette.holoCyan)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title.isEmpty ? "New Tab" : tab.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(HoloTheme.Text.primary)
                        .lineLimit(1)
                    
                    Text(tab.domainHost ?? tab.url?.absoluteString ?? "Local Canvas")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(HoloTheme.Text.secondary)
                        .lineLimit(1)
                }
            }
            
            Divider()
            
            HStack {
                HoloBadge(tab.state.rawValue.capitalized, color: tab.state == .suspended ? HoloTheme.Palette.holoViolet : HoloTheme.Palette.holoBlue)
                
                Spacer()
                
                Text(tab.lastAccessedDate, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(HoloTheme.Text.secondary)
            }
        }
        .padding(12)
        .frame(width: 220)
        .holoGlassCard(cornerRadius: 12)
    }
}
