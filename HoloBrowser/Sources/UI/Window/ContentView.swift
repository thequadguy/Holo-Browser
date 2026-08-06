import SwiftUI

/// Main window content layout synthesizing Liquid Glass UI, AI Sidebar, Command Palette, Session Recovery, Library Views, and WebKit canvas.
public struct ContentView: View {
    @StateObject private var viewModel = BrowserViewModel()
    @StateObject private var commandManager = CommandManager()
    @StateObject private var modeManager = ModeManager()
    @StateObject private var aiManager = AIManager()
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var privacyManager = AIPrivacyManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var extensionManager = ExtensionManager()
    @StateObject private var reliabilityManager = ReliabilityManager()
    @StateObject private var mindEngine = HoloMindEngine()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showWelcomeSheet: Bool = false
    @State private var showFeedbackSheet: Bool = false
    @State private var showImportWizardSheet: Bool = false
    @State private var showAboutSheet: Bool = false
    @State private var showDogfoodSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Main Content & Sidebar Layout
            HStack(spacing: 0) {
                // Primary Browser Canvas
                VStack(spacing: 0) {
                    // Tab Bar (hidden in Focus mode)
                    if modeManager.currentMode != .focus {
                        TabBarView(tabManager: viewModel.tabManager, activeProfileID: viewModel.profileManager.activeProfile.id, onNewTab: { viewModel.createNewTab() })
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Holo Navigation Toolbar (hidden in Focus mode)
                    if modeManager.currentMode != .focus {
                        NavigationToolbarView(
                            viewModel: viewModel,
                            commandManager: commandManager,
                            modeManager: modeManager,
                            aiManager: aiManager,
                            onOpenSettings: { SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: privacyManager) },
                            onOpenImportWizard: { showImportWizardSheet = true },
                            onOpenHoloMind: { mindEngine.togglePanel() },
                            onExecuteQuickAction: { action in
                                mindEngine.executeQuickAction(action, context: "Current tab context", profile: viewModel.profileManager.activeProfile)
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Web Content Area
                    // P0-B: Guard against .closed tabs — WKWebViewWrapper must never be rendered
                    // for a closed tab or it will hit the assertionFailure fallback.
                    ZStack(alignment: .topTrailing) {
                        if let activeTab = viewModel.tabManager.activeTab, activeTab.state != .closed {
                            if activeTab.url?.scheme == "holo" && activeTab.url?.host == "start" {
                                HoloStartPageView(
                                    mindEngine: mindEngine,
                                    tabManager: viewModel.tabManager,
                                    currentProfileID: viewModel.profileManager.activeProfile.id,
                                    isPrivateMode: viewModel.profileManager.activeProfile.isPrivate
                                )
                                .id(activeTab.id)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                WKWebViewWrapper(tab: activeTab)
                                    .id(activeTab.id)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        // Session Crash Recovery Overlay Banner (Top Trailing floating below chrome)
                        if viewModel.sessionManager.hasRecoverableSession && viewModel.sessionManager.showRecoveryPrompt {
                            HoloSessionRecoveryCard(viewModel: viewModel)
                                .padding(.top, 16)
                                .padding(.trailing, 16)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                
                // Native AI Sidebar Drawer
                if aiManager.isSidebarVisible {
                    AISidebarView(aiManager: aiManager, activeTab: viewModel.tabManager.activeTab)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            

            
            // Password Save Permission Overlay Banner
            if let prompt = viewModel.passwordManager.promptSaveCredential {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save Password for \(prompt.domain)?")
                                .font(.system(size: 12, weight: .bold))
                            Text("Username: \(prompt.username.isEmpty ? "Unknown User" : prompt.username)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Never") {
                            viewModel.passwordManager.promptSaveCredential = nil
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        
                        Button("Save Password") {
                            // P1-5: consumePasswordData() is mutating — work on a var copy.
                            var mutablePrompt = prompt
                            
                            // Extract data and immediately zero it from the prompt structure.
                            let pwData = mutablePrompt.consumePasswordData()
                            
                            Task {
                                await viewModel.passwordManager.saveCredential(
                                    domain: prompt.domain,
                                    username: prompt.username,
                                    passwordData: pwData,
                                    profileID: viewModel.profileManager.activeProfile.id
                                )
                            }
                            viewModel.passwordManager.promptSaveCredential = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.system(size: 11, weight: .semibold))

                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        VisualEffectViewWrapper(material: .hudWindow, blendingMode: .withinWindow)
                            .cornerRadius(12)
                    )
                    .padding(.top, 40)
                    .frame(maxWidth: 520)
                    .shadow(radius: 8)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Focus Mode Exit Overlay
            if modeManager.currentMode == .focus {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(HoloDesign.Animations.springNormal) {
                                modeManager.toggleFocusMode()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "eye")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Exit Focus Mode")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                VisualEffectViewWrapper(material: .hudWindow, blendingMode: .withinWindow)
                                    .cornerRadius(16)
                            )
                            .foregroundColor(.primary)
                            .shadow(radius: 6)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }
            
            // Cmd+K Command Palette Modal Overlay
            if commandManager.isPaletteVisible {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        commandManager.isPaletteVisible = false
                    }
                
                CommandPaletteView(commandManager: commandManager)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
            
            // Media Permission Request Prompt (P0-Fix-5)
            // Surfaces camera/microphone access requests for user approval instead of auto-granting.
            if let req = permissionManager.pendingRequest {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: req.captureType == .camera ? "camera.fill" : req.captureType == .microphone ? "mic.fill" : "camera.and.ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(req.captureType == .camera ? "Camera Access Requested" : req.captureType == .microphone ? "Microphone Access Requested" : "Camera & Microphone Requested")
                                .font(.system(size: 13, weight: .semibold))
                            Text(req.domain)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Allow") {
                            permissionManager.approve(id: req.id, rememberDecision: false)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        Button("Deny") {
                            permissionManager.deny(id: req.id, rememberDecision: false)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(
                        VisualEffectViewWrapper(material: .hudWindow, blendingMode: .withinWindow)
                            .cornerRadius(12)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(HoloDesign.Animations.springNormal, value: permissionManager.pendingRequest?.id)
            }

            // Web Error Overlay
            if let errorMessage = viewModel.errorMessage {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                WebErrorOverlayView(
                    errorMessage: errorMessage,
                    onRetry: {
                        viewModel.reloadOrStop()
                    },
                    onDismiss: {
                        viewModel.dismissError()
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(
            KeyboardShortcutHandlerView(
                viewModel: viewModel,
                commandManager: commandManager,
                modeManager: modeManager,
                aiManager: aiManager,
                onOpenSettings: { SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: privacyManager) }
            )
        )
        .onAppear {
            // P1-2: Inject managers FIRST, then call setup() to create the initial tab.
            // This ensures the first tab's webview gets permissionManager and reliabilityManager
            // wired at creation time, eliminating the startup delegate race.
            viewModel.tabManager.permissionManager = permissionManager
            viewModel.tabManager.reliabilityManager = reliabilityManager

            // Create the initial tab now that delegates are ready.
            let startupBehavior = HoloCommandCenterSettings.shared.startupBehavior
            if startupBehavior == .previousSession && viewModel.sessionManager.loadPreviousSession() != nil {
                viewModel.restorePreviousSession()
                if viewModel.tabManager.tabs.isEmpty {
                    viewModel.tabManager.setup(dataStore: viewModel.profileManager.activeWebsiteDataStore)
                }
            } else if startupBehavior == .custom, let url = URL(string: HoloCommandCenterSettings.shared.customHomepageURL) {
                viewModel.tabManager.setup(dataStore: viewModel.profileManager.activeWebsiteDataStore, startupURL: url)
            } else {
                viewModel.tabManager.setup(dataStore: viewModel.profileManager.activeWebsiteDataStore)
            }

            commandManager.registerDefaultCommands(
                viewModel: viewModel,
                aiManager: aiManager,
                extensionManager: extensionManager,
                onToggleMode: {
                    withAnimation(HoloDesign.Animations.springNormal) {
                        modeManager.toggleFocusMode()
                    }
                },
                onOpenSettings: {
                    SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: privacyManager)
                }
            )
            if viewModel.sessionManager.hasRecoverableSession {
                viewModel.sessionManager.showRecoveryPrompt = true
            }
            // Phase 1: Show welcome sheet on first launch
            if !hasCompletedOnboarding {
                showWelcomeSheet = true
            }
        }
        // P1-7: When the active profile changes AFTER initial setup, migrate open tabs.
        // onReceive fires immediately on subscription with the current value — we skip that
        // first emission to avoid closing the initial tab created by setup(dataStore:).
        // Migration only runs when the profile ID genuinely changes.
        .onReceive(viewModel.profileManager.$activeProfile
            .dropFirst()  // Skip initial emission — not a real profile switch
        ) { newProfile in
            let newStore = viewModel.profileManager.websiteDataStore(for: newProfile)
            viewModel.tabManager.migrateToNewProfile(
                dataStore: newStore,
                newProfileID: newProfile.id
            )
        }
        .onReceive(viewModel.tabManager.$tabs) { tabs in
            mindEngine.analyzeBrowserState(tabs: tabs)
        }

        .sheet(isPresented: $showWelcomeSheet) {
            HoloWelcomeView {
                hasCompletedOnboarding = true
                showWelcomeSheet = false
            }
        }
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackSheetView()
        }
        .sheet(isPresented: $showImportWizardSheet) {
            BrowserImportWizardView(
                bookmarkManager: viewModel.bookmarkManager,
                historyStore: historyStore,
                onDismiss: { showImportWizardSheet = false }
            )
        }
        .sheet(isPresented: $mindEngine.isPanelVisible) {
            HoloMindDashboardView(
                mindEngine: mindEngine,
                currentProfileID: viewModel.profileManager.activeProfile.id,
                isPrivateMode: viewModel.profileManager.activeProfile.isPrivate,
                onDismiss: { mindEngine.isPanelVisible = false }
            )
        }
        .onReceive(viewModel.$currentURL) { url in
            if let url = url, let title = viewModel.tabManager.activeTab?.title {
                let isPrivate = viewModel.profileManager.activeProfile.isPrivate
                historyStore.addEntry(url: url, title: title, isPrivate: isPrivate)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloQuickActionSummarize"))) { _ in
            mindEngine.executeQuickAction(.summarizePage, context: "Triggered from Context Menu", profile: viewModel.profileManager.activeProfile)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloQuickActionSaveMemory"))) { _ in
            mindEngine.executeQuickAction(.saveToMemory, context: "Selected text from Context Menu", profile: viewModel.profileManager.activeProfile)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloSmartSearchAI"))) { notification in
            if let _ = notification.object as? String {
                mindEngine.isPanelVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloSmartSearchMission"))) { notification in
            if let query = notification.object as? String {
                mindEngine.assignGoal(title: query, category: .research)
                mindEngine.isPanelVisible = true
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutHoloBrowserView()
        }
        .sheet(isPresented: $showDogfoodSheet) {
            DogfoodSheetView(viewModel: viewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloOpenAbout"))) { _ in
            showAboutSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloOpenFeedback"))) { _ in
            showFeedbackSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloOpenDogfood"))) { _ in
            showDogfoodSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloOpenSettings"))) { _ in
            SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: privacyManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HoloNewTabShortcut"))) { _ in
            viewModel.createNewTab()
        }
    }
}

/// Keyboard shortcut delegate capturing Cmd+K, Cmd+Shift+A, Cmd+L, Cmd+T, Cmd+Shift+T, Cmd+W, Cmd+Option+I, and Cmd+1..9.
private struct KeyboardShortcutHandlerView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var commandManager: CommandManager
    @ObservedObject var modeManager: ModeManager
    @ObservedObject var aiManager: AIManager
    var onOpenSettings: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Cmd + ,: Open Preferences / Settings
            Button("") {
                onOpenSettings?()
            }
            .keyboardShortcut(",", modifiers: [.command])
            .opacity(0)
            
            // Cmd + K: Command Palette
            Button("") {
                commandManager.togglePalette()
            }
            .keyboardShortcut("k", modifiers: [.command])
            .opacity(0)
            
            // Cmd + L: Focus Address Bar
            Button("") {
                NotificationCenter.default.post(name: .focusAddressBar, object: nil)
            }
            .keyboardShortcut("l", modifiers: [.command])
            .opacity(0)
            
            // Cmd + Shift + A: Toggle AI Sidebar
            Button("") {
                withAnimation(HoloDesign.Animations.springNormal) {
                    aiManager.toggleSidebar()
                }
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
            .opacity(0)
            
            // Cmd + Shift + T: Restore Closed Tab
            // P1-1: Pass the active profile's data store so the restored tab uses the correct
            // profile isolation — recentlyClosedTabs now tracks profileID per entry.
            Button("") {
                viewModel.tabManager.restoreRecentlyClosedTab(
                    dataStore: viewModel.profileManager.activeWebsiteDataStore
                )
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .opacity(0)
            
            // Cmd + T: New Tab
            Button("") {
                viewModel.createNewTab()
            }
            .keyboardShortcut("t", modifiers: [.command])
            .opacity(0)
            
            // Cmd + W: Close Tab
            Button("") {
                viewModel.closeActiveTab()
            }
            .keyboardShortcut("w", modifiers: [.command])
            .opacity(0)
            
            // Cmd + Option + I: Web Inspector
            Button("") {
                viewModel.toggleWebInspector()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
            .opacity(0)
            
            // Cmd + 1..9: Switch Tabs
            ForEach(1...9, id: \.self) { index in
                Button("") {
                    viewModel.selectTab(at: index - 1)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: [.command])
                .opacity(0)
            }
        }
    }
}
