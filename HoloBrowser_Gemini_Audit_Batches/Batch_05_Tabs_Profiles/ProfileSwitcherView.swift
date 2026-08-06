import SwiftUI

/// Popover UI for displaying, switching, and creating browser profiles.
public struct ProfileSwitcherView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var showNewProfileSheet: Bool = false
    @State private var newProfileName: String = ""
    @State private var selectedColorHex: String = "#007AFF"
    
    private let availableColors = ["#007AFF", "#34C759", "#FF9500", "#FF2D55", "#AF52DE", "#5856D6"]
    
    public init(profileManager: ProfileManager) {
        self.profileManager = profileManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Browser Profiles")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button(action: {
                    showNewProfileSheet.toggle()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("Create Profile")
            }
            
            Divider()
            
            // Profile List
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileRowView(
                            profile: profile,
                            isActive: profile.id == profileManager.activeProfile.id,
                            onSelect: {
                                profileManager.selectProfile(id: profile.id)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 180)
            
            // Inline New Profile Form
            if showNewProfileSheet {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text("New Profile").font(.caption).bold()
                    
                    TextField("Profile Name", text: $newProfileName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 8) {
                        ForEach(availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle().stroke(Color.primary, lineWidth: selectedColorHex == hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                    
                    HStack {
                        Button("Cancel") {
                            showNewProfileSheet = false
                            newProfileName = ""
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button("Create") {
                            let trimmed = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            profileManager.createProfile(name: trimmed, colorHex: selectedColorHex)
                            newProfileName = ""
                            showNewProfileSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(
            VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
        )
    }
}

private struct ProfileRowView: View {
    let profile: BrowserProfile
    let isActive: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: profile.colorHex))
                .frame(width: 20, height: 20)
                .overlay(
                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.system(size: 12, weight: isActive ? .bold : .regular))
                    .foregroundColor(.primary)
                
                if profile.isPrivate {
                    Text("Private Mode")
                        .font(.system(size: 9))
                        .foregroundColor(.purple)
                }
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
