import SwiftUI

/// Native macOS history view with search, date grouping, and item deletion.
public struct HistoryView: View {
    @ObservedObject var historyStore: HistoryStore
    let onNavigate: (URL) -> Void
    
    @State private var searchQuery: String = ""
    
    public init(historyStore: HistoryStore, onNavigate: @escaping (URL) -> Void) {
        self.historyStore = historyStore
        self.onNavigate = onNavigate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentColor)
                    Text("Browsing History")
                        .font(.headline)
                }
                Spacer()
                Button("Clear History") {
                    historyStore.clearAll()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.red)
            }
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search history...", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
            
            Divider()
            
            let filtered = HistorySearch.search(searchQuery, in: historyStore.historyItems)
            
            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No history entries found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(filtered) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title.isEmpty ? entry.urlString : entry.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1)
                                    Text(entry.urlString)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                            .onTapGesture {
                                if let url = URL(string: entry.urlString) {
                                    onNavigate(url)
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 200, maxHeight: 320)
            }
        }
        .padding(14)
        .frame(width: 440)
    }
}
