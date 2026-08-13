import SwiftUI
import WebKit

/// Dual-pane side-by-side browser view sharing Holo Liquid Glass design language.
/// Strictly reuses existing Tab & WKWebView instances without reloading or duplicating webviews.
public struct HoloSplitView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var environment: BrowserEnvironment
    let activeProfileID: UUID
    let isPrivateMode: Bool
    
    @State private var dragOffset: CGFloat = 0
    
    public init(
        tabManager: TabManager,
        environment: BrowserEnvironment,
        activeProfileID: UUID,
        isPrivateMode: Bool
    ) {
        self.tabManager = tabManager
        self.environment = environment
        self.activeProfileID = activeProfileID
        self.isPrivateMode = isPrivateMode
    }
    
    private var primaryTab: Tab? {
        guard let id = tabManager.splitState.primaryTabID else { return tabManager.activeTab }
        return tabManager.tabs.first(where: { $0.id == id })
    }
    
    private var secondaryTab: Tab? {
        guard let id = tabManager.splitState.secondaryTabID else { return nil }
        return tabManager.tabs.first(where: { $0.id == id })
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let minPaneWidth: CGFloat = 260
            let dividerWidth: CGFloat = 8
            
            let rawPrimaryWidth = totalWidth * CGFloat(tabManager.splitState.dividerRatio)
            let primaryWidth = min(max(minPaneWidth, rawPrimaryWidth), totalWidth - minPaneWidth - dividerWidth)
            let secondaryWidth = totalWidth - primaryWidth - dividerWidth
            
            HStack(spacing: 0) {
                // Primary Pane Container
                if let pTab = primaryTab {
                    PaneContainerView(
                        tab: pTab,
                        pane: .primary,
                        isActivePane: tabManager.splitState.activePane == .primary,
                        tabManager: tabManager,
                        environment: environment,
                        activeProfileID: activeProfileID,
                        isPrivateMode: isPrivateMode
                    )
                    .frame(width: primaryWidth)
                }
                
                // Interactive Liquid Glass Divider Bar
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                    
                    Rectangle()
                        .fill(HoloTheme.Palette.glassBorderGradient)
                        .frame(width: 1)
                }
                .frame(width: dividerWidth)
                .contentShape(Rectangle())
                .cursor(.resizeLeftRight)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newPrimaryWidth = primaryWidth + value.translation.width
                            let newRatio = Double(newPrimaryWidth / totalWidth)
                            let clampedRatio = min(max(0.25, newRatio), 0.75)
                            tabManager.splitState.dividerRatio = clampedRatio
                        }
                )
                .accessibilityLabel("Split View Resize Divider")
                .accessibilityHint("Drag left or right to resize split browser panes")
                
                // Secondary Pane Container
                if let sTab = secondaryTab {
                    PaneContainerView(
                        tab: sTab,
                        pane: .secondary,
                        isActivePane: tabManager.splitState.activePane == .secondary,
                        tabManager: tabManager,
                        environment: environment,
                        activeProfileID: activeProfileID,
                        isPrivateMode: isPrivateMode
                    )
                    .frame(width: secondaryWidth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Helper container representing one side of the split view with pane toolbar controls.
private struct PaneContainerView: View {
    @ObservedObject var tab: Tab
    let pane: SplitPane
    let isActivePane: Bool
    @ObservedObject var tabManager: TabManager
    @ObservedObject var environment: BrowserEnvironment
    let activeProfileID: UUID
    let isPrivateMode: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Pane Header Toolbar
            HStack(spacing: 8) {
                // Active Pane Indicator Glow
                Circle()
                    .fill(isActivePane ? HoloTheme.Palette.holoCyan : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .holoGlow(color: HoloTheme.Palette.holoCyan, radius: 4, isActive: isActivePane)
                
                Image(systemName: tab.faviconSymbol)
                    .font(.system(size: 11))
                    .foregroundColor(isActivePane ? HoloTheme.Palette.holoCyan : .secondary)
                
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .font(.system(size: 11, weight: isActivePane ? .bold : .medium))
                    .foregroundColor(isActivePane ? .white : .secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Replace Pane Tab Selection Menu
                Menu {
                    ForEach(tabManager.tabs.filter { $0.id != tab.id }) { t in
                        Button(t.title.isEmpty ? "New Tab" : t.title) {
                            tabManager.replaceSplitTab(pane: pane, newTabID: t.id)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(4)
                }
                .menuStyle(.borderlessButton)
                .help("Replace pane tab")
                .accessibilityLabel("Replace \(pane.rawValue) pane tab")
                
                // Exit Split View Button
                Button(action: {
                    tabManager.exitSplitView()
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Split View")
                .accessibilityLabel("Close Split View")
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Color.white.opacity(isActivePane ? 0.08 : 0.04))
            .overlay(
                Rectangle()
                    .fill(isActivePane ? HoloTheme.Palette.holoCyan.opacity(0.6) : Color.clear)
                    .frame(height: 1.5),
                alignment: .bottom
            )
            .onTapGesture {
                tabManager.setSplitActivePane(pane)
            }
            
            // Web Canvas
            if tab.url?.scheme == "holo" && tab.url?.host == "start" {
                HoloStartPageView(
                    mindEngine: environment.mindEngine,
                    tabManager: tabManager,
                    currentProfileID: activeProfileID,
                    isPrivateMode: isPrivateMode
                )
                .id(tab.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                WKWebViewWrapper(tab: tab)
                    .id(tab.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isActivePane ? AnyShapeStyle(HoloTheme.Palette.glassBorderGradient) : AnyShapeStyle(Color.clear), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(pane.rawValue.capitalized) browser pane: \(tab.title)")
    }
}
