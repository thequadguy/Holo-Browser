import SwiftUI

/// Floating glass tab bar component hosting liquid tab items and new tab creation.
public struct TabBarView: View {
    @ObservedObject var tabManager: TabManager
    
    public init(tabManager: TabManager) {
        self.tabManager = tabManager
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabManager.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == tabManager.activeTabID,
                            onSelect: {
                                withAnimation(HoloDesign.Animations.springFast) {
                                    tabManager.selectTab(id: tab.id)
                                }
                            },
                            onClose: {
                                withAnimation(HoloDesign.Animations.springFast) {
                                    tabManager.closeTab(id: tab.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            
            // New Tab "+" Button
            Button(action: {
                withAnimation(HoloDesign.Animations.springFast) {
                    _ = tabManager.createNewTab()
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.gray.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .padding(.trailing, 8)
            .help("New Tab (⌘T)")
        }
        .background(
            VisualEffectViewWrapper(material: .sidebar, blendingMode: .withinWindow)
        )
        .overlay(
            Divider(), alignment: .bottom
        )
    }
}
