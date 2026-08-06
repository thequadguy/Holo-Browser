# Holo Browser: Detailed Feature Specifications (Version 1.0)

> **Document Status**: Complete / Technical Specifications  
> **Target Audience**: Core Engineering & Product Architecture  

---

## 1. Profiles & Workspace Isolation Engine

### Objective
Provide isolated browser profiles (e.g. *Default*, *Work*, *Private / Incognito*) with separate cookie stores, local storage, history indices, and extension configurations.

### Specification & Interfaces
```swift
@MainActor
public final class ProfileManager: ObservableObject {
    @Published public private(set) var activeProfile: BrowserProfile
    
    public func createProfile(name: String, isPrivate: Bool) -> BrowserProfile {
        let dataStore: WKWebsiteDataStore = isPrivate ? .nonPersistent() : .init()
        let profile = BrowserProfile(name: name, dataStore: dataStore, isPrivate: isPrivate)
        return profile
    }
}
```

---

## 2. Keychain Password Manager & Auto-Fill

### Objective
Securely save, query, auto-fill, and generate strong passwords using macOS Apple Keychain Services (`Security.framework`).

### Security Requirements
* Credentials must be encrypted using `kSecAccessControlBiometryAny` or default Keychain protection (`kSecAttrAccessibleWhenUnlocked`).
* Passwords must **never** be passed to AI model providers or logged to telemetry.

---

## 3. WebExtensions API Integration

### Objective
Enable Chrome and Safari web extensions using Apple’s native `WKWebExtensionController` (available on macOS 15+).

### Implementation Path
```swift
#if canImport(WebKit) && os(macOS)
@available(macOS 15.0, *)
public final class ExtensionManager: ObservableObject {
    public let extensionController = WKWebExtensionController()
    
    public func loadExtension(from url: URL) async throws {
        let extensionContext = try await WKWebExtensionContext(extension: WKWebExtension(url: url))
        try await extensionController.load(extensionContext)
    }
}
#endif
```

---

## 4. Multi-Step Autonomous Web Agent (Phase 6)

### Objective
Enable Holo Browser to execute multi-step web workflows (e.g., searching for product prices across 3 sites and building a comparative Markdown table).

### Human-in-the-Loop Safeguards
> [!CAUTION]
> Web Agents are strictly prohibited from submitting payment forms, entering passwords, or executing account deletion requests without explicit human confirmation.

```swift
public struct AgentStep {
    public enum StepType {
        case navigate(URL)
        case clickElement(selector: String)
        case extractData(selector: String)
        case promptUserConfirmation(reason: String)
    }
    public let type: StepType
}
```

---

## 5. Local LLM & Edge Inference (Phase 7)

### Objective
Integrate local model inference engines via Ollama (`http://127.0.0.1:11434`), LM Studio, and Apple Silicon Neural Engine (CoreML).

### Provider Implementation
```swift
public final class OllamaProvider: AIProviderProtocol, @unchecked Sendable {
    public let name: String = "Local Ollama Engine"
    private let baseURL: URL
    
    public init(baseURL: URL = URL(string: "http://127.0.0.1:11434")!) {
        self.baseURL = baseURL
    }
    
    public func sendMessage(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        // Stream text from local Ollama endpoint over native URLSession
        AsyncThrowingStream { continuation in
            // Execution logic
        }
    }
}
```
