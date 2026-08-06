import SwiftUI

/// Settings view for switching local providers (CoreML / Ollama).
public struct LocalAISettingsView: View {
    @ObservedObject var modelManager: ModelManager
    @ObservedObject var privateAIManager: PrivateAIManager
    
    public init(modelManager: ModelManager, privateAIManager: PrivateAIManager) {
        self.modelManager = modelManager
        self.privateAIManager = privateAIManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cpu.fill")
                        .foregroundColor(.green)
                    Text("Local AI & Private Runtime")
                        .font(.headline)
                }
                Spacer()
            }
            
            Divider()
            
            Toggle("Enforce Zero-Network Local AI Only Mode", isOn: $privateAIManager.isOfflineOnlyMode)
                .font(.system(size: 12, weight: .semibold))
            
            Text("When enabled, all AI requests run 100% on-device on Apple Silicon or Ollama localhost with zero external network transmission.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Detected Hardware:").font(.caption).bold()
                HStack(spacing: 12) {
                    Label(modelManager.isAppleSilicon ? "Apple Silicon (ARM64)" : "Intel x86_64", systemImage: modelManager.isAppleSilicon ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(modelManager.isAppleSilicon ? .green : .orange)
                        .font(.caption)
                    
                    Label(modelManager.hasNeuralEngine ? "Neural Engine Available" : "Software Fallback", systemImage: modelManager.hasNeuralEngine ? "checkmark.circle.fill" : "info.circle")
                        .foregroundColor(modelManager.hasNeuralEngine ? .green : .secondary)
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }
}
