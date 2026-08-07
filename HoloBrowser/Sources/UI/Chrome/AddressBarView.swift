import SwiftUI
import Combine

public extension Notification.Name {
    static let focusAddressBar = Notification.Name("focusAddressBar")
}

/// 3D Liquid Glass OmniBox Address Bar matching reference image image_0.png.
/// Features a distinct glass capsule bubble with "What are you looking for ?" placeholder, standalone "Search" glass pill button,
/// and vibrant rainbow holographic edge diffraction.
public struct AddressBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @FocusState private var isFocused: Bool
    
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var bookmarkStore = BookmarkStore()
    
    public init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
    }
    
    private var isAIQuery: Bool {
        viewModel.inputURLString.trimmingCharacters(in: .whitespaces).hasPrefix("h ")
    }
    
    private var isMissionQuery: Bool {
        viewModel.inputURLString.trimmingCharacters(in: .whitespaces).hasPrefix("mission ")
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Glass Capsule Bubble Address Field (matching image_0.png)
                HStack(spacing: 8) {
                    // Lock / Privacy Badge
                    if isAIQuery {
                        HStack(spacing: 4) {
                            HoloAssistantPresenceView(state: .listening)
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                            Text("HoloMind AI")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(HoloTheme.Palette.holoCyan)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(HoloTheme.Palette.holoCyan.opacity(0.16)))
                    } else if isMissionQuery {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.horizontal.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(HoloTheme.Palette.holoEmerald)
                            Text("Mission")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(HoloTheme.Palette.holoEmerald)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(HoloTheme.Palette.holoEmerald.opacity(0.16)))
                    } else {
                        Image(systemName: viewModel.inputURLString.hasPrefix("https://") ? "lock.fill" : "shield.checkmark.fill")
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.profileManager.activeProfile.isPrivate ? .orange : HoloTheme.Palette.holoCyan)
                    }
                    
                    TextField("What are you looking for ?", text: $viewModel.inputURLString)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .focused($isFocused)
                        .onSubmit {
                            viewModel.submitAddressInput()
                        }
                        .onExitCommand {
                            cancelEditing()
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
                .padding(.vertical, 7)
                .background(
                    ZStack {
                        VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                            .clipShape(Capsule())
                        
                        Capsule()
                            .fill(isFocused ? Color.white.opacity(0.32) : Color.white.opacity(0.18))
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isFocused ? AnyShapeStyle(HoloTheme.Palette.rainbowIridescentGradient) : AnyShapeStyle(HoloTheme.Palette.glassBorderGradient),
                            lineWidth: isFocused ? 1.5 : 1.0
                        )
                )
                .shadow(
                    color: isFocused ? HoloTheme.Glow.cyan.opacity(0.35) : Color.black.opacity(0.04),
                    radius: isFocused ? 10 : 3,
                    x: 0,
                    y: isFocused ? 2 : 1
                )
                
                // Standalone "Search" Pill Glass Button (matching image_0.png)
                Button(action: {
                    viewModel.submitAddressInput()
                }) {
                    Text("Search")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(
                            ZStack {
                                VisualEffectViewWrapper(material: .popover, blendingMode: .behindWindow)
                                    .clipShape(Capsule())
                                Capsule()
                                    .fill(Color.white.opacity(0.24))
                            }
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(HoloTheme.Palette.rainbowIridescentGradient, lineWidth: 1.2)
                        )
                        .shadow(color: HoloTheme.Glow.cyan.opacity(0.25), radius: 6, y: 1)
                }
                .buttonStyle(.plain)
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusAddressBar)) { _ in
                isFocused = true
            }
            
            // Autocomplete Suggestion Dropdown
            if isFocused && !viewModel.inputURLString.isEmpty {
                let suggestions = getSuggestions(query: viewModel.inputURLString)
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(suggestions.prefix(4), id: \.self) { sug in
                            Button(action: {
                                viewModel.inputURLString = sug
                                viewModel.submitAddressInput()
                                isFocused = false
                            }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption)
                                        .foregroundColor(HoloTheme.Palette.holoCyan)
                                    Text(sug)
                                        .font(.system(size: 11, design: .monospaced))
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.20)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .holoDeepGlass(cornerRadius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(HoloTheme.Palette.rainbowIridescentGradient, lineWidth: 1.0)
                    )
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
    
    private func getSuggestions(query: String) -> [String] {
        let q = query.lowercased()
        var results: [String] = []
        
        for item in historyStore.historyItems {
            if item.title.lowercased().contains(q) || item.urlString.lowercased().contains(q) {
                results.append(item.urlString)
            }
        }
        
        for b in bookmarkStore.bookmarks {
            if b.title.lowercased().contains(q) || b.urlString.lowercased().contains(q) {
                results.append(b.urlString)
            }
        }
        
        return Array(Set(results))
    }
}
