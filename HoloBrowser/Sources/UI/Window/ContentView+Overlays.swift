import SwiftUI
import WebKit

// MARK: - Content Overlays Extension

extension ContentView {
    @ViewBuilder
    var contentOverlaysView: some View {
        passwordSaveOverlay
        focusModeOverlay
        mediaPermissionOverlay
        webErrorOverlay
        javaScriptDialogOverlay
    }

    @ViewBuilder
    private var passwordSaveOverlay: some View {
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
    }

    @ViewBuilder
    private var focusModeOverlay: some View {
        if modeManager.currentMode == .focus {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(HoloDesign.Animations.springNormal) {
                            modeManager.toggleFocusMode()
                        }
                    }, label: {
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
                    })
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var mediaPermissionOverlay: some View {
        if let req = environment.permissionManager.pendingRequest {
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: mediaPermissionIcon(for: req.captureType))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mediaPermissionTitle(for: req.captureType))
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
    }

    @ViewBuilder
    private var webErrorOverlay: some View {
        if let errorMessage = viewModel.errorMessage {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            WebErrorOverlayView(
                errorMessage: errorMessage,
                onRetry: { viewModel.reloadOrStop() },
                onDismiss: { viewModel.dismissError() }
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var javaScriptDialogOverlay: some View {
        if let dialog = environment.permissionManager.pendingDialog {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                JavaScriptDialogOverlayView(
                    dialog: dialog,
                    onResolveAlert: {
                        environment.permissionManager.resolveAlert(id: dialog.id)
                    },
                    onResolveConfirm: { result in
                        environment.permissionManager.resolveConfirm(id: dialog.id, result: result)
                    },
                    onResolvePrompt: { text in
                        environment.permissionManager.resolvePrompt(id: dialog.id, text: text)
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            .animation(HoloDesign.Animations.springNormal, value: environment.permissionManager.pendingDialog?.id)
        }
    }

    private func mediaPermissionIcon(for captureType: WKMediaCaptureType) -> String {
        switch captureType {
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        default: return "camera.and.ellipsis"
        }
    }

    private func mediaPermissionTitle(for captureType: WKMediaCaptureType) -> String {
        switch captureType {
        case .camera: return "Camera Access Requested"
        case .microphone: return "Microphone Access Requested"
        default: return "Camera & Microphone Requested"
        }
    }
}

// MARK: - Keyboard Shortcut Handler

/// Keyboard shortcut delegate capturing Cmd+K, Cmd+Shift+A, Cmd+L, Cmd+T, Cmd+Shift+T, Cmd+W,
/// Cmd+Option+I, and Cmd+1..9.
struct KeyboardShortcutHandlerView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var commandManager: CommandManager
    @ObservedObject var modeManager: ModeManager
    @ObservedObject var aiManager: AIManager
    var onOpenSettings: (() -> Void)?

    var body: some View {
        ZStack {
            // Cmd + ,: Open Preferences / Settings
            Button("") { onOpenSettings?() }
                .keyboardShortcut(",", modifiers: [.command])
                .opacity(0)

            // Cmd + K: Command Palette
            Button("") { commandManager.togglePalette() }
                .keyboardShortcut("k", modifiers: [.command])
                .opacity(0)

            // Cmd + L: Focus Address Bar
            Button("") { HoloEventBus.shared.post(.focusAddressBar) }
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
            Button("") { viewModel.createNewTab() }
                .keyboardShortcut("t", modifiers: [.command])
                .opacity(0)

            // Cmd + W: Close Tab
            Button("") { viewModel.closeActiveTab() }
                .keyboardShortcut("w", modifiers: [.command])
                .opacity(0)

            // Cmd + Option + I: Web Inspector
            Button("") { viewModel.toggleWebInspector() }
                .keyboardShortcut("i", modifiers: [.command, .option])
                .opacity(0)

            // Cmd + 1..9: Switch Tabs
            ForEach(1...9, id: \.self) { index in
                Button("") { viewModel.selectTab(at: index - 1) }
                    .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: [.command])
                    .opacity(0)
            }
        }
    }
}
