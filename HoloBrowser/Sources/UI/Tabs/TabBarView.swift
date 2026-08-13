import SwiftUI

/// Floating glass tab bar component hosting liquid tab items, new tab creation, and tab overflow selection menu.
public struct TabBarView: View {
    @ObservedObject var tabManager: TabManager
    let activeProfileID: UUID
    var onNewTab: (() -> Void)?
    
    public init(tabManager: TabManager, activeProfileID: UUID, onNewTab: (() -> Void)? = nil) {
        self.tabManager = tabManager
        self.activeProfileID = activeProfileID
        self.onNewTab = onNewTab
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
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
                                        tabManager.closeTab(id: tab.id, currentProfileID: activeProfileID)
                                    }
                                }
                            )
                            .frame(minWidth: 110, maxWidth: 180)
                            .id(tab.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .onChange(of: tabManager.activeTabID) { oldID, newID in
                    if let newID = newID {
                        withAnimation {
                            proxy.scrollTo(newID, anchor: .center)
                        }
                    }
                }
            }
            
            // Tab Overview Grid Button (⌘⇧O)
            Button(action: {
                HoloEventBus.shared.post(.openTabOverview)
            }) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.gray.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Tab Overview & Holo Spaces (⌘⇧O)")
            
            // Tab Overflow Menu Button (Lists all open tabs for instant selection on smaller screens)
            if tabManager.tabs.count > 5 {

                Menu {
                    ForEach(tabManager.tabs) { tab in
                        Button(action: {
                            tabManager.selectTab(id: tab.id)
                        }) {
                            HStack {
                                if tab.id == tabManager.activeTabID {
                                    Image(systemName: "checkmark")
                                }
                                Text(tab.title.isEmpty ? (tab.url?.absoluteString ?? "New Tab") : tab.title)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "square.stack")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.gray.opacity(0.12)))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28, height: 28)
                .help("All Open Tabs (\(tabManager.tabs.count))")
            }
            
            // New Tab "+" Button
            Button(action: {
                withAnimation(HoloDesign.Animations.springFast) {
                    if let onNewTab = onNewTab {
                        onNewTab()
                    } else {
                        _ = tabManager.createNewTab()
                    }
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.gray.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .padding(.trailing, 8)
            .help("New Tab (⌘T)")
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }
}
