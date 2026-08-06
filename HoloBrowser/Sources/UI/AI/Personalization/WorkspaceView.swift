import SwiftUI

/// Workspace project selector and tab manager view.
public struct WorkspaceView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    let profileID: UUID
    let isPrivate: Bool
    
    @State private var newName: String = ""
    
    public init(workspaceManager: WorkspaceManager, profileID: UUID, isPrivate: Bool) {
        self.workspaceManager = workspaceManager
        self.profileID = profileID
        self.isPrivate = isPrivate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.accentColor)
                    Text("AI Workspaces & Projects")
                        .font(.headline)
                }
                Spacer()
            }
            
            Divider()
            
            if isPrivate {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("Workspaces Disabled in Private Browsing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                HStack {
                    TextField("New Workspace Name...", text: $newName)
                        .textFieldStyle(.roundedBorder)
                    Button("Create") {
                        guard !newName.isEmpty else { return }
                        workspaceManager.createWorkspace(name: newName, profileID: profileID, isPrivate: isPrivate)
                        newName = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                
                let list = workspaceManager.workspaces(for: profileID)
                
                if list.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "folder")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        Text("No workspaces created yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(list) { ws in
                                HStack {
                                    Image(systemName: ws.iconName)
                                        .foregroundColor(.accentColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ws.name)
                                            .font(.system(size: 12, weight: .bold))
                                        Text("\(ws.tabURLs.count) tabs | \(ws.noteIDs.count) notes")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        workspaceManager.deleteWorkspace(id: ws.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                            }
                        }
                    }
                    .frame(minHeight: 160, maxHeight: 260)
                }
            }
        }
        .padding(14)
        .frame(width: 420)
    }
}
