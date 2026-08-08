import SwiftUI
import WebKit
import AppKit

public enum SettingsCategory: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case search = "Search Engine"
    case tabs = "Tabs"
    case privacy = "Privacy & Security"
    case passwords = "Passwords"
    case autofill = "Autofill"
    case downloads = "Downloads"
    case languages = "Languages"
    case system = "System"
    case accessibility = "Accessibility"
    case profiles = "Profiles"
    case extensions = "Extensions"
    case holomind = "HoloMind"
    case advanced = "Advanced"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .appearance: return "paintbrush.fill"
        case .search: return "magnifyingglass"
        case .tabs: return "square.stack.fill"
        case .privacy: return "shield.checkerboard"
        case .passwords: return "key.fill"
        case .autofill: return "creditcard.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .languages: return "globe"
        case .system: return "cpu.fill"
        case .accessibility: return "figure.wave"
        case .profiles: return "person.crop.circle.fill"
        case .extensions: return "puzzlepiece.fill"
        case .holomind: return "brain.head.profile"
        case .advanced: return "slider.horizontal.3"
        }
    }
}

/// Native Window Controller hosting the full application Settings experience.
public final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = SettingsWindowController()
    
    public convenience init() {
        self.init(window: nil)
    }
    
    public func open(viewModel: BrowserViewModel, privacyManager: AIPrivacyManager) {
        if let existingWindow = self.window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView(viewModel: viewModel, privacyManager: privacyManager, onClose: { [weak self] in
            self?.closeWindow()
        })
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Preferences"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        // Crucial: assign windowController and NSWindowController.window property so AppKit recognizes ownership & enables red close button
        self.window = window
        window.windowController = self
        
        // Explicitly enable standard macOS traffic light controls
        if let closeButton = window.standardWindowButton(.closeButton) {
            closeButton.isEnabled = true
            closeButton.target = self
            closeButton.action = #selector(handleCloseButton)
        }
        if let miniButton = window.standardWindowButton(.miniaturizeButton) {
            miniButton.isEnabled = true
        }
        if let zoomButton = window.standardWindowButton(.zoomButton) {
            zoomButton.isEnabled = true
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func handleCloseButton() {
        closeWindow()
    }
    
    public func closeWindow() {
        self.window?.close()
        self.window = nil
    }
    
    public func windowWillClose(_ notification: Notification) {
        self.window = nil
    }
}

/// Comprehensive Chrome-level application Settings architecture for Holo Browser.
public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var privacyManager: AIPrivacyManager
    @ObservedObject private var settings = HoloStartupSettings.shared
    @ObservedObject private var appearanceSettings = HoloAppearanceSettings.shared
    
    var onClose: (() -> Void)? = nil
    
    @State private var selectedCategory: SettingsCategory = .general
    @State private var searchQuery: String = ""
    
    // Preferences Storage
    @AppStorage("defaultNewTabBehavior") private var newTabBehavior: String = "Command Center"
    @AppStorage("downloadPath") private var downloadPath: String = "~/Downloads"
    @AppStorage("askDownloadDestination") private var askDownloadDestination: Bool = false
    @AppStorage("autoOpenSafeDownloads") private var autoOpenSafeDownloads: Bool = true
    @AppStorage("searchEngine") private var searchEngine: String = "Brave Search"
    @AppStorage("searchSuggestionsEnabled") private var searchSuggestionsEnabled: Bool = true
    @AppStorage("aiSearchRouting") private var aiSearchRouting: Bool = true
    @AppStorage("addressBarAI") private var addressBarAI: Bool = true
    
    @AppStorage("autoDiscardTabs") private var autoDiscardTabs: Bool = true
    @AppStorage("tabHoverPreview") private var tabHoverPreview: Bool = true
    
    @AppStorage("trackingProtection") private var trackingProtection: Bool = true
    @AppStorage("blockThirdPartyCookies") private var blockThirdPartyCookies: Bool = true
    @AppStorage("httpsOnlyMode") private var httpsOnlyMode: Bool = true
    
    @AppStorage("passwordAutoFill") private var passwordAutoFill: Bool = true
    @AppStorage("masterPasswordEnabled") private var masterPasswordEnabled: Bool = false
    
    @AppStorage("autofillAddresses") private var autofillAddresses: Bool = true
    @AppStorage("autofillPayments") private var autofillPayments: Bool = true
    
    @AppStorage("spellCheckEnabled") private var spellCheckEnabled: Bool = true
    @AppStorage("translatePromptEnabled") private var translatePromptEnabled: Bool = true
    
    @AppStorage("hardwareAcceleration") private var hardwareAcceleration: Bool = true
    @AppStorage("backgroundProcessOptimization") private var backgroundProcessOptimization: Bool = true
    
    @AppStorage("pageZoomScale") private var pageZoomScale: Double = 1.0
    @AppStorage("highContrastMode") private var highContrastMode: Bool = false
    
    @AppStorage("holoMemoryEnabled") private var holoMemoryEnabled: Bool = true
    @AppStorage("proactiveIntelligence") private var proactiveIntelligence: String = "Balanced"
    @AppStorage("missionApprovalRequired") private var missionApprovalRequired: Bool = true
    
    @AppStorage("developerFlagsEnabled") private var developerFlagsEnabled: Bool = false
    
    public init(viewModel: BrowserViewModel, privacyManager: AIPrivacyManager, onClose: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.privacyManager = privacyManager
        self.onClose = onClose
    }
    
    var filteredCategories: [SettingsCategory] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return SettingsCategory.allCases
        }
        let q = searchQuery.lowercased()
        return SettingsCategory.allCases.filter { cat in
            cat.rawValue.lowercased().contains(q) || categoryMatchesQuery(cat, q: q)
        }
    }
    
    private func categoryMatchesQuery(_ category: SettingsCategory, q: String) -> Bool {
        switch category {
        case .general: return "startup homepage new tab default downloads".contains(q)
        case .appearance: return "liquid glass dark mode theme animation vibrancy".contains(q)
        case .search: return "engine brave suggestions omnibox routing".contains(q)
        case .tabs: return "pin group discard preview cards".contains(q)
        case .privacy: return "cookies tracking https clear browsing data gatekeeper".contains(q)
        case .passwords: return "key credentials master fill alert breach".contains(q)
        case .autofill: return "payment address credit card form".contains(q)
        case .downloads: return "location folder path destination open".contains(q)
        case .languages: return "translate spell check english".contains(q)
        case .system: return "hardware acceleration GPU network proxy".contains(q)
        case .accessibility: return "zoom scale contrast screen reader".contains(q)
        case .profiles: return "avatar account user isolation multi".contains(q)
        case .extensions: return "webextension addon permission storage".contains(q)
        case .holomind: return "ai memory proactive intelligence export clear mission".contains(q)
        case .advanced: return "reset developer flags diagnostics export".contains(q)
        }
    }
    
    public var body: some View {
        ZStack {
            // Invisible Keyboard Shortcut Captures
            Group {
                Button("") {
                    if let onClose = onClose {
                        onClose()
                    } else {
                        SettingsWindowController.shared.closeWindow()
                        dismiss()
                    }
                }
                .keyboardShortcut("w", modifiers: [.command])
                .opacity(0)
                
                Button("") {
                    NSApp.keyWindow?.miniaturize(nil)
                }
                .keyboardShortcut("m", modifiers: [.command])
                .opacity(0)
            }
            
            HStack(spacing: 0) {
                // Sidebar Navigation (HoloFrost Tier)
                VStack(alignment: .leading, spacing: 10) {
                    // Window Traffic Light Spacing & Title Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(HoloTheme.Palette.holoCyan)
                            Text("Preferences")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(HoloTheme.Text.primary)
                            Spacer()
                        }
                        .padding(.leading, 70) // Clearance for native traffic light window buttons
                        .padding(.trailing, 10)
                        
                        // "Find settings" Search Bar
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            TextField("Find settings...", text: $searchQuery)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                            if !searchQuery.isEmpty {
                                Button(action: { searchQuery = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .holoClearGlass(cornerRadius: 8)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                    
                    Divider()
                    
                    // Category List
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(filteredCategories) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: category.iconName)
                                            .font(.system(size: 13, weight: selectedCategory == category ? .bold : .regular))
                                            .foregroundColor(selectedCategory == category ? HoloTheme.Palette.holoCyan : .secondary)
                                            .frame(width: 18)
                                        
                                        Text(category.rawValue)
                                            .font(.system(size: 12, weight: selectedCategory == category ? .semibold : .regular))
                                            .foregroundColor(selectedCategory == category ? HoloTheme.Text.primary : HoloTheme.Text.secondary)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(selectedCategory == category ? HoloTheme.Palette.holoCyan.opacity(0.16) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedCategory == category ? HoloTheme.Palette.holoCyan.opacity(0.35) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    Spacer()
                }
                .frame(width: 220)
                .holoFrostGlass(cornerRadius: 0)
                
                Divider()
                
                // Detail Content View (HoloSolid Glass Tier)
                VStack(alignment: .leading, spacing: 0) {
                    // Header Title Banner with Close Button
                    HStack {
                        Image(systemName: selectedCategory.iconName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(HoloTheme.Palette.holoCyan)
                        Text(selectedCategory.rawValue)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(HoloTheme.Text.primary)
                        Spacer()
                        
                        Button(action: {
                            if let onClose = onClose {
                                onClose()
                            } else {
                                SettingsWindowController.shared.closeWindow()
                                dismiss()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.03))
                    
                    Divider()
                    
                    // Detailed Preference Pages
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            switch selectedCategory {
                            case .general:
                                renderGeneralSettings()
                            case .appearance:
                                renderAppearanceSettings()
                            case .search:
                                renderSearchSettings()
                            case .tabs:
                                renderTabSettings()
                            case .privacy:
                                renderPrivacySettings()
                            case .passwords:
                                renderPasswordSettings()
                            case .autofill:
                                renderAutofillSettings()
                            case .downloads:
                                renderDownloadSettings()
                            case .languages:
                                renderLanguageSettings()
                            case .system:
                                renderSystemSettings()
                            case .accessibility:
                                renderAccessibilitySettings()
                            case .profiles:
                                ProfileManagementView(profileManager: viewModel.profileManager)
                            case .extensions:
                                renderExtensionSettings()
                            case .holomind:
                                renderHoloMindSettings()
                            case .advanced:
                                renderAdvancedSettings()
                            }
                        }
                        .padding(20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .holoSolidGlass(cornerRadius: 0)
            }
        }
        .frame(width: 880, height: 620)
    }
    
    // MARK: - Category View Builders
    
    @ViewBuilder
    private func renderGeneralSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Startup Behavior").font(.headline)
            Picker("", selection: $settings.startupBehavior) {
                ForEach(HoloStartupBehavior.allCases) { behavior in
                    Text(behavior.rawValue).tag(behavior)
                }
            }
            .pickerStyle(.radioGroup)
            
            if settings.startupBehavior == .custom {
                TextField("Custom Homepage URL", text: $settings.customHomepageURL)
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            Text("New Tab Page").font(.headline)
            Picker("", selection: $newTabBehavior) {
                Text("Holo Command Center").tag("Command Center")
                Text("Blank Page").tag("Blank Page")
            }
            .pickerStyle(.radioGroup)
            
            Divider()
            
            Text("Default Browser").font(.headline)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Make Holo Browser your default web browser").font(.subheadline)
                    Text("Holo Browser is not currently set as default.").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button("Set as Default") {
                    MacIntegrationManager.openDefaultBrowserSettings()
                }
                .buttonStyle(HoloSecondaryButtonStyle())
            }
        }
    }
    
    @ViewBuilder
    private func renderAppearanceSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Liquid Glass Engine").font(.headline)
            Toggle("Liquid Glass Interface", isOn: $appearanceSettings.enableLiquidGlass)
            Toggle("Holographic Accents & Glowing Halos", isOn: $appearanceSettings.enableHolographicAccents)
            Toggle("Animated Background Particle Field", isOn: $appearanceSettings.enableAnimatedBackground)
            Toggle("H Presence Subtle Motion Effects", isOn: $appearanceSettings.enableHPresenceEffects)
            Toggle("Active Tab Ambient Glow", isOn: $appearanceSettings.enableTabGlow)
            Toggle("Reduced Motion", isOn: $appearanceSettings.reducedMotion)
            
            Divider()
            
            Text("Performance Level").font(.headline)
            Picker("", selection: $appearanceSettings.effectsLevelString) {
                ForEach(HoloEffectsLevel.allCases) { level in
                    Text(level.rawValue).tag(level.rawValue)
                }
            }
            .pickerStyle(.segmented)
            Text("Controls liquid glass transparency, blur radius, and particle intensity.").font(.caption).foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func renderSearchSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Default Search Engine").font(.headline)
            Picker("Engine", selection: $searchEngine) {
                Text("Brave Search (Recommended)").tag("Brave Search")
                Text("DuckDuckGo").tag("DuckDuckGo")
                Text("Google").tag("Google")
                Text("Bing").tag("Bing")
            }
            .pickerStyle(.menu)
            
            Divider()
            
            Text("Smart Search Routing").font(.headline)
            Toggle("Enable Omnibox Search Suggestions", isOn: $searchSuggestionsEnabled)
            Toggle("Automatically route 'h' queries to HoloMind AI", isOn: $aiSearchRouting)
            Toggle("Display AI Action previews in Address Bar", isOn: $addressBarAI)
        }
    }
    
    @ViewBuilder
    private func renderTabSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tab Management").font(.headline)
            Toggle("Auto-discard inactive tabs to save memory", isOn: $autoDiscardTabs)
            Toggle("Show live hover previews when hovering tab items", isOn: $tabHoverPreview)
            
            Divider()
            
            Text("Tab Groups & Pinning").font(.headline)
            Text("Pinned tabs automatically align to the left of the tab bar with compact layout protection.").font(.caption).foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func renderPrivacySettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browsing Security").font(.headline)
            Toggle("Strict Tracking Protection", isOn: $trackingProtection)
            Toggle("Block Third-Party Cookies", isOn: $blockThirdPartyCookies)
            Toggle("HTTPS-Only Mode", isOn: $httpsOnlyMode)
            
            Divider()
            
            Text("Browsing Data").font(.headline)
            Button("Clear Browsing Data...") {
                let store = viewModel.profileManager.activeWebsiteDataStore
                let types = WKWebsiteDataStore.allWebsiteDataTypes()
                store.removeData(ofTypes: types, modifiedSince: Date.distantPast) {}
                viewModel.downloadManager.clearCompleted()
            }
            .buttonStyle(HoloSecondaryButtonStyle())
            
            Divider()
            
            Text("AI Privacy Gatekeeper").font(.headline)
            PrivacyDashboardView()
        }
    }
    
    @ViewBuilder
    private func renderPasswordSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Password Manager").font(.headline)
            Toggle("Auto-fill passwords and credentials", isOn: $passwordAutoFill)
            Toggle("Require Master Password / Touch ID for vault access", isOn: $masterPasswordEnabled)
            
            Divider()
            
            Text("Credential Vault").font(.headline)
            Text("Passwords stored securely in macOS Keychain with AES-256 encryption.").font(.caption).foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func renderAutofillSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Autofill Settings").font(.headline)
            Toggle("Autofill saved addresses and contact info", isOn: $autofillAddresses)
            Toggle("Autofill payment methods & cards", isOn: $autofillPayments)
        }
    }
    
    @ViewBuilder
    private func renderDownloadSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Downloads Destination").font(.headline)
            HStack {
                Text("Location:")
                TextField("Download Path", text: $downloadPath)
                    .textFieldStyle(.roundedBorder)
                Button("Change...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        downloadPath = url.path
                    }
                }
                .buttonStyle(HoloSecondaryButtonStyle())
            }
            
            Toggle("Ask where to save each file before downloading", isOn: $askDownloadDestination)
            Toggle("Automatically open safe downloads after completion", isOn: $autoOpenSafeDownloads)
        }
    }
    
    @ViewBuilder
    private func renderLanguageSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Languages & Spell Check").font(.headline)
            Toggle("Enable spell check for text inputs", isOn: $spellCheckEnabled)
            Toggle("Prompt to translate pages in foreign languages", isOn: $translatePromptEnabled)
        }
    }
    
    @ViewBuilder
    private func renderSystemSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System & Hardware Acceleration").font(.headline)
            Toggle("Use Metal hardware acceleration when available", isOn: $hardwareAcceleration)
            Toggle("Optimize background tab process memory footprint", isOn: $backgroundProcessOptimization)
        }
    }
    
    @ViewBuilder
    private func renderAccessibilitySettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Page Scaling").font(.headline)
            HStack {
                Text("Default Zoom Level:")
                Slider(value: $pageZoomScale, in: 0.8...1.5, step: 0.1)
                Text("\(Int(pageZoomScale * 100))%")
                    .font(.monospacedDigit(.body)())
            }
            
            Toggle("High Contrast Mode", isOn: $highContrastMode)
        }
    }
    
    @ViewBuilder
    private func renderExtensionSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WebExtensions Registry").font(.headline)
            ExtensionManagerView(extensionManager: viewModel.extensionManager)
        }
    }
    
    @ViewBuilder
    private func renderHoloMindSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Memory Engine").font(.headline)
            Toggle("Enable HoloMind Personal Memory", isOn: $holoMemoryEnabled)
            
            HStack(spacing: 12) {
                Button("Clear All Memories") {
                    MemoryPrivacyManager.clearAllMemories()
                }
                .buttonStyle(HoloSecondaryButtonStyle())
                
                Button("Export Memories (JSON)") {
                    let json = MemoryPrivacyManager.exportMemoriesJSON()
                    let panel = NSSavePanel()
                    panel.nameFieldStringValue = "holo_memories.json"
                    if panel.runModal() == .OK, let url = panel.url {
                        try? json.data(using: .utf8)?.write(to: url)
                    }
                }
                .buttonStyle(HoloSecondaryButtonStyle())
            }
            
            Divider()
            
            Text("Proactive Intelligence Level").font(.headline)
            Picker("", selection: $proactiveIntelligence) {
                Text("Maximum (Suggestions for all tasks)").tag("Maximum")
                Text("Balanced (High confidence only)").tag("Balanced")
                Text("Minimal (Only when explicitly asked)").tag("Minimal")
            }
            .pickerStyle(.radioGroup)
            
            Divider()
            
            Text("Mission Safety").font(.headline)
            Toggle("Require my explicit approval before executing actions", isOn: $missionApprovalRequired)
        }
    }
    
    @ViewBuilder
    private func renderAdvancedSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Developer & Diagnostic Tools").font(.headline)
            Toggle("Enable Developer Flags & Diagnostics Overlays", isOn: $developerFlagsEnabled)
            
            Divider()
            
            Text("Reset Preferences").font(.headline)
            Button("Reset All Preferences to Factory Defaults") {
                settings.startupBehavior = .commandCenter
                appearanceSettings.enableLiquidGlass = true
                appearanceSettings.enableHolographicAccents = true
                appearanceSettings.enableAnimatedBackground = true
                searchEngine = "Brave Search"
                searchSuggestionsEnabled = true
                trackingProtection = true
                blockThirdPartyCookies = true
            }
            .buttonStyle(HoloSecondaryButtonStyle())
        }
    }
}
