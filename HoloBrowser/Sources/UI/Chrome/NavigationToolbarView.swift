import SwiftUI

/// Premium floating browser toolbar featuring frosted glass translucency, Profile Switcher, AI button, and Holo controls.
public struct NavigationToolbarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var commandManager: CommandManager
    @ObservedObject var modeManager: ModeManager
    @ObservedObject var aiManager: AIManager
    
    public var onOpenSettings: (() -> Void)?
    public var onOpenImportWizard: (() -> Void)?
    public var onOpenHoloMind: (() -> Void)?
    public var onExecuteQuickAction: ((HQuickAction) -> Void)?
    
    @State private var showProfilePopover: Bool = false
    
    public init(
        viewModel: BrowserViewModel,
        commandManager: CommandManager,
        modeManager: ModeManager,
        aiManager: AIManager,
        onOpenSettings: (() -> Void)? = nil,
        onOpenImportWizard: (() -> Void)? = nil,
        onOpenHoloMind: (() -> Void)? = nil,
        onExecuteQuickAction: ((HQuickAction) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.commandManager = commandManager
        self.modeManager = modeManager
        self.aiManager = aiManager
        self.onOpenSettings = onOpenSettings
        self.onOpenImportWizard = onOpenImportWizard
        self.onOpenHoloMind = onOpenHoloMind
        self.onExecuteQuickAction = onExecuteQuickAction
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Navigation Cluster (Back / Forward / Reload)
                HStack(spacing: 4) {
                    Button(action: { viewModel.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canGoBack)
                    .foregroundColor(viewModel.canGoBack ? .primary : .secondary.opacity(0.4))
                    .help("Back")
                    
                    Button(action: { viewModel.goForward() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canGoForward)
                    .foregroundColor(viewModel.canGoForward ? .primary : .secondary.opacity(0.4))
                    .help("Forward")
                    
                    Button(action: { viewModel.reloadOrStop() }) {
                        Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                    .help(viewModel.isLoading ? "Stop" : "Reload")
                }
                .padding(.horizontal, 4)
                .background(Capsule().fill(Color.gray.opacity(0.12)))
                
                // Profile Switcher Button
                Button(action: {
                    showProfilePopover.toggle()
                }) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: viewModel.profileManager.activeProfile.colorHex))
                            .frame(width: 14, height: 14)
                            .holoGlow(color: Color(hex: viewModel.profileManager.activeProfile.colorHex), radius: 4, isActive: HoloAppearanceSettings.shared.enableHolographicAccents)
                            .overlay(
                                Text(String(viewModel.profileManager.activeProfile.name.prefix(1)).uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text("Profile: \(viewModel.profileManager.activeProfile.name)")
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 26)
                    .background(Capsule().fill(Color.gray.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showProfilePopover, arrowEdge: .bottom) {
                    ProfileSwitcherView(profileManager: viewModel.profileManager)
                }
                .help("Switch Profile")
                
                // Address Bar
                AddressBarView(viewModel: viewModel)
                
                // Holo Action Controls (H Chief of Staff, AI, Cmd+K, Mode Toggle)
                HStack(spacing: 4) {
                    // HoloMind Chief of Staff Button
                    Button(action: {
                        onOpenHoloMind?()
                    }) {
                        Image(systemName: "h.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.purple)
                    .help("HoloMind Chief of Staff (⌘⇧H)")
                    
                    // Holo Quick Actions Menu
                    Menu {
                        Button("Summarize Page") {
                            onExecuteQuickAction?(.summarizePage)
                        }
                        Button("Detect Intent") {
                            onExecuteQuickAction?(.detectIntent)
                        }
                        Button("Save Memory") {
                            onExecuteQuickAction?(.saveToMemory)
                        }
                    } label: {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.purple)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 16)
                    .help("Holo Quick Actions")
                    
                    // AI Assistant Toggle Button
                    Button(action: {
                        withAnimation(HoloDesign.Animations.springNormal) {
                            aiManager.toggleSidebar()
                        }
                    }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(aiManager.isSidebarVisible ? .purple : .primary)
                    .help("Toggle Holo AI Sidebar")
                    
                    // Command Palette Button (⌘K)
                    Button(action: {
                        commandManager.togglePalette()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "command")
                                .font(.system(size: 11, weight: .bold))
                            Text("K")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Capsule().fill(Color.gray.opacity(0.15)))
                    .foregroundColor(.primary)
                    .help("Open Command Palette (⌘K)")
                    
                    // Focus Mode Toggle Button
                    Button(action: {
                        withAnimation(HoloDesign.Animations.springNormal) {
                            modeManager.toggleFocusMode()
                        }
                    }) {
                        Image(systemName: modeManager.currentMode.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(modeManager.currentMode == .focus ? .accentColor : .primary)
                    .help("Toggle Focus Mode")
                    
                    // Import Wizard Button
                    Button(action: {
                        onOpenImportWizard?()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                    .help("Import Browser Data & Migration Wizard")
                    
                    // Settings Preferences Button (⌘,)
                    Button(action: {
                        onOpenSettings?()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                    .help("Preferences (⌘,)")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .holoCrystalGlass(cornerRadius: 0)
            
            // Linear Progress Indicator
            if viewModel.isLoading && viewModel.progress < 1.0 {
                ProgressView(value: viewModel.progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(height: 2)
                    .tint(.accentColor)
            } else {
                Divider()
            }
        }
    }
}
