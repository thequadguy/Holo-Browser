import SwiftUI

/// Form sheet for creating or editing browser profiles with custom icons, color swatches, purpose presets, and AI memory controls.
public struct CreateProfileSheetView: View {
    @ObservedObject var profileManager: ProfileManager
    let existingProfile: BrowserProfile?
    let onDismiss: () -> Void
    
    @State private var name: String = ""
    @State private var selectedColorHex: String = "#007AFF"
    @State private var selectedIcon: String = "person.fill"
    @State private var selectedPurpose: ProfilePurpose = .personal
    @State private var aiMemoryEnabled: Bool = true
    @State private var isPrivateMode: Bool = false
    
    private let availableColors = ["#007AFF", "#34C759", "#AF52DE", "#FF9500", "#FF2D55", "#5856D6", "#00C7BE"]
    private let availableIcons = ["person.fill", "briefcase.fill", "atom", "book.fill", "cart.fill", "desktopcomputer", "terminal.fill", "shield.fill"]
    
    public init(
        profileManager: ProfileManager,
        existingProfile: BrowserProfile? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.profileManager = profileManager
        self.existingProfile = existingProfile
        self.onDismiss = onDismiss
        
        if let existing = existingProfile {
            _name = State(initialValue: existing.name)
            _selectedColorHex = State(initialValue: existing.colorHex)
            _selectedIcon = State(initialValue: existing.iconName)
            _selectedPurpose = State(initialValue: existing.purpose)
            _aiMemoryEnabled = State(initialValue: existing.aiMemoryEnabled)
            _isPrivateMode = State(initialValue: existing.isPrivate)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(existingProfile == nil ? "Create New Profile" : "Edit Profile")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
            
            Divider()
            
            // Form Body
            VStack(alignment: .leading, spacing: 14) {
                // Profile Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Name").font(.system(size: 12, weight: .semibold))
                    TextField("e.g. Work, Personal, Research", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Profile Purpose Preset
                VStack(alignment: .leading, spacing: 6) {
                    Text("Purpose Preset").font(.system(size: 12, weight: .semibold))
                    HStack(spacing: 8) {
                        ForEach(ProfilePurpose.allCases) { purpose in
                            HoloBadge(
                                purpose.rawValue,
                                color: selectedPurpose == purpose ? .accentColor : .secondary
                            )
                            .onTapGesture {
                                selectedPurpose = purpose
                                selectedIcon = purpose.defaultIcon
                                selectedColorHex = purpose.defaultColorHex
                            }
                        }
                    }
                }
                
                // Icon Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Avatar Icon").font(.system(size: 12, weight: .semibold))
                    HStack(spacing: 10) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 14))
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.accentColor : Color.gray.opacity(0.12))
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                }
                
                // Color Theme Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Color Theme").font(.system(size: 12, weight: .semibold))
                    HStack(spacing: 10) {
                        ForEach(availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle().stroke(Color.primary, lineWidth: selectedColorHex == hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                }
                
                // Separate AI Memory Controls
                Toggle("Enable Isolated AI Memory for this Profile", isOn: $aiMemoryEnabled)
                    .font(.system(size: 11))
                    .disabled(isPrivateMode)
                
                if isPrivateMode {
                    Text("Private browsing profiles do not store persistent AI memory.")
                        .font(.system(size: 10))
                        .foregroundColor(.purple)
                }
            }
            .padding(18)
            
            Divider()
            
            // Footer Action Bar
            HStack {
                HoloGlassButton(title: "Cancel") {
                    onDismiss()
                }
                
                Spacer()
                
                HoloGlassButton(title: existingProfile == nil ? "Create Profile" : "Save Changes", isProminent: true) {
                    saveProfile()
                }
            }
            .padding(14)
            .background(VisualEffectViewWrapper(material: .headerView, blendingMode: .withinWindow))
        }
        .frame(width: 420)
        .holoGlassCard(cornerRadius: 12, padding: 0)
    }
    
    private func saveProfile() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let existing = existingProfile {
            profileManager.updateProfile(
                id: existing.id,
                name: trimmed,
                colorHex: selectedColorHex,
                iconName: selectedIcon,
                purpose: selectedPurpose,
                aiMemoryEnabled: aiMemoryEnabled
            )
        } else {
            profileManager.createProfile(
                name: trimmed,
                colorHex: selectedColorHex,
                iconName: selectedIcon,
                purpose: selectedPurpose,
                aiMemoryEnabled: aiMemoryEnabled,
                isPrivate: isPrivateMode
            )
        }
        onDismiss()
    }
}
