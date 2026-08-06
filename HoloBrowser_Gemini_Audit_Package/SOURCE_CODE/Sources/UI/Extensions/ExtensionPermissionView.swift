import SwiftUI

/// Approval sheet prompting user permission consent before extension installation.
public struct ExtensionPermissionView: View {
    let extensionItem: Extension
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    public init(
        extensionItem: Extension,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.extensionItem = extensionItem
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: extensionItem.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Install \(extensionItem.name)?")
                        .font(.headline)
                    Text("Version \(extensionItem.version) • By \(extensionItem.author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Requested Permissions:")
                    .font(.system(size: 12, weight: .bold))
                
                ForEach(extensionItem.permissions) { perm in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.purple)
                            .font(.system(size: 12))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(perm.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                            Text(perm.description)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Install Extension") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(width: 380)
    }
}
