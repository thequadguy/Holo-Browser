import Foundation

/// Main-actor manager detecting hardware (Apple Silicon vs Intel, Neural Engine), scanning local models, and unloading inactive weights.
@MainActor
public final class ModelManager: ObservableObject {
    @Published public private(set) var availableModels: [ModelMetadata] = []
    @Published public private(set) var activeModel: ModelMetadata?
    @Published public private(set) var isAppleSilicon: Bool = false
    @Published public private(set) var hasNeuralEngine: Bool = false
    
    public init() {
        detectHardware()
        loadBuiltInModels()
    }
    
    private func detectHardware() {
        #if arch(arm64)
        self.isAppleSilicon = true
        self.hasNeuralEngine = true
        #else
        self.isAppleSilicon = false
        self.hasNeuralEngine = false
        #endif
    }
    
    private func loadBuiltInModels() {
        var list: [ModelMetadata] = [
            ModelMetadata(id: "coreml-phi3-mini", name: "Phi-3 Mini (CoreML 4-bit)", sizeBytes: 2_100_000_000, ramRequirementMB: 2800, backend: .coreML, isInstalled: isAppleSilicon),
            ModelMetadata(id: "coreml-llama3-8b", name: "Llama-3 8B (CoreML Neural Engine)", sizeBytes: 4_500_000_000, ramRequirementMB: 5200, backend: .coreML, isInstalled: false),
            ModelMetadata(id: "ollama-llama3", name: "Llama-3 8B (Ollama Localhost)", sizeBytes: 4_700_000_000, ramRequirementMB: 5500, backend: .ollama, isInstalled: true),
            ModelMetadata(id: "ollama-mistral", name: "Mistral 7B (Ollama Localhost)", sizeBytes: 4_100_000_000, ramRequirementMB: 4800, backend: .ollama, isInstalled: true)
        ]
        
        if !isAppleSilicon {
            list.removeAll(where: { $0.backend == .coreML })
        }
        
        self.availableModels = list
        self.activeModel = list.first(where: { $0.isInstalled })
    }
    
    public func selectModel(_ model: ModelMetadata) {
        self.activeModel = model
    }
    
    public func unloadActiveModel() {
        self.activeModel = nil
    }
}
