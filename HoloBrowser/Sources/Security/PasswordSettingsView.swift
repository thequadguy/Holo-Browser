import SwiftUI

/// Native macOS settings view for viewing, searching, and managing saved website credentials.
/// Implements secure 30-second timed reveal lifecycles and immediate memory clearance on view disappearance.
public struct PasswordSettingsView: View {
    @ObservedObject var passwordManager: PasswordManager
    let activeProfileID: UUID
    
    @State private var searchQuery: String = ""
    @State private var revealedPasswords: [UUID: String] = [:]
    @State private var autoHideTasks: [UUID: Task<Void, Never>] = [:]
    
    public init(passwordManager: PasswordManager, activeProfileID: UUID) {
        self.passwordManager = passwordManager
        self.activeProfileID = activeProfileID
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header & Search
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .foregroundColor(.accentColor)
                    Text("Saved Passwords & Credentials")
                        .font(.headline)
                }
                Spacer()
            }
            
            // Warning Banner when any password is visible
            if !revealedPasswords.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.amberOrange)
                    Text("Plaintext password visible. Automatically hiding in 30 seconds.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.amberOrange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.12)))
            }
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search domain or username...", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
            
            Divider()
            
            // Credentials Table / List
            let list = passwordManager.searchCredentials(query: searchQuery, profileID: activeProfileID)
            
            if list.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "lock.shield")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No saved passwords for this profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(list) { cred in
                            CredentialRowView(
                                credential: cred,
                                revealedPassword: revealedPasswords[cred.id],
                                onReveal: {
                                    revealPassword(for: cred)
                                },
                                onHide: {
                                    hidePassword(for: cred.id)
                                },
                                onDelete: {
                                    hidePassword(for: cred.id)
                                    passwordManager.deleteCredential(id: cred.id)
                                }
                            )
                        }
                    }
                }
                .frame(minHeight: 200, maxHeight: 300)
            }
        }
        .padding(16)
        .frame(width: 480)
        .onDisappear {
            clearAllRevealedPasswords()
        }
    }
    
    private func revealPassword(for credential: PasswordCredential) {
        // Cancel existing timer task for this credential if any
        autoHideTasks[credential.id]?.cancel()
        
        Task { @MainActor in
            if let pass = await passwordManager.retrievePassword(for: credential) {
                revealedPasswords[credential.id] = pass
                
                // Schedule 30-second automatic memory clearance task
                let task = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                    guard !Task.isCancelled else { return }
                    self.hidePassword(for: credential.id)
                }
                autoHideTasks[credential.id] = task
            }
        }
    }
    
    private func hidePassword(for id: UUID) {
        autoHideTasks[id]?.cancel()
        autoHideTasks.removeValue(forKey: id)
        revealedPasswords.removeValue(forKey: id)
    }
    
    private func clearAllRevealedPasswords() {
        for task in autoHideTasks.values {
            task.cancel()
        }
        autoHideTasks.removeAll()
        revealedPasswords.removeAll()
    }
}

private struct CredentialRowView: View {
    let credential: PasswordCredential
    let revealedPassword: String?
    let onReveal: () -> Void
    let onHide: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(credential.domain)
                    .font(.system(size: 13, weight: .semibold))
                Text(credential.username)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let pass = revealedPassword {
                HStack(spacing: 6) {
                    Text(pass)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                    
                    Button("Hide") {
                        onHide()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                }
            } else {
                Button("Reveal") {
                    onReveal()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Delete credential")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

private extension Color {
    static let amberOrange = Color(red: 0.9, green: 0.5, blue: 0.1)
}
