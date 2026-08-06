import SwiftUI

/// Floating overlay modal view for the Cmd+K Command Palette.
public struct CommandPaletteView: View {
    @ObservedObject var commandManager: CommandManager
    @FocusState private var isSearchFocused: Bool
    
    public init(commandManager: CommandManager) {
        self.commandManager = commandManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Type a command or search...", text: $commandManager.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isSearchFocused)
                    .onSubmit {
                        if let first = commandManager.filteredCommands.first {
                            commandManager.execute(command: first)
                        }
                    }
                
                Text("ESC")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
            
            Divider()
            
            // Commands List
            ScrollView {
                VStack(spacing: 4) {
                    if commandManager.filteredCommands.isEmpty {
                        Text("No matching commands found")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(24)
                    } else {
                        ForEach(commandManager.filteredCommands) { command in
                            CommandItemRow(command: command) {
                                commandManager.execute(command: command)
                            }
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 280)
        }
        .frame(width: 520)
        .background(
            VisualEffectViewWrapper(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            isSearchFocused = true
        }
    }
}

private struct CommandItemRow: View {
    let command: Command
    let onSelect: () -> Void
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isHovered ? .accentColor : .primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(command.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                if let subtitle = command.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(command.category.rawValue)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.gray.opacity(0.15)))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
