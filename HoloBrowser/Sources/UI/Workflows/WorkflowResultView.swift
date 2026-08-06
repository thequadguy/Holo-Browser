import SwiftUI

/// Formatted result card rendering summary text, extracted sources, and markdown output.
public struct WorkflowResultView: View {
    let result: WorkflowResult
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Workflow Completed Successfully")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Result Summary:")
                        .font(.system(size: 11, weight: .bold))
                    
                    Text(result.summary)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                    
                    if !result.comparisonTable.isEmpty {
                        Text("Source Quality Matrix:")
                            .font(.system(size: 11, weight: .bold))
                        
                        ForEach(Array(result.comparisonTable.keys), id: \.self) { key in
                            HStack {
                                Text(key).font(.caption).bold()
                                Spacer()
                                Text(result.comparisonTable[key] ?? "").font(.caption).foregroundColor(.secondary)
                            }
                            .padding(4)
                        }
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)))
    }
}
