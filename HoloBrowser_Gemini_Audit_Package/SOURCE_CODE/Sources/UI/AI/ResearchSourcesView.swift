import SwiftUI

/// View rendering collected research sources for active session with citation generator.
public struct ResearchSourcesView: View {
    @ObservedObject var researchManager: ResearchManager
    
    @State private var selectedStyle: CitationManager.CitationStyle = .mla
    
    public init(researchManager: ResearchManager) {
        self.researchManager = researchManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Citation Format:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $selectedStyle) {
                    ForEach(CitationManager.CitationStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            Divider()
            
            if let session = researchManager.activeSession, !session.sources.isEmpty {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(session.sources) { source in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(source.title)
                                        .font(.system(size: 11, weight: .bold))
                                        .lineLimit(1)
                                    Spacer()
                                    Button(action: {
                                        let citation = CitationManager.formatCitation(for: source, style: selectedStyle)
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(citation, forType: .string)
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 10))
                                    }
                                    .buttonStyle(.plain)
                                    .help("Copy citation")
                                }
                                
                                Text(source.urlString)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Text(source.summary)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No sources added yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
