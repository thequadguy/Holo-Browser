import SwiftUI

/// Main research workspace view displaying active session, sources count, notes count, and AI comparison trigger.
public struct ResearchWorkspaceView: View {
    @ObservedObject var researchManager: ResearchManager
    @ObservedObject var aiManager: AIManager
    let isPrivate: Bool
    
    @State private var newTopic: String = ""
    
    public init(researchManager: ResearchManager, aiManager: AIManager, isPrivate: Bool) {
        self.researchManager = researchManager
        self.aiManager = aiManager
        self.isPrivate = isPrivate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isPrivate {
                VStack(spacing: 8) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("Research Workspace Disabled in Private Browsing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let session = researchManager.activeSession {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.title)
                                .font(.system(size: 14, weight: .bold))
                            Text("Topic: \(session.topic)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack(spacing: 10) {
                        VStack {
                            Text("\(session.sources.count)")
                                .font(.headline)
                            Text("Sources").font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                        
                        VStack {
                            Text("\(session.notes.count)")
                                .font(.headline)
                            Text("Notes").font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                    }
                    
                    Divider()
                    
                    // Multi-Source AI Synthesis Trigger
                    Button(action: {
                        triggerMultiSourceAnalysis(session: session)
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("Compare & Analyze All Sources (\(session.sources.count))")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.12)))
                        .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    .disabled(session.sources.isEmpty)
                    
                    // Export Markdown Button
                    Button(action: {
                        copyMarkdownExport(session: session)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Copy Research as Markdown")
                                .font(.system(size: 11))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(10)
            } else {
                VStack(spacing: 10) {
                    Text("No Active Research Session").font(.caption).foregroundColor(.secondary)
                    HStack {
                        TextField("New Topic (e.g. Quantum Computing)...", text: $newTopic)
                            .textFieldStyle(.roundedBorder)
                        Button("Create") {
                            _ = researchManager.createSession(title: newTopic, topic: newTopic, profileID: UUID(), isPrivate: false)
                        }
                    }
                }
                .padding(10)
            }
        }
    }
    
    private func triggerMultiSourceAnalysis(session: ResearchSession) {
        guard !session.sources.isEmpty else { return }
        let combined = session.sources.enumerated().map { (idx, src) in
            "Source \(idx + 1): \(src.title) (\(src.urlString))\nSummary: \(src.summary)"
        }.joined(separator: "\n\n")
        
        aiManager.chat(userText: "Analyze and compare the following research sources:\n\n\(combined)")
    }
    
    private func copyMarkdownExport(session: ResearchSession) {
        let md = researchManager.exportSessionAsMarkdown(session)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(md, forType: .string)
    }
}
