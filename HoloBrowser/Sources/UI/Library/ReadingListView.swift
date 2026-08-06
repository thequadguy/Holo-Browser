import SwiftUI

/// Native macOS reading list view displaying saved unread/read articles.
public struct ReadingListView: View {
    @ObservedObject var readingListManager: ReadingListManager
    let activeProfileID: UUID
    let onNavigate: (URL) -> Void
    
    public init(
        readingListManager: ReadingListManager,
        activeProfileID: UUID,
        onNavigate: @escaping (URL) -> Void
    ) {
        self.readingListManager = readingListManager
        self.activeProfileID = activeProfileID
        self.onNavigate = onNavigate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "eyeglasses")
                        .foregroundColor(.accentColor)
                    Text("Reading List")
                        .font(.headline)
                }
                Spacer()
            }
            
            Divider()
            
            let list = readingListManager.items(for: activeProfileID)
            
            if list.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "eyeglasses")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Reading list is empty")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(list) { item in
                            HStack {
                                Image(systemName: item.isRead ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isRead ? .green : .secondary)
                                    .onTapGesture {
                                        readingListManager.toggleReadStatus(id: item.id)
                                    }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 12, weight: item.isRead ? .regular : .bold))
                                        .lineLimit(1)
                                    Text(item.urlString)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    readingListManager.removeItem(id: item.id)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                            .onTapGesture {
                                if let url = URL(string: item.urlString) {
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
        .frame(width: 420)
    }
}
