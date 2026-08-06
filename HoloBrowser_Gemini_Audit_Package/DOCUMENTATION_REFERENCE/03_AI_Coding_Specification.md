# Holo Browser: AI Coding Agent Specification & Directives

> **Target Audience**: AI Coding Agents (Antigravity, Codex, Claude Code, Cursor)  
> **Rule Level**: MANDATORY / STRICT COMPLIANCE  
> **Language & Standard**: Swift 5.10 / Swift 6, Xcode 15/16, macOS 14.0+ SDK  

---

## 1. Core Operating Principles for AI Agents

You are an autonomous AI coding agent tasked with building **Holo Browser**—a native, high-performance macOS browser. You must operate under the following strict rules:

### RULE 1: Build a REAL Browser First
* **NO Fake Functionality**: Never create fake progress bars, static webpage screenshots, mock HTML strings rendered in labels, or simulated back/forward buttons.
* **Real Engine Integration**: Every URL navigation request MUST execute against a real `WKWebView` instance that makes actual network calls over HTTP/HTTPS.

### RULE 2: Zero Superficial Complexity
* Do not introduce massive third-party dependencies (e.g., Alamofire, SwiftyJSON, React Native, CocoaPods). Use native macOS frameworks (`URLSession`, `JSONDecoder`, `Combine`, `SwiftData`).
* Do not write custom HTML rendering engines, CSS parsers, or JavaScript interpreters.

### RULE 3: Strict Modular Architecture
* Keep Views, ViewModels, Core Services, and Engine Wrappers completely isolated.
* Views MUST NOT perform network requests, manage storage transactions, or directly construct `URLRequest` logic.

### RULE 4: Incremental Milestone Execution
* Build and verify one milestone at a time. Never jump ahead to write Phase 4 AI features or Phase 3 glass styling before Phase 1 navigation is 100% functional and verified without crashes.

---

## 2. Swift Coding Standards & Guidelines

### 2.1 Concurrency & Memory Safety
* **Swift Concurrency Only**: Use `async`/`await`, `Actor`, and `@MainActor`. Do NOT use legacy `DispatchQueue.main.async` unless interfacing with legacy AppKit APIs that require it.
* **Strict Memory Management**: Always capture `[weak self]` in closures, delegate callbacks, or Combine subscribers to prevent retain cycles.
* **Main Actor Binding**: All ViewModels and UI state properties MUST be annotated with `@MainActor`.

```swift
// GOOD: Safe concurrency and memory management
@MainActor
public final class BrowserViewModel: ObservableObject {
    @Published public private(set) var currentURL: URL?
    @Published public private(set) var isLoading: Bool = false
    
    private let navigationManager: NavigationManagerProtocol
    
    public init(navigationManager: NavigationManagerProtocol) {
        self.navigationManager = navigationManager
    }
    
    public func navigate(to urlString: String) async {
        guard let url = URLSanitizer.sanitize(urlString) else { return }
        await navigationManager.load(url: url)
    }
}
```

```swift
// BAD: Anti-pattern, thread-unsafe, leak-prone
class BadViewModel {
    var url: String = ""
    
    func load() {
        DispatchQueue.global().async {
            // Unsafe UI update on background thread
            self.url = "https://example.com"
        }
    }
}
```

### 2.2 Modern State Management
* Target macOS 14+ `@Observable` macro where appropriate, or standard `ObservableObject` / `@Published` for backward compatibility within SwiftUI.
* Keep state mutation unidirectional: User Action → ViewModel Method → Engine State → Published UI Update.

---

## 3. Architecture & File Organization Rules

### Folder Structure Integrity
All source files MUST be placed in their exact designated directory within the `HoloBrowser/` project tree (see `05_Project_Folder_Structure.md`).

* **Core Rules**:
  1. `Engine/` folder contains WKWebView configuration and low-level WebKit delegates.
  2. `UI/` folder contains pure SwiftUI components and AppKit window bridge views.
  3. `ViewModels/` contains business logic and observable states.
  4. `Storage/` handles CoreData/SwiftData persistence.

---

## 4. Error Handling Requirements

* **No Swallowed Exceptions**: Never use empty `catch {}` blocks or `try?` on critical system operations.
* **Typed Domain Errors**: Define explicit `Error` enums for Navigation, Storage, and Privacy filtering.
* **User-Facing Graceful Recovery**: Web page crashes, SSL failures, or network drops must present clean, native error state views inside the browser window rather than crashing the host process.

```swift
public enum HoloNavigationError: LocalizedError {
    case invalidURL(String)
    case networkUnreachable
    case sslCertificateUntrusted(String)
    case webProcessCrashed
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let raw):
            return "The address '\(raw)' is invalid. Please check the URL and try again."
        case .networkUnreachable:
            return "No Internet Connection. Please verify your network settings."
        case .sslCertificateUntrusted(let domain):
            return "Security Warning: The connection to \(domain) is not secure."
        case .webProcessCrashed:
            return "The webpage process terminated unexpectedly. Reloading..."
        }
    }
}
```

---

## 5. Performance Thresholds & Requirements

Every build deliverable MUST satisfy these strict performance constraints:

1. **Cold App Startup Time**: Under **500ms** on Apple Silicon (M1/M2/M3/M4) Macs.
2. **Idle Memory Consumption**: Baseline app footprint **< 150MB RAM** with 1 blank/home tab.
3. **UI Frame Rate**: Constant **60fps / 120fps (ProMotion)** during window resizing, toolbar interaction, and tab switching. Zero main-thread blocking operations.
4. **Binary Size**: Release executable bundle **< 25MB** total size.

---

## 6. What NOT to Build Early (Strict Prohibition List)

To preserve focus and ensure a solid engineering foundation, **DO NOT** attempt to build or add the following features during early milestones:

❌ **DO NOT build AI Assistant / LLM Integration** during Phase 1 or Phase 2.  
❌ **DO NOT build custom liquid glass shaders / complex Metal effects** before standard web page navigation works cleanly.  
❌ **DO NOT build workspace switching or multi-profile isolated cookie pools** during initial window setup.  
❌ **DO NOT attempt to support Chromium / WebExtensions API** before native bookmarks and history persistence work.  
❌ **DO NOT build cloud sync or account login services** until the local browser engine is bulletproof.

---

## 7. AI Code Review & Verification Workflow

Before reporting any milestone as complete, the AI coding agent must:

1. **Verify Compilation**: Ensure zero Swift compiler warnings or errors (`swift build` or Xcode build succeeds).
2. **Run Unit Tests**: Execute all XCTest suites (`swift test` or `xcodebuild test`).
3. **Check Resource Leaks**: Confirm WebViews and view controllers are deallocated properly on tab closure.
4. **Self-Document**: Document all added public APIs with standard Swift documentation comments (`///`).
