import SwiftUI

/// View rendering smart tab auto-grouping recommendations and duplicate tab detection.
public struct SmartTabsView: View {
    @ObservedObject var smartTabManager: SmartTabManager
    let tabs: [Tab]
    let onCloseTab: (UUID) -> Void
    
    public init(smartTabManager: SmartTabManager, tabs: [Tab], onCloseTab: @escaping (UUID) -> Void) {
        self.smartTabManager = smartTabManager
        self.tabs = tabs
        self.onCloseTab = onCloseTab
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.3.layers.3d.down.right")
                        .foregroundColor(.blue)
                    Text("Smart Tab Intelligence")
                        .font(.headline)
                }
                Spacer()
                Button("Analyze Open Tabs") {
                    smartTabManager.analyzeTabs(tabs)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
            }
            
            Divider()
            
            let duplicates = smartTabManager.findDuplicateTabs(tabs)
            if !duplicates.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Found \(duplicates.count) duplicate tab(s)")
                        .font(.caption)
                        .bold()
                    Spacer()
                    Button("Close Duplicates") {
                        for dup in duplicates {
                            onCloseTab(dup.id)
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.12)))
            }
            
            SmartTabSuggestionView()
        }
        .padding(14)
        .frame(width: 440)
    }
}
