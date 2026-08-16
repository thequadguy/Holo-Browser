import SwiftUI

/// Main window content layout synthesizing Liquid Glass UI, AI Sidebar, Command Palette,
/// Session Recovery, Library Views, and WebKit canvas.
/// Environment-injected composition view receiving dependencies from BrowserEnvironment
/// and OverlayCoordinator.
public struct ContentView: View {
    @ObservedObject var environment: BrowserEnvironment
    @ObservedObject var overlayCoordinator: OverlayCoordinator

    @StateObject var viewModel: BrowserViewModel
    @StateObject private var commandManager = CommandManager()
    @StateObject var modeManager = ModeManager()

    @State private var showTabOverview: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    public init(environment: BrowserEnvironment) {
        self.environment = environment
        self.overlayCoordinator = environment.overlayCoordinator
        self._viewModel = StateObject(wrappedValue: environment.makeBrowserViewModel())
    }

    public var body: some View {
        ZStack {
            HoloBackgroundView()

            VStack(spacing: 0) {
                if modeManager.currentMode != .focus { chromeView }

                ZStack(alignment: .topTrailing) {
                    webContentView
                    if viewModel.sessionManager.hasRecoverableSession
                        && viewModel.sessionManager.showRecoveryPrompt {
                        HoloSessionRecoveryCard(viewModel: viewModel)
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }

            contentOverlaysView
        }
        .frame(minWidth: 800, minHeight: 600)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HoloTheme.Palette.crystalSpecularGradient, lineWidth: 1.25)
        )
        .overlay(overlayPaletteView)
        .onReceive(HoloEventBus.shared.publisher) { event in
            if case .openTabOverview = event {
                withAnimation(HoloTheme.Animations.springSnappy) { showTabOverview.toggle() }
            }
        }
        .background(keyboardHandlerView)
        .onAppear(perform: onAppearSetup)
        .onReceive(viewModel.profileManager.$activeProfile.dropFirst(), perform: onProfileChange)
        .onReceive(viewModel.tabManager.$tabs) { environment.mindEngine.analyzeBrowserState(tabs: $0) }
        .sheet(isPresented: $overlayCoordinator.showWelcomeSheet) {
            HoloWelcomeView {
                hasCompletedOnboarding = true
                overlayCoordinator.showWelcomeSheet = false
            }
        }
        .sheet(isPresented: $overlayCoordinator.showFeedbackSheet) { FeedbackSheetView() }
        .sheet(isPresented: $overlayCoordinator.showImportWizardSheet) {
            BrowserImportWizardView(
                bookmarkManager: viewModel.bookmarkManager,
                historyStore: environment.historyStore,
                onDismiss: { overlayCoordinator.showImportWizardSheet = false }
            )
        }
        .sheet(isPresented: $overlayCoordinator.showAboutSheet) { AboutHoloBrowserView() }
        .sheet(isPresented: $overlayCoordinator.showDogfoodSheet) {
            DogfoodSheetView(viewModel: viewModel)
        }
        .onReceive(viewModel.$currentURL) { url in
            if let url = url, let title = viewModel.tabManager.activeTab?.title {
                let isPrivate = viewModel.profileManager.activeProfile.isPrivate
                environment.historyStore.addEntry(url: url, title: title, isPrivate: isPrivate)
            }
        }
        .onReceive(environment.eventBus.publisher, perform: handleBusEvent)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var chromeView: some View {
        VStack(spacing: 0) {
            TabBarView(
                tabManager: viewModel.tabManager,
                activeProfileID: viewModel.profileManager.activeProfile.id,
                onNewTab: { viewModel.createNewTab() }
            )
            NavigationToolbarView(
                viewModel: viewModel,
                commandManager: commandManager,
                modeManager: modeManager,
                aiManager: environment.aiManager,
                onOpenSettings: {
                    SettingsWindowController.shared.open(
                        viewModel: viewModel,
                        privacyManager: environment.privacyManager
                    )
                },
                onOpenImportWizard: { overlayCoordinator.showImportWizardSheet = true },
                onOpenHoloMind: { environment.mindEngine.togglePanel() },
                onExecuteQuickAction: handleQuickAction
            )
        }
        .background(
            ZStack {
                VisualEffectViewWrapper(material: .headerView, blendingMode: .behindWindow)
                HoloTheme.Palette.chromeFill
            }
        )
        .overlay(
            Rectangle().fill(HoloTheme.Palette.glassBorderGradient).opacity(0.5).frame(height: 1),
            alignment: .bottom
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private var webContentView: some View {
        if !hasCompletedOnboarding {
            VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.tabManager.splitState.isActive {
            HoloSplitView(
                tabManager: viewModel.tabManager,
                environment: environment,
                activeProfileID: viewModel.profileManager.activeProfile.id,
                isPrivateMode: viewModel.profileManager.activeProfile.isPrivate
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let activeTab = viewModel.tabManager.activeTab, activeTab.state != .closed {
            activeTabView(activeTab)
        } else {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func activeTabView(_ activeTab: Tab) -> some View {
        if activeTab.url?.scheme == "holo" && activeTab.url?.host == "start" {
            HoloStartPageView(
                mindEngine: environment.mindEngine,
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
    }

    @ViewBuilder
    private var overlayPaletteView: some View {
        ZStack {
            CommandPaletteView(commandManager: commandManager)
            if showTabOverview {
                HoloTabOverviewView(
                    tabManager: viewModel.tabManager,
                    activeProfileID: viewModel.profileManager.activeProfile.id,
                    isPresented: $showTabOverview
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    private var keyboardHandlerView: some View {
        KeyboardShortcutHandlerView(
            viewModel: viewModel,
            commandManager: commandManager,
            modeManager: modeManager,
            aiManager: environment.aiManager,
            onOpenSettings: {
                SettingsWindowController.shared.open(
                    viewModel: viewModel,
                    privacyManager: environment.privacyManager
                )
            }
        )
    }
}

// MARK: - Event & Action Handlers

extension ContentView {
    func handleQuickAction(_ action: HQuickAction) {
        if action == .summarizePage, let webView = viewModel.tabManager.activeTab?.webView {
            environment.mindEngine.summarizePage(
                webView: webView,
                aiManager: environment.aiManager,
                profile: viewModel.profileManager.activeProfile
            )
        } else {
            environment.mindEngine.executeQuickAction(
                action, context: nil, profile: viewModel.profileManager.activeProfile
            )
        }
    }

    func onAppearSetup() {
        viewModel.tabManager.permissionManager = environment.permissionManager
        viewModel.tabManager.reliabilityManager = environment.reliabilityManager
        setupTabManagerForStartup()
        commandManager.registerDefaultCommands(
            viewModel: viewModel,
            aiManager: environment.aiManager,
            extensionManager: environment.extensionManager,
            onToggleMode: {
                withAnimation(HoloDesign.Animations.springNormal) { modeManager.toggleFocusMode() }
            },
            onOpenSettings: {
                SettingsWindowController.shared.open(
                    viewModel: viewModel, privacyManager: environment.privacyManager
                )
            }
        )
        if viewModel.sessionManager.hasRecoverableSession {
            viewModel.sessionManager.showRecoveryPrompt = true
        }
        if !hasCompletedOnboarding { overlayCoordinator.showWelcomeSheet = true }
    }

    private func setupTabManagerForStartup() {
        let startupBehavior = HoloStartupSettings.shared.startupBehavior
        if startupBehavior == .previousSession && viewModel.sessionManager.loadPreviousSession() != nil {
            viewModel.restorePreviousSession()
            if viewModel.tabManager.tabs.isEmpty {
                viewModel.tabManager.setup(dataStore: viewModel.profileManager.activeWebsiteDataStore)
            }
        } else if startupBehavior == .custom,
                  let url = URL(string: HoloStartupSettings.shared.customHomepageURL) {
            viewModel.tabManager.setup(
                dataStore: viewModel.profileManager.activeWebsiteDataStore, startupURL: url
            )
        } else {
            viewModel.tabManager.setup(dataStore: viewModel.profileManager.activeWebsiteDataStore)
        }
    }

    func onProfileChange(_ newProfile: BrowserProfile) {
        let newStore = viewModel.profileManager.websiteDataStore(for: newProfile)
        viewModel.tabManager.migrateToNewProfile(dataStore: newStore, newProfileID: newProfile.id)
    }

    func handleBusEvent(_ event: HoloEvent) {
        if handleOverlayEvent(event) { return }
        handleActionEvent(event)
    }

    private func handleOverlayEvent(_ event: HoloEvent) -> Bool {
        switch event {
        case .openSettings:
            SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: environment.privacyManager)
            return true
        case .openAbout:
            overlayCoordinator.showAboutSheet = true
            return true
        case .openFeedback:
            overlayCoordinator.showFeedbackSheet = true
            return true
        case .openDogfood:
            overlayCoordinator.showDogfoodSheet = true
            return true
        case .openImportWizard:
            overlayCoordinator.showImportWizardSheet = true
            return true
        default:
            return false
        }
    }

    private func handleActionEvent(_ event: HoloEvent) {
        switch event {
        case .newTabShortcut:
            viewModel.createNewTab()
        case .quickActionSummarize:
            handleQuickActionSummarize()
        case .quickActionSaveMemory:
            handleSaveMemory()
        case .smartSearchAI(let query):
            handleSmartSearchAI(query: query)
        case .smartSearchMission(let query):
            handleSmartSearchMission(query: query)
        default:
            break
        }
    }

    private func handleQuickActionSummarize() {
        if let webView = viewModel.tabManager.activeTab?.webView {
            environment.mindEngine.summarizePage(
                webView: webView, aiManager: environment.aiManager,
                profile: viewModel.profileManager.activeProfile
            )
        } else {
            environment.aiManager.isSidebarVisible = true
        }
    }

    private func handleSaveMemory() {
        environment.mindEngine.executeQuickAction(
            .saveToMemory,
            context: "Selected text from Context Menu",
            profile: viewModel.profileManager.activeProfile
        )
    }

    private func handleSmartSearchAI(query: String) {
        environment.aiManager.isSidebarVisible = true
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let webView = viewModel.tabManager.activeTab?.webView {
            Task { @MainActor in
                if let context = try? await PageContextBuilder.buildContext(from: webView) {
                    environment.aiManager.askPage(question: trimmed, text: context.bodyText)
                } else {
                    environment.aiManager.chat(userText: trimmed)
                }
            }
        } else {
            environment.aiManager.chat(userText: trimmed)
        }
    }

    private func handleSmartSearchMission(query: String) {
        environment.mindEngine.assignGoal(title: query, category: .research)
        environment.aiManager.isSidebarVisible = true
    }
}
