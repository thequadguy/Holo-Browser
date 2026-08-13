import SwiftUI

/// Popover UI for displaying, switching, creating, and customizing browser profiles.
public struct ProfileSwitcherView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var showCreateSheet: Bool = false
    @State private var profileToEdit: BrowserProfile? = nil
    
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
                    showCreateSheet = true
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
                VStack(spacing: 6) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileRowView(
                            profile: profile,
                            isActive: profile.id == profileManager.activeProfile.id,
                            onSelect: {
                                profileManager.selectProfile(id: profile.id)
                            },
                            onEdit: {
                                profileToEdit = profile
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(14)
        .frame(width: 280)
        .background(
            ZStack {
                VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
                HoloTheme.Palette.chromeFill
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HoloTheme.Palette.glassBorderGradient, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showCreateSheet) {
            CreateProfileSheetView(profileManager: profileManager) {
                showCreateSheet = false
            }
        }
        .sheet(item: $profileToEdit) { profile in
            CreateProfileSheetView(profileManager: profileManager, existingProfile: profile) {
                profileToEdit = nil
            }
        }
    }
}

private struct ProfileRowView: View {
    let profile: BrowserProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(hex: profile.colorHex))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: profile.iconName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(profile.name)
                                .font(.system(size: 12, weight: isActive ? .bold : .regular))
                                .foregroundColor(.primary)
                            
                            if profile.isPrivate {
                                HoloBadge("Private", color: .purple)
                            } else {
                                HoloBadge(profile.purpose.rawValue, color: Color(hex: profile.colorHex))
                            }
                        }
                        
                        Text(profile.aiMemoryEnabled ? "AI Memory Enabled" : "AI Memory Off")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: onEdit) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14)) // Increased for accessibility
                    .foregroundColor(.secondary)
                    .padding(8) // Larger hit target
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Edit Profile")
            
            if isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.accentColor)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.accentColor.opacity(0.12) : Color.clear)
        )
    }
}
