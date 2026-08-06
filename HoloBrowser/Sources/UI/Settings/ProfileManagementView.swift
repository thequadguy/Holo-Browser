import SwiftUI

/// Profile Management Settings View allowing full customization, separate browsing data controls, and profile deletion.
public struct ProfileManagementView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var profileToEdit: BrowserProfile? = nil
    @State private var showCreateSheet: Bool = false
    @State private var dataClearedMessage: String? = nil
    
    public init(profileManager: ProfileManager) {
        self.profileManager = profileManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Profile Management")
                        .font(.system(size: 16, weight: .bold))
                    Text("Manage profile containers, WKWebsiteDataStore data isolation, and AI memory settings")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HoloGlassButton(title: "Add Profile", icon: "plus", isProminent: true) {
                    showCreateSheet = true
                }
            }
            
            Divider()
            
            if #unavailable(macOS 14.0) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Degraded Profile Isolation")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("True profile isolation requires macOS 14+. Holo is using non-persistent fallback stores. Your data is private, but session cookies will not survive restarts.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.yellow.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                .padding(.bottom, 4)
            }
            
            if let msg = dataClearedMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(msg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.1)))
            }
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileDetailCard(
                            profile: profile,
                            isActive: profile.id == profileManager.activeProfile.id,
                            canDelete: profileManager.profiles.count > 1,
                            onSelect: {
                                profileManager.selectProfile(id: profile.id)
                            },
                            onEdit: {
                                profileToEdit = profile
                            },
                            onClearData: {
                                profileManager.clearProfileBrowsingData(id: profile.id)
                                dataClearedMessage = "Cleared web cookies, cache, and storage for '\(profile.name)'."
                            },
                            onDelete: {
                                profileManager.deleteProfile(id: profile.id)
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
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

private struct ProfileDetailCard: View {
    let profile: BrowserProfile
    let isActive: Bool
    let canDelete: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onClearData: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: profile.colorHex))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: profile.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 13, weight: .bold))
                    
                    if isActive {
                        HoloBadge("Active", color: .accentColor)
                    }
                    
                    HoloBadge(profile.purpose.rawValue, color: Color(hex: profile.colorHex))
                }
                
                Text(profile.isPrivate ? "Non-persistent ephemeral data store" : "Isolated WKWebsiteDataStore ID: \(profile.storageIdentifier.prefix(8))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if !isActive {
                    HoloGlassButton(title: "Switch", icon: "arrow.triangle.2.circlepath") {
                        onSelect()
                    }
                }
                
                HoloGlassButton(title: "Edit", icon: "pencil") {
                    onEdit()
                }
                
                HoloGlassButton(title: "Clear Data", icon: "trash") {
                    onClearData()
                }
                
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.bin.fill")
                            .foregroundColor(.red)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Delete Profile")
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.accentColor.opacity(0.08) : Color.gray.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}
