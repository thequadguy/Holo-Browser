import SwiftUI

/// Premium floating browser toolbar featuring frosted glass translucency, Profile Switcher, AI button, and Holo controls.
public struct NavigationToolbarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var commandManager: CommandManager
    @ObservedObject var modeManager: ModeManager
    @ObservedObject var aiManager: AIManager
    
    @State private var showProfilePopover: Bool = false
    
    public init(
        viewModel: BrowserViewModel,
        commandManager: CommandManager,
        modeManager: ModeManager,
        aiManager: AIManager
    ) {
        self.viewModel = viewModel
        self.commandManager = commandManager
        self.modeManager = modeManager
        self.aiManager = aiManager
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
                            .overlay(
                                Text(String(viewModel.profileManager.activeProfile.name.prefix(1)).uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(viewModel.profileManager.activeProfile.name)
                            .font(.system(size: 11, weight: .medium))
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
                
                // Holo Action Controls (AI, Cmd+K, Mode Toggle)
                HStack(spacing: 4) {
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
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow)
            )
            
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
