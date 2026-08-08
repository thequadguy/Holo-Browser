import SwiftUI
import Combine

public extension Notification.Name {
    static let focusAddressBar = Notification.Name("focusAddressBar")
}

/// 3D Liquid Glass Intelligent Omnibox Address Bar.
/// Replaces the static address bar with a dynamic intent-driven command field.
public struct AddressBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @FocusState private var isFocused: Bool
    
    @StateObject private var omniboxViewModel = OmniboxViewModel()
    
    public init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
    }
    
    // Dynamic Intent Resolution via HoloSmartSearchRouter
    private var currentRoute: HoloSearchRoute {
        HoloSmartSearchRouter.route(for: viewModel.inputURLString)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Unified Intelligent Omnibox Capsule
            HStack(spacing: 8) {
                // Dynamic Leading Badge / Icon
                Group {
                    switch currentRoute {
                    case .ai(_, _):
                        HStack(spacing: 4) {
                            HoloAssistantPresenceView(state: .listening)
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                            if isFocused {
                                Text("HoloMind")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(HoloTheme.Palette.holoCyan)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(HoloTheme.Palette.holoCyan.opacity(0.16)))
                        
                    case .mission(_):
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(HoloTheme.Palette.holoEmerald)
                            if isFocused {
                                Text("Mission")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(HoloTheme.Palette.holoEmerald)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(HoloTheme.Palette.holoEmerald.opacity(0.16)))
                        
                    case .web(let url):
                        if url.host?.contains("search.brave.com") == true && !viewModel.inputURLString.hasPrefix("http") && !viewModel.inputURLString.contains(".") {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: viewModel.inputURLString.hasPrefix("https://") ? "lock.fill" : "globe")
                                .font(.system(size: 11))
                                .foregroundColor(viewModel.profileManager.activeProfile.isPrivate ? .orange : .secondary)
                        }
                    }
                }
                .animation(HoloDesign.Animations.springFast, value: viewModel.inputURLString)
                
                TextField("Search or type URL", text: $viewModel.inputURLString)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: isFocused ? .semibold : .medium, design: .default))
                    .focused($isFocused)
                    .onSubmit {
                        if omniboxViewModel.selectedIndex >= 0 {
                            if omniboxViewModel.executeSelected(browserViewModel: viewModel) {
                                isFocused = false
                            }
                        } else {
                            viewModel.submitAddressInput()
                            isFocused = false
                        }
                    }
                    .onExitCommand {
                        if isFocused {
                            cancelEditing()
                        }
                    }
                    .onMoveCommand { direction in
                        switch direction {
                        case .up:
                            omniboxViewModel.moveSelectionUp()
                        case .down:
                            omniboxViewModel.moveSelectionDown()
                        default:
                            break
                        }
                    }
                    .onChange(of: viewModel.inputURLString) { _, newValue in
                        omniboxViewModel.query = newValue
                    }
                    .onChange(of: isFocused) { _, focused in
                        if focused {
                            omniboxViewModel.query = viewModel.inputURLString
                        } else {
                            omniboxViewModel.resetState()
                        }
                    }
                
                if !viewModel.inputURLString.isEmpty && isFocused {
                    Button(action: {
                        cancelEditing()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(
                ZStack {
                    VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                        .clipShape(Capsule())
                    
                    Capsule()
                        .fill(isFocused ? Color.black.opacity(0.12) : Color.black.opacity(0.04))
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        isFocused ? AnyShapeStyle(Color.white.opacity(0.25)) : AnyShapeStyle(HoloTheme.Palette.glassBorderGradient),
                        lineWidth: isFocused ? 1.0 : 0.5
                    )
            )
            .shadow(
                color: isFocused ? Color.black.opacity(0.20) : Color.black.opacity(0.04),
                radius: isFocused ? 8 : 3,
                x: 0,
                y: isFocused ? 2 : 1
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(HoloDesign.Animations.springNormal, value: isFocused)
            .onReceive(NotificationCenter.default.publisher(for: .focusAddressBar)) { _ in
                isFocused = true
                viewModel.inputURLString = viewModel.tabManager.activeTab?.url?.absoluteString ?? ""
            }
            
            // Autocomplete Suggestion Dropdown
            if isFocused {
                if !omniboxViewModel.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(omniboxViewModel.suggestions.enumerated()), id: \.element.id) { index, sug in
                            Button(action: {
                                omniboxViewModel.selectedIndex = index
                                let executed = omniboxViewModel.executeSelected(browserViewModel: viewModel)
                                if executed {
                                    isFocused = false
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: sug.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(sug.iconColor)
                                        .frame(width: 22)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sug.title)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        if let subtitle = sug.subtitle {
                                            Text(subtitle)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(omniboxViewModel.selectedIndex == index ? Color.white.opacity(0.12) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { isHovered in
                                if isHovered {
                                    omniboxViewModel.selectedIndex = index
                                }
                            }
                        }
                    }
                    .padding(6)
                    .holoDeepGlass(cornerRadius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(HoloTheme.Palette.glassBorderGradient, lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.top, 4)
                }
            }
        }
    }
    
    private func cancelEditing() {
        if let currentURL = viewModel.tabManager.activeTab?.url?.absoluteString {
            viewModel.inputURLString = currentURL
        } else {
            viewModel.inputURLString = ""
        }
        isFocused = false
    }
}
