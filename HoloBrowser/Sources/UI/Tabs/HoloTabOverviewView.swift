import SwiftUI
import AppKit

/// Spatial Liquid Glass Tab Overview overlay supporting Holo Spaces, tab search,
/// duplicate tab alerts, and space switching.
public struct HoloTabOverviewView: View {
    @ObservedObject var tabManager: TabManager
    let activeProfileID: UUID
    @Binding var isPresented: Bool

    @State private var searchQuery: String = ""
    @State private var selectedFilter: TabOverviewFilter = .all
    @State private var newSpaceName: String = ""
    @State private var showNewSpaceField: Bool = false

    public enum TabOverviewFilter: String, CaseIterable, Identifiable {
        case all = "All Tabs"
        case active = "Active"
        case duplicates = "Duplicates"

        public var id: String { rawValue }
    }

    public init(tabManager: TabManager, activeProfileID: UUID, isPresented: Binding<Bool>) {
        self.tabManager = tabManager
        self.activeProfileID = activeProfileID
        self._isPresented = isPresented
    }

    private var filteredTabs: [Tab] {
        let profileTabs = tabManager.tabs
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return profileTabs.filter { tab in
            let matchesQuery = query.isEmpty ||
                tab.title.lowercased().contains(query) ||
                (tab.url?.absoluteString.lowercased().contains(query) ?? false) ||
                (tab.domainHost?.lowercased().contains(query) ?? false)

            guard matchesQuery else { return false }

            switch selectedFilter {
            case .all:
                return true
            case .active:
                return tab.state == .active
            case .duplicates:
                if let normalized = SmartTabEngine.shared.normalizeURL(tab.url) {
                    return (SmartTabEngine.shared.duplicateGroups[normalized]?.count ?? 0) > 1
                }
                return false
            }
        }
    }

    public var body: some View {
        ZStack {
            // Background Spatial Blur
            VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 20) {
                // Header Bar (Search, Spaces Selector, Filter Chips & Close)
                headerBarView

                // Holo Spaces Bar
                HStack(spacing: 12) {
                    Button(action: {
                        tabManager.selectSpace(id: nil)
                    }, label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.stack.fill")
                            Text("All Tabs (\(tabManager.tabs.count))")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            tabManager.activeSpaceID == nil
                                ? AnyShapeStyle(HoloTheme.Palette.heroGradient)
                                : AnyShapeStyle(Color.white.opacity(0.08))
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.5))
                    })
                    .buttonStyle(.plain)

                    ForEach(tabManager.spaces(for: activeProfileID)) { space in
                        Button(action: {
                            tabManager.selectSpace(id: space.id)
                        }, label: {
                            HStack(spacing: 6) {
                                Image(systemName: space.icon)
                                    .foregroundColor(Color(hex: space.colorHex))
                                Text(space.name)
                                Text("(\(space.tabIDs.count))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                tabManager.activeSpaceID == space.id
                                    ? AnyShapeStyle(Color(hex: space.colorHex).opacity(0.25))
                                    : AnyShapeStyle(Color.white.opacity(0.08))
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    tabManager.activeSpaceID == space.id
                                        ? Color(hex: space.colorHex)
                                        : Color.white.opacity(0.20),
                                    lineWidth: 0.8
                                )
                            )
                        })
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete Space") {
                                tabManager.deleteSpace(id: space.id)
                            }
                        }
                    }

                    if showNewSpaceField {
                        HStack(spacing: 6) {
                            TextField("Space Name", text: $newSpaceName, onCommit: {
                                let trimmed = newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    tabManager.createSpace(name: trimmed, profileID: activeProfileID)
                                }
                                newSpaceName = ""
                                showNewSpaceField = false
                            })
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 110)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .overlay(Capsule().stroke(HoloTheme.Palette.holoCyan, lineWidth: 1))
                    } else {
                        Button(action: { showNewSpaceField = true }, label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("New Space")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(HoloTheme.Palette.holoCyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(HoloTheme.Palette.holoCyan.opacity(0.12)))
                        })
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)

                // Spatial Tab Cards Grid
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(filteredTabs) { tab in
                            HoloTabCardView(
                                tab: tab,
                                isActive: tab.id == tabManager.activeTabID,
                                spaces: tabManager.spaces(for: activeProfileID),
                                tabManager: tabManager,
                                onSelect: {
                                    tabManager.selectTab(id: tab.id)
                                    isPresented = false
                                },
                                onSplit: {
                                    isPresented = false
                                },
                                onClose: {
                                    tabManager.closeTab(id: tab.id, currentProfileID: activeProfileID)
                                },
                                onAssignSpace: { spaceID in
                                    tabManager.assignTabToSpace(tabID: tab.id, spaceID: spaceID)
                                }
                            )
                        }
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: 1080, maxHeight: 720)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: "0F172A").opacity(0.92))
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(HoloTheme.Palette.crystalSpecularGradient, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 24, y: 12)
            .padding(32)
        }
    }

    @ViewBuilder
    private var headerBarView: some View {
        HStack(spacing: 16) {
            // Title
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(HoloTheme.Palette.holoBlueTextGradient)
                Text("Tab Overview")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                TextField("Search title, URL, domain...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    })
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: 260)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))

            // Filter Chips
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TabOverviewFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)

            // Close Button
            Button(action: { isPresented = false }, label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            })
            .buttonStyle(.plain)
            .accessibilityLabel("Close Tab Overview")
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}
