import SwiftUI
import Combine

public extension Notification.Name {
    static let focusAddressBar = Notification.Name("focusAddressBar")
}

/// Address bar supporting Cmd+L focus, inline history/bookmark autocomplete suggestions, Escape clear, and Return navigation.
public struct AddressBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @FocusState private var isFocused: Bool
    
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var bookmarkStore = BookmarkStore()
    
    public init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                TextField("Enter URL or search...", text: $viewModel.inputURLString)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .regular))
                    .focused($isFocused)
                    .onSubmit {
                        viewModel.submitAddressInput()
                    }
                
                if !viewModel.inputURLString.isEmpty && isFocused {
                    Button(action: {
                        viewModel.inputURLString = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .holoClearGlass(cornerRadius: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? HoloTheme.Palette.holoCyan.opacity(0.8) : Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: isFocused ? HoloTheme.Glow.cyan : Color.clear, radius: isFocused ? 12 : 0)
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
                                        .foregroundColor(.secondary)
                                    Text(sug)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color(NSColor.controlBackgroundColor)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.windowBackgroundColor)).shadow(radius: 3))
                    .frame(width: 320)
                    .offset(y: 4)
                }
            }
        }
    }
    
    private func getSuggestions(query: String) -> [String] {
        let trimmed = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        var matches: [String] = []
        for item in historyStore.historyItems {
            if item.urlString.lowercased().contains(trimmed) || item.title.lowercased().contains(trimmed) {
                matches.append(item.urlString)
            }
        }
        for bm in bookmarkStore.bookmarks {
            if bm.urlString.lowercased().contains(trimmed) || bm.title.lowercased().contains(trimmed) {
                matches.append(bm.urlString)
            }
        }
        return Array(Set(matches))
    }
}
