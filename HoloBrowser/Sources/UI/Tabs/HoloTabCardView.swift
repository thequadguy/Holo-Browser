import SwiftUI

/// Card component inside the spatial tab overview grid.
struct HoloTabCardView: View {
    @ObservedObject var tab: Tab
    let isActive: Bool
    let spaces: [HoloSpace]
    @ObservedObject var tabManager: TabManager
    let onSelect: () -> Void
    let onSplit: () -> Void
    let onClose: () -> Void
    let onAssignSpace: (UUID?) -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Favicon & Close Button
            HStack(spacing: 8) {
                Image(systemName: tab.faviconSymbol)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? HoloTheme.Palette.holoCyan : .secondary)

                Text(tab.domainHost ?? "Local Canvas")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close tab \(tab.title)")
            }

            // Tab Title
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(maxHeight: 38, alignment: .topLeading)

            Spacer()

            // Card Footer (Space Assignment & Badges)
            HStack {
                Menu {
                    Button("No Space (Unassigned)") { onAssignSpace(nil) }
                    ForEach(spaces) { space in
                        Button(space.name) { onAssignSpace(space.id) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 10))
                        Text(currentSpaceName())
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(HoloTheme.Palette.holoCyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(HoloTheme.Palette.holoCyan.opacity(0.15)))
                }
                .menuStyle(.borderlessButton)

                Spacer()

                if isActive {
                    HoloBadge("Active", color: HoloTheme.Palette.holoCyan)
                } else {
                    Button(action: {
                        if let activeID = tabManager.activeTabID {
                            tabManager.enterSplitView(primaryID: activeID, secondaryID: tab.id)
                            onSplit()
                        }
                    }, label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.split.2x1")
                                .font(.system(size: 10))
                            Text("Split")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(HoloTheme.Palette.holoCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(HoloTheme.Palette.holoCyan.opacity(0.12)))
                    })
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open tab in Split View")
                }
            }
        }
        .padding(14)
        .frame(height: 140)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: isHovered ? Color.black.opacity(0.25) : Color.black.opacity(0.1),
            radius: isHovered ? 8 : 4,
            y: 3
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(HoloTheme.Animations.springSnappy, value: isHovered)
        .onTapGesture { onSelect() }
        .onHover { isHovered = $0 }
    }

    private var cardBackground: some View {
        ZStack {
            VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isActive
                        ? Color.white.opacity(0.14)
                        : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                )
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isActive
                        ? AnyShapeStyle(HoloTheme.Palette.holoBlueTextGradient)
                        : (isHovered
                            ? AnyShapeStyle(Color.white.opacity(0.25))
                            : AnyShapeStyle(Color.white.opacity(0.12))),
                    lineWidth: isActive ? 1.2 : 0.6
                )
        }
    }

    private func currentSpaceName() -> String {
        for space in spaces where space.containsTab(id: tab.id) {
            return space.name
        }
        return "Space"
    }
}
