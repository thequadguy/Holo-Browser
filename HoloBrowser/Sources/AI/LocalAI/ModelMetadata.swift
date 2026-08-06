import Foundation

public enum LocalBackendType: String, Codable, CaseIterable {
    case coreML = "Apple CoreML"
    case metal = "Metal Performance Shaders"
    case ollama = "Ollama Localhost"
}

/// Metadata describing a local AI model file and its system hardware requirements.
public struct ModelMetadata: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let sizeBytes: Int64
    public let ramRequirementMB: Int
    public let backend: LocalBackendType
    public var isInstalled: Bool
    
    public init(
        id: String,
        name: String,
        sizeBytes: Int64,
        ramRequirementMB: Int,
        backend: LocalBackendType,
        isInstalled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sizeBytes = sizeBytes
        self.ramRequirementMB = ramRequirementMB
        self.backend = backend
        self.isInstalled = isInstalled
    }
}
