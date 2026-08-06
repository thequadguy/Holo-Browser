import SwiftUI

/// Native macOS settings view for viewing, enabling/disabling, and managing installed Holo extensions.
public struct ExtensionManagerView: View {
    @ObservedObject var extensionManager: ExtensionManager
    
    public init(extensionManager: ExtensionManager) {
        self.extensionManager = extensionManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                    Text("Extensions & UserScripts")
                        .font(.headline)
                }
                Spacer()
            }
            
            Divider()
            
            if extensionManager.extensions.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No extensions installed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(extensionManager.extensions) { ext in
                            ExtensionRowView(
                                extensionItem: ext,
                                onToggle: {
                                    extensionManager.toggleExtension(id: ext.id)
                                },
                                onDelete: {
                                    extensionManager.removeExtension(id: ext.id)
                                }
                            )
                        }
                    }
                }
                .frame(minHeight: 200, maxHeight: 320)
            }
        }
        .padding(16)
        .frame(width: 480)
        .sheet(item: Binding(
            get: { extensionManager.pendingInstallExtension },
            set: { _ in extensionManager.cancelInstall() }
        )) { ext in
            ExtensionPermissionView(
                extensionItem: ext,
                onConfirm: {
                    extensionManager.confirmInstall()
                },
                onCancel: {
                    extensionManager.cancelInstall()
                }
            )
        }
    }
}

private struct ExtensionRowView: View {
    let extensionItem: Extension
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: extensionItem.iconName)
                .font(.system(size: 20))
                .foregroundColor(extensionItem.enabled ? .accentColor : .secondary)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(extensionItem.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text("v\(extensionItem.version)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { extensionItem.enabled },
                        set: { _ in onToggle() }
                    ))
                    .toggleStyle(.switch)
                }
                
                Text("Type: \(extensionItem.type.rawValue) • By \(extensionItem.author)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(extensionItem.permissions) { perm in
                        Text(perm.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.purple.opacity(0.12)))
                            .foregroundColor(.purple)
                    }
                }
                .padding(.top, 2)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Remove extension")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}
