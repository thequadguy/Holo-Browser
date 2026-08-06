import SwiftUI

/// Model manager view rendering installed local models, RAM requirements, import controls, and deletion options.
public struct ModelLibraryView: View {
    @ObservedObject var modelManager: ModelManager
    
    public init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundColor(.accentColor)
                    Text("Local Model Library")
                        .font(.headline)
                }
                Spacer()
            }
            
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(modelManager.availableModels) { model in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(.system(size: 12, weight: .bold))
                                HStack(spacing: 8) {
                                    Text(model.backend.rawValue)
                                        .font(.system(size: 9))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.blue.opacity(0.12)))
                                        .foregroundColor(.blue)
                                    
                                    Text("\(model.ramRequirementMB) MB RAM")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            
                            if model.isInstalled {
                                if modelManager.activeModel?.id == model.id {
                                    Text("Active")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.green)
                                } else {
                                    Button("Select") {
                                        modelManager.selectModel(model)
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                            } else {
                                Button("Install") {
                                    // Simulated installation
                                }
                                .buttonStyle(.borderedProminent)
                                .font(.caption)
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                    }
                }
            }
            .frame(minHeight: 180, maxHeight: 280)
        }
        .padding(12)
        .frame(width: 440)
    }
}
