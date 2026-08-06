import SwiftUI

/// Native macOS bookmarks manager view with folder hierarchy.
public struct BookmarksView: View {
    @ObservedObject var bookmarkStore: BookmarkStore
    @ObservedObject var bookmarkManager: BookmarkManager
    let onNavigate: (URL) -> Void
    
    public init(
        bookmarkStore: BookmarkStore,
        bookmarkManager: BookmarkManager,
        onNavigate: @escaping (URL) -> Void
    ) {
        self.bookmarkStore = bookmarkStore
        self.bookmarkManager = bookmarkManager
        self.onNavigate = onNavigate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Bookmarks & Favorites")
                        .font(.headline)
                }
                Spacer()
            }
            
            Divider()
            
            let list = bookmarkStore.bookmarks
            
            if list.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "star")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No bookmarks saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(list) { item in
                            BookmarkItemRowView(item: item, onSelect: {
                                if let url = URL(string: item.urlString) {
                                    onNavigate(url)
                                }
                            }, onDelete: {
                                bookmarkStore.removeBookmark(id: item.id)
                            })
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

private struct BookmarkItemRowView: View {
    let item: BookmarkItem
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(item.urlString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
        .onTapGesture {
            onSelect()
        }
    }
}
