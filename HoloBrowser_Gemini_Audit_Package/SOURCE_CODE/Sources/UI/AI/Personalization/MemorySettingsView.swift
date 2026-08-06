import SwiftUI

/// Inspection UI rendering stored personal memory items with individual & bulk deletion.
public struct MemorySettingsView: View {
    @ObservedObject var intelligenceManager: BrowserIntelligenceManager
    let profileID: UUID
    
    public init(intelligenceManager: BrowserIntelligenceManager, profileID: UUID) {
        self.intelligenceManager = intelligenceManager
        self.profileID = profileID
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("AI Personalization Memory")
                        .font(.headline)
                }
                Spacer()
                Button("Clear All Memories") {
                    intelligenceManager.clearAll(for: profileID)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Text("Review and control what Holo AI remembers about your preferences:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            let list = intelligenceManager.memories(for: profileID)
            
            if list.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "brain")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No personalized memories stored")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(list) { mem in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(mem.category.rawValue)
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color.purple.opacity(0.12)))
                                            .foregroundColor(.purple)
                                        Spacer()
                                        Text(mem.dateCreated.formatted(date: .numeric, time: .shortened))
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }
                                    Text(mem.content)
                                        .font(.system(size: 11))
                                }
                                
                                Button(action: {
                                    intelligenceManager.deleteMemory(id: mem.id)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                        }
                    }
                }
                .frame(minHeight: 180, maxHeight: 300)
            }
        }
        .padding(14)
        .frame(width: 440)
    }
}
