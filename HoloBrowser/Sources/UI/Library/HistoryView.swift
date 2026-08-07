import SwiftUI

/// Native macOS history view with search, date grouping (Today, Yesterday, Previous 7 Days, Earlier), and item deletion.
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
                    VStack(alignment: .leading, spacing: 12) {
                        let grouped = groupItemsByDate(filtered)
                        
                        ForEach(grouped, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                    .padding(.top, 4)
                                
                                ForEach(section.items) { entry in
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
                    }
                }
                .frame(minHeight: 200, maxHeight: 320)
            }
        }
        .padding(14)
        .frame(width: 440)
    }
    
    private struct HistorySection {
        let title: String
        let items: [HistoryItem]
    }
    
    private func groupItemsByDate(_ items: [HistoryItem]) -> [HistorySection] {
        let calendar = Calendar.current
        let now = Date()
        
        var today: [HistoryItem] = []
        var yesterday: [HistoryItem] = []
        var last7Days: [HistoryItem] = []
        var earlier: [HistoryItem] = []
        
        for item in items {
            if calendar.isDateInToday(item.timestamp) {
                today.append(item)
            } else if calendar.isDateInYesterday(item.timestamp) {
                yesterday.append(item)
            } else if let daysAgo = calendar.dateComponents([.day], from: item.timestamp, to: now).day, daysAgo <= 7 {
                last7Days.append(item)
            } else {
                earlier.append(item)
            }
        }
        
        var result: [HistorySection] = []
        if !today.isEmpty { result.append(HistorySection(title: "Today", items: today)) }
        if !yesterday.isEmpty { result.append(HistorySection(title: "Yesterday", items: yesterday)) }
        if !last7Days.isEmpty { result.append(HistorySection(title: "Previous 7 Days", items: last7Days)) }
        if !earlier.isEmpty { result.append(HistorySection(title: "Earlier", items: earlier)) }
        
        return result
    }
}
