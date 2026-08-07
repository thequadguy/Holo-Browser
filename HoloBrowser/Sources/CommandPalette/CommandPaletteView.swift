import SwiftUI

/// Floating overlay modal view for the Cmd+K Command Palette with keyboard traversal support.
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
                    .foregroundColor(HoloTheme.Palette.holoCyan)
                
                TextField("Type a command or search open tabs...", text: $commandManager.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isSearchFocused)
                    .onSubmit {
                        commandManager.executeSelected()
                    }
                    .onMoveCommand { direction in
                        switch direction {
                        case .up:
                            commandManager.moveSelectionUp()
                        case .down:
                            commandManager.moveSelectionDown()
                        default:
                            break
                        }
                    }
                
                HStack(spacing: 4) {
                    Text("↑↓ Nav")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)))
                        .foregroundColor(.secondary)
                    
                    Text("ESC")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
            
            Divider()
            
            // Commands List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 4) {
                        if commandManager.filteredCommands.isEmpty {
                            Text("No matching commands or open tabs found")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .padding(24)
                        } else {
                            ForEach(Array(commandManager.filteredCommands.enumerated()), id: \.element.id) { index, command in
                                CommandItemRow(
                                    command: command,
                                    isSelected: index == commandManager.selectedIndex,
                                    onSelect: {
                                        commandManager.execute(command: command)
                                    }
                                )
                                .id(index)
                            }
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 320)
                .onChange(of: commandManager.selectedIndex) { _, newIndex in
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 540)
        .background(
            VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
                .cornerRadius(14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(HoloTheme.Palette.holoCyan.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: HoloTheme.Glow.cyan.opacity(0.3), radius: 24, x: 0, y: 8)
        .onAppear {
            isSearchFocused = true
        }
    }
}

private struct CommandItemRow: View {
    let command: Command
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: command.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected || isHovered ? HoloTheme.Palette.holoCyan : .primary)
                    .frame(width: 22)
                
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
                
                Text(categoryBadgeText(category: command.category))
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? HoloTheme.Palette.holoCyan.opacity(0.2) : Color.gray.opacity(0.12))
                    .foregroundColor(isSelected ? HoloTheme.Palette.holoCyan : .secondary)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? HoloTheme.Palette.holoCyan.opacity(0.15) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? HoloTheme.Palette.holoCyan.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovered = hover
        }
    }
    
    private func categoryBadgeText(category: CommandCategory) -> String {
        switch category {
        case .navigation: return "NAV"
        case .tabs: return "TAB"
        case .preferences: return "SETTING"
        case .system: return "HOLO"
        }
    }
}
