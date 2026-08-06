import Foundation
import Combine

/// Manager handling command registry and search queries for the Cmd+K Command Palette.
@MainActor
public final class CommandManager: ObservableObject {
    @Published public var searchQuery: String = ""
    @Published public private(set) var filteredCommands: [Command] = []
    @Published public var isPaletteVisible: Bool = false
    
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
        onToggleMode: @escaping () -> Void
    ) {
        var baseCommands: [Command] = [
            // Phase 9 Daily Driver Commands
            Command(title: "Restore Closed Tab", subtitle: "Reopen most recently closed tab (⌘ShiftT)", icon: "arrow.uturn.backward.square", category: .tabs) {
                viewModel.tabManager.restoreRecentlyClosedTab()
            },
            Command(title: "Search Open Tabs", subtitle: "Filter and jump to open tab (⌘ShiftF)", icon: "sparkle.magnifyingglass", category: .tabs) {
                viewModel.inputURLString = ""
            },
            Command(title: "Export Holo Backup", subtitle: "Export bookmarks, history, and workspaces archive", icon: "square.and.arrow.up", category: .system) {
                viewModel.inputURLString = "holo://settings"
            },
            
            // Phase 6F AI Personalization Commands
            Command(title: "Search My Knowledge & History", subtitle: "Cross-system natural language search over notes, history, and memory", icon: "magnifyingglass.circle", category: .system) {
                aiManager.isSidebarVisible = true
            },
            Command(title: "Open Workspaces", subtitle: "Open project workspace dashboard", icon: "folder", category: .system) {
                aiManager.isSidebarVisible = true
            },
            Command(title: "Generate Daily Briefing", subtitle: "Opt-in AI morning research and article summary", icon: "sun.max", category: .system) {
                aiManager.isSidebarVisible = true
            },
            Command(title: "Group Smart Tabs", subtitle: "Categorize open tabs and detect duplicates", icon: "square.3.layers.3d.down.right", category: .tabs) {
                aiManager.isSidebarVisible = true
            },
            
            // Phase 6E AI Workflow Commands
            Command(title: "Start AI Workflow", subtitle: "Launch multi-step AI task planner", icon: "cpu", category: .system) {
                aiManager.isSidebarVisible = true
            },
            Command(title: "Research This Topic", subtitle: "Synthesize research topic across web sources", icon: "doc.text.magnifyingglass", category: .system) {
                aiManager.isSidebarVisible = true
            },
            
            // Library Commands
            Command(title: "Open History", subtitle: "View and search browsing history", icon: "clock", category: .navigation) {
                viewModel.inputURLString = "holo://history"
            },
            Command(title: "Open Bookmarks", subtitle: "View and manage saved favorites", icon: "star", category: .navigation) {
                viewModel.inputURLString = "holo://bookmarks"
            },
            Command(title: "Open Reading List", subtitle: "View saved reading list articles", icon: "eyeglasses", category: .navigation) {
                viewModel.inputURLString = "holo://reading-list"
            },
            Command(title: "Open Downloads", subtitle: "View active and completed file downloads", icon: "arrow.down.circle", category: .navigation) {
                viewModel.inputURLString = "holo://downloads"
            },
            
            // Navigation & Tabs
            Command(title: "New Tab", subtitle: "Open a fresh browsing tab", icon: "plus.square", category: .tabs) {
                viewModel.createNewTab()
            },
            Command(title: "Close Tab", subtitle: "Close active tab", icon: "xmark.square", category: .tabs) {
                viewModel.closeActiveTab()
            },
            Command(title: "Reload Page", subtitle: "Re-fetch current webpage payload", icon: "arrow.clockwise", category: .navigation) {
                viewModel.reloadOrStop()
            },
            Command(title: "Go Back", subtitle: "Navigate backward in history", icon: "chevron.left", category: .navigation) {
                viewModel.goBack()
            },
            Command(title: "Go Forward", subtitle: "Navigate forward in history", icon: "chevron.right", category: .navigation) {
                viewModel.goForward()
            },
            
            // System & Preferences
            Command(title: "Toggle Focus Mode", subtitle: "Hide UI chrome for distraction-free reading", icon: "eye.slash", category: .system) {
                onToggleMode()
            },
            Command(title: "Open Preferences", subtitle: "Configure homepage, search engine, and downloads", icon: "gearshape", category: .preferences) {
                viewModel.submitAddressInput()
            }
        ]
        
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
    }
    
    public func execute(command: Command) {
        isPaletteVisible = false
        searchQuery = ""
        command.action()
    }
    
    public func togglePalette() {
        isPaletteVisible.toggle()
        if !isPaletteVisible {
            searchQuery = ""
        }
    }
}
