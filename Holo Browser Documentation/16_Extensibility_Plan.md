# Holo Browser: System Extensibility & Plugin Plan

> **Document Status**: Complete / Technical Architecture  
> **Target Release**: Holo Browser 1.0 & Version 1.2 Upgrades  

---

## 1. Extension Architecture Overview

Holo Browser supports three tiers of system extensibility:

```
Tier 1: Native Command Registry (Cmd+K Extensions)
Tier 2: UserScript Injection (Custom CSS / DOM Scripts)
Tier 3: WebExtensions API (Chrome & Safari Extensions via WKWebExtensionController)
```

---

## 2. WebExtensions Integration Architecture (macOS 15+)

Beginning in macOS 15.0 Sequoia, WebKit provides native support for browser extensions via `WKWebExtensionController`.

```swift
#if canImport(WebKit) && os(macOS)
@available(macOS 15.0, *)
public final class HoloWebExtensionManager: ObservableObject {
    public let controller = WKWebExtensionController()
    
    public func loadExtension(from folderURL: URL) async throws {
        let extensionContext = try await WKWebExtensionContext(extension: WKWebExtension(url: folderURL))
        try await controller.load(extensionContext)
    }
}
#endif
```

---

## 3. UserScript Injection Pipeline

Custom user scripts and CSS themes can be added to `WKUserContentController` at `atDocumentEnd` or `atDocumentStart` with main frame sandboxing:

```swift
public func injectUserScript(source: String, in webView: WKWebView) {
    let script = WKUserScript(
        source: source,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
    )
    webView.configuration.userContentController.addUserScript(script)
}
```
