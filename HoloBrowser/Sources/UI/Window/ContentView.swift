import SwiftUI

/// Main window content layout synthesizing Liquid Glass UI, AI Sidebar, Command Palette, Session Recovery, Library Views, and WebKit canvas.
/// Environment-injected composition view receiving dependencies from BrowserEnvironment and OverlayCoordinator.
public struct ContentView: View {
    @ObservedObject var environment: BrowserEnvironment
    @ObservedObject var overlayCoordinator: OverlayCoordinator
    
    @StateObject private var viewModel: BrowserViewModel
    @StateObject private var commandManager = CommandManager()
    @StateObject private var modeManager = ModeManager()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    public init(environment: BrowserEnvironment) {
        self.environment = environment
        self.overlayCoordinator = environment.overlayCoordinator
        self._viewModel = StateObject(wrappedValue: environment.makeBrowserViewModel())
    }
    
    public var body: some View {
        ZStack {
            // Shared Root Optical Environment (behind chrome, canvas, popovers, and overlays)
            HoloBackgroundView()
            
            // Primary Browser Canvas (No Sidebar)
            VStack(spacing: 0) {

                // Unified Chrome Shell: Tab Bar + Navigation Toolbar fused into a single glass surface (hidden in Focus mode)
                if modeManager.currentMode != .focus {
                    VStack(spacing: 0) {
                        TabBarView(tabManager: viewModel.tabManager, activeProfileID: viewModel.profileManager.activeProfile.id, onNewTab: { viewModel.createNewTab() })

                        NavigationToolbarView(
                            viewModel: viewModel,
                            commandManager: commandManager,
                            modeManager: modeManager,
                            aiManager: environment.aiManager,
                            onOpenSettings: { SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: environment.privacyManager) },
                            onOpenImportWizard: { overlayCoordinator.showImportWizardSheet = true },
                            onOpenHoloMind: { environment.mindEngine.togglePanel() },
                            onExecuteQuickAction: { action in
                                if action == .summarizePage,
                                   let webView = viewModel.tabManager.activeTab?.webView {
                                    environment.mindEngine.summarizePage(
                                        webView: webView,
                                        aiManager: environment.aiManager,
                                        profile: viewModel.profileManager.activeProfile
                                    )
                                } else {
                                    environment.mindEngine.executeQuickAction(action, context: nil, profile: viewModel.profileManager.activeProfile)
                                }
                            }
                        )
                    }
                    .background(
                        ZStack {
                            VisualEffectViewWrapper(material: .headerView, blendingMode: .behindWindow)
                            HoloTheme.Palette.chromeFill
                        }
                    )
                    .overlay(
                        Rectangle()
                            .fill(HoloTheme.Palette.glassBorderGradient)
                            .opacity(0.5)
                            .frame(height: 1),
                        alignment: .bottom
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Web Content Area
                ZStack(alignment: .topTrailing) {
                    if !hasCompletedOnboarding {
                        // Bright Liquid Glass background card while onboarding is presented
                        VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let activeTab = viewModel.tabManager.activeTab, activeTab.state != .closed {
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
                            var mutablePrompt = prompt
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
                        VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
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
                                VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
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
            
            // Media Permission Request Prompt
            if let req = environment.permissionManager.pendingRequest {
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
                            environment.permissionManager.approve(id: req.id, rememberDecision: false)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        Button("Deny") {
                            environment.permissionManager.deny(id: req.id, rememberDecision: false)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(
                        VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
                            .cornerRadius(12)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(HoloDesign.Animations.springNormal, value: environment.permissionManager.pendingRequest?.id)
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
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HoloTheme.Palette.crystalSpecularGradient, lineWidth: 1.25)
        )
        .background(
            KeyboardShortcutHandlerView(
                viewModel: viewModel,
                commandManager: commandManager,
                modeManager: modeManager,
                aiManager: environment.aiManager,
                onOpenSettings: { SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: environment.privacyManager) }
            )
        )
        .onAppear {
            viewModel.tabManager.permissionManager = environment.permissionManager
            viewModel.tabManager.reliabilityManager = environment.reliabilityManager

            let startupBehavior = HoloStartupSettings.shared.startupBehavior
            if startupBehavior == .previousSession && viewModel.sessionManager.loadPreviousSession() != nil {
                viewModel.restorePreviousSession()
                if viewModel.tabManager.tabs.isEmpty {
                    viewModel.tabManager.setup(dataStore: viewModel.profileManager.activeWebsiteDataStore)
                }
            } else if startupBehavior == .custom, let url = URL(string: HoloStartupSettings.shared.customHomepageURL) {
                viewModel.tabManager.setup(dataStore: viewModel.profileManager.activeWebsiteDataStore, startupURL: url)
            } else {
                viewModel.tabManager.setup(dataStore: viewModel.profileManager.activeWebsiteDataStore)
            }

            commandManager.registerDefaultCommands(
                viewModel: viewModel,
                aiManager: environment.aiManager,
                extensionManager: environment.extensionManager,
                onToggleMode: {
                    withAnimation(HoloDesign.Animations.springNormal) {
                        modeManager.toggleFocusMode()
                    }
                },
                onOpenSettings: {
                    SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: environment.privacyManager)
                }
            )
            if viewModel.sessionManager.hasRecoverableSession {
                viewModel.sessionManager.showRecoveryPrompt = true
            }
            if !hasCompletedOnboarding {
                overlayCoordinator.showWelcomeSheet = true
            }
        }
        .onReceive(viewModel.profileManager.$activeProfile.dropFirst()) { newProfile in
            let newStore = viewModel.profileManager.websiteDataStore(for: newProfile)
            viewModel.tabManager.migrateToNewProfile(
                dataStore: newStore,
                newProfileID: newProfile.id
            )
        }
        .onReceive(viewModel.tabManager.$tabs) { tabs in
            environment.mindEngine.analyzeBrowserState(tabs: tabs)
        }
        .sheet(isPresented: $overlayCoordinator.showWelcomeSheet) {
            HoloWelcomeView {
                hasCompletedOnboarding = true
                overlayCoordinator.showWelcomeSheet = false
            }
        }
        .sheet(isPresented: $overlayCoordinator.showFeedbackSheet) {
            FeedbackSheetView()
        }
        .sheet(isPresented: $overlayCoordinator.showImportWizardSheet) {
            BrowserImportWizardView(
                bookmarkManager: viewModel.bookmarkManager,
                historyStore: environment.historyStore,
                onDismiss: { overlayCoordinator.showImportWizardSheet = false }
            )
        }

        .sheet(isPresented: $overlayCoordinator.showAboutSheet) {
            AboutHoloBrowserView()
        }
        .sheet(isPresented: $overlayCoordinator.showDogfoodSheet) {
            DogfoodSheetView(viewModel: viewModel)
        }
        .onReceive(viewModel.$currentURL) { url in
            if let url = url, let title = viewModel.tabManager.activeTab?.title {
                let isPrivate = viewModel.profileManager.activeProfile.isPrivate
                environment.historyStore.addEntry(url: url, title: title, isPrivate: isPrivate)
            }
        }
        .onReceive(environment.eventBus.publisher) { event in
            switch event {
            case .openSettings:
                SettingsWindowController.shared.open(viewModel: viewModel, privacyManager: environment.privacyManager)
            case .openAbout:
                overlayCoordinator.showAboutSheet = true
            case .openFeedback:
                overlayCoordinator.showFeedbackSheet = true
            case .openDogfood:
                overlayCoordinator.showDogfoodSheet = true
            case .openImportWizard:
                overlayCoordinator.showImportWizardSheet = true
            case .newTabShortcut:
                viewModel.createNewTab()
            case .quickActionSummarize:
                if let webView = viewModel.tabManager.activeTab?.webView {
                    environment.mindEngine.summarizePage(
                        webView: webView,
                        aiManager: environment.aiManager,
                        profile: viewModel.profileManager.activeProfile
                    )
                } else {
                    environment.aiManager.isSidebarVisible = true
                }
            case .quickActionSaveMemory:
                environment.mindEngine.executeQuickAction(.saveToMemory, context: "Selected text from Context Menu", profile: viewModel.profileManager.activeProfile)
            case .smartSearchAI(let query):
                environment.aiManager.isSidebarVisible = true
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
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
            case .smartSearchMission(let query):
                environment.mindEngine.assignGoal(title: query, category: .research)
                environment.aiManager.isSidebarVisible = true
            default:
                break
            }
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
                HoloEventBus.shared.post(.focusAddressBar)
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
