import SwiftUI

/// Smart Tab Suggestions UI component displaying auto-grouped tab clusters and 1-click actions.
public struct SmartTabSuggestionView: View {
    @ObservedObject private var smartTabManager = SmartTabManager.shared
    @ObservedObject private var smartTabEngine = SmartTabEngine.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.3.layers.3d.down.right")
                    .foregroundColor(.purple)
                Text("Smart Tab Intelligence")
                    .font(.headline)
                Spacer()
                Button("Undo Grouping") {
                    smartTabManager.undoGrouping()
                }
                .font(.caption)
                .disabled(smartTabManager.previousGroupsState.isEmpty)
            }
            
            if smartTabManager.suggestions.isEmpty {
                Text("No tab grouping suggestions. All tabs organized.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(smartTabManager.suggestions) { suggestion in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(suggestion.categoryName)
                                .font(.subheadline)
                                .bold()
                            Text("\(suggestion.tabIDs.count) tabs")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Group") {
                            // Apply tab grouping
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}
