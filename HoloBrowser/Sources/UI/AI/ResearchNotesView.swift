import SwiftUI

/// View displaying research notes and markdown editor for active session.
public struct ResearchNotesView: View {
    @ObservedObject var researchManager: ResearchManager
    let isPrivate: Bool
    
    @State private var newNoteTitle: String = ""
    @State private var newNoteContent: String = ""
    
    public init(researchManager: ResearchManager, isPrivate: Bool) {
        self.researchManager = researchManager
        self.isPrivate = isPrivate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let session = researchManager.activeSession {
                VStack(spacing: 6) {
                    TextField("Note Title...", text: $newNoteTitle)
                        .textFieldStyle(.roundedBorder)
                    TextEditor(text: $newNoteContent)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(height: 70)
                        .border(Color.secondary.opacity(0.3))
                    
                    HStack {
                        Spacer()
                        Button("Add Note") {
                            guard !newNoteContent.isEmpty else { return }
                            researchManager.addNoteToActiveSession(
                                title: newNoteTitle.isEmpty ? "Untitled Note" : newNoteTitle,
                                content: newNoteContent,
                                isAIGenerated: false,
                                isPrivate: isPrivate
                            )
                            newNoteTitle = ""
                            newNoteContent = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                    }
                }
                .padding(8)
                
                Divider()
                
                if !session.notes.isEmpty {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(session.notes) { note in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(note.title)
                                            .font(.system(size: 11, weight: .bold))
                                        Spacer()
                                        if note.isAIGenerated {
                                            Text("AI")
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 4)
                                                .background(Capsule().fill(Color.purple.opacity(0.15)))
                                                .foregroundColor(.purple)
                                        }
                                    }
                                    Text(note.content)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                } else {
                    VStack(spacing: 4) {
                        Spacer()
                        Text("No notes saved").font(.caption).foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack {
                    Spacer()
                    Text("No active research session").font(.caption).foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
