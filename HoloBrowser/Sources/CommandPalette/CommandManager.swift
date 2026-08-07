import Foundation
import Combine

/// Manager handling command registry, open tab indexing, keyboard navigation, and execution for the Cmd+K Command Palette.
@MainActor
public final class CommandManager: ObservableObject {
    @Published public var searchQuery: String = ""
    @Published public private(set) var filteredCommands: [Command] = []
    @Published public var selectedIndex: Int = 0
    @Published public var isPaletteVisible: Bool = false
    @Published public private(set) var recentCommandTitles: [String] = []
    
    private var allCommands: [Command] = []
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        $searchQuery
            .receive(on: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterCommands(query: query)
            }
            .store(in: &cancellables)
    }
    
    /// Populates commands bound to BrowserViewModel, AIManager, and ExtensionManager actions.
    public func registerDefaultCommands(
        viewModel: BrowserViewModel,
        aiManager: AIManager,
        extensionManager: ExtensionManager,
        onToggleMode: @escaping () -> Void,
        onOpenSettings: (() -> Void)? = nil
    ) {
        var baseCommands: [Command] = [
            // HoloMind Instant AI Context Actions
            Command(title: "Summarize Active Page", subtitle: "Ask HoloMind to produce a clean executive summary", icon: "doc.text.fill", category: .system) {
                LocalUsageMetrics.shared.recordFeatureUsage(name: "CmdK_SummarizePage")
                HoloEventBus.shared.post(.smartSearchAI(query: "Summarize current webpage"))
            },
            Command(title: "Extract Action Items", subtitle: "Extract tasks, deadlines, and key bullet points", icon: "list.bullet.rectangle.fill", category: .system) {
                LocalUsageMetrics.shared.recordFeatureUsage(name: "CmdK_ExtractActions")
                HoloEventBus.shared.post(.smartSearchAI(query: "Extract key action items and tasks from page"))
            },
            Command(title: "Explain Selected Text", subtitle: "Provide instant AI clarification for highlighted concepts", icon: "text.magnifyingglass", category: .system) {
                LocalUsageMetrics.shared.recordFeatureUsage(name: "CmdK_ExplainSelection")
                HoloEventBus.shared.post(.smartSearchAI(query: "Explain selected text in context"))
            },
            Command(title: "Save Memory to Vault", subtitle: "Store current page context into local Personal Memory", icon: "brain.head.profile", category: .system) {
                LocalUsageMetrics.shared.recordFeatureUsage(name: "CmdK_SaveMemory")
                aiManager.isSidebarVisible = true
            },
            
            // Profile & Workspace Switching
            Command(title: "Switch to Personal Space", subtitle: "Isolated cookies & history for personal browsing", icon: "person.fill", category: .preferences) {
                viewModel.profileManager.selectProfile(byPurpose: .personal)
            },
            Command(title: "Switch to Work Space", subtitle: "Isolated credentials for work productivity", icon: "briefcase.fill", category: .preferences) {
                viewModel.profileManager.selectProfile(byPurpose: .work)
            },
            Command(title: "Switch to Private Space", subtitle: "Zero disk history incognito browsing", icon: "shield.slash.fill", category: .preferences) {
                viewModel.profileManager.selectProfile(byPurpose: .privateBrowsing)
            },
            
            // RC4 Intelligent Commands
            Command(title: "Organize Tabs", subtitle: "Categorize open tabs and remove duplicates", icon: "square.3.layers.3d.down.right", category: .tabs) {
                LocalUsageMetrics.shared.recordFeatureUsage(name: "CmdK_OrganizeTabs")
                aiManager.isSidebarVisible = true
            },
            Command(title: "Open Settings", subtitle: "Configure profiles, privacy, AI, and system health (⌘,)", icon: "gearshape.fill", category: .preferences) {
                LocalUsageMetrics.shared.recordFeatureUsage(name: "CmdK_OpenSettings")
                onOpenSettings?()
            },
            Command(title: "Create Research Project", subtitle: "Launch multi-tab AI research assistant workflow", icon: "doc.text.magnifyingglass", category: .system) {
                LocalUsageMetrics.shared.recordFeatureUsage(name: "CmdK_CreateResearchProject")
                aiManager.isSidebarVisible = true
            },
            Command(title: "Show Privacy Status", subtitle: "Inspect privacy shield & HoloDoctor health dashboard", icon: "shield.checkmark.fill", category: .preferences) {
                LocalUsageMetrics.shared.recordFeatureUsage(name: "CmdK_ShowPrivacyStatus")
                onOpenSettings?()
            },
            
            // Tab & Navigation Commands
            Command(title: "Restore Closed Tab", subtitle: "Reopen most recently closed tab (⌘ShiftT)", icon: "arrow.uturn.backward.square", category: .tabs) {
                viewModel.tabManager.restoreRecentlyClosedTab()
            },
            Command(title: "New Tab", subtitle: "Open a fresh browsing tab (⌘T)", icon: "plus.square", category: .tabs) {
                viewModel.createNewTab()
            },
            Command(title: "Close Tab", subtitle: "Close active tab (⌘W)", icon: "xmark.square", category: .tabs) {
                viewModel.closeActiveTab()
            },
            Command(title: "Reload Page", subtitle: "Re-fetch current webpage payload (⌘R)", icon: "arrow.clockwise", category: .navigation) {
                viewModel.reloadOrStop()
            },
            Command(title: "Go Back", subtitle: "Navigate backward in history (⌘[)", icon: "chevron.left", category: .navigation) {
                viewModel.goBack()
            },
            Command(title: "Go Forward", subtitle: "Navigate forward in history (⌘])", icon: "chevron.right", category: .navigation) {
                viewModel.goForward()
            },
            
            // Library & History
            Command(title: "Open History", subtitle: "View and search browsing history", icon: "clock", category: .navigation) {
                viewModel.inputURLString = "holo://history"
            },
            Command(title: "Open Bookmarks", subtitle: "View and manage saved favorites", icon: "star", category: .navigation) {
                viewModel.inputURLString = "holo://bookmarks"
            },
            Command(title: "Open Downloads", subtitle: "View active and completed file downloads", icon: "arrow.down.circle", category: .navigation) {
                viewModel.inputURLString = "holo://downloads"
            },
            
            // System Features
            Command(title: "Toggle Focus Mode", subtitle: "Hide UI chrome for distraction-free reading", icon: "eye.slash", category: .system) {
                onToggleMode()
            }
        ]
        
        // Dynamically Index Open Tabs
        for (idx, tab) in viewModel.tabManager.tabs.enumerated() {
            let tabTitle = tab.title.isEmpty ? (tab.url?.absoluteString ?? "Tab \(idx + 1)") : tab.title
            let openTabCmd = Command(
                title: "Jump to Tab: \(tabTitle)",
                subtitle: tab.url?.host ?? "Open Tab",
                icon: "globe",
                category: .tabs
            ) {
                viewModel.tabManager.selectTab(id: tab.id)
            }
            baseCommands.append(openTabCmd)
        }
        
        // Dynamically add Command Extensions
        for ext in extensionManager.extensions where ext.enabled && ext.type == .command {
            let extCmd = Command(
                title: ext.name,
                subtitle: "Extension by \(ext.author)",
                icon: ext.iconName,
                category: .system
            ) {
                aiManager.isSidebarVisible = true
            }
            baseCommands.append(extCmd)
        }
        
        allCommands = baseCommands
        filterCommands(query: searchQuery)
    }
    
    private func filterCommands(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            filteredCommands = allCommands
        } else {
            filteredCommands = allCommands.filter {
                $0.title.lowercased().contains(trimmed) || ($0.subtitle?.lowercased().contains(trimmed) ?? false)
            }
        }
        selectedIndex = 0
    }
    
    public func moveSelectionUp() {
        guard !filteredCommands.isEmpty else { return }
        if selectedIndex > 0 {
            selectedIndex -= 1
        } else {
            selectedIndex = filteredCommands.count - 1
        }
    }
    
    public func moveSelectionDown() {
        guard !filteredCommands.isEmpty else { return }
        if selectedIndex < filteredCommands.count - 1 {
            selectedIndex += 1
        } else {
            selectedIndex = 0
        }
    }
    
    public func executeSelected() {
        guard selectedIndex >= 0 && selectedIndex < filteredCommands.count else { return }
        execute(command: filteredCommands[selectedIndex])
    }
    
    public func execute(command: Command) {
        if !recentCommandTitles.contains(command.title) {
            recentCommandTitles.insert(command.title, at: 0)
            if recentCommandTitles.count > 5 {
                recentCommandTitles.removeLast()
            }
        }
        isPaletteVisible = false
        searchQuery = ""
        command.action()
    }
    
    public func togglePalette() {
        isPaletteVisible.toggle()
        if !isPaletteVisible {
            searchQuery = ""
        } else {
            selectedIndex = 0
        }
    }
}
