# Holo Browser — Extension Ecosystem & Compatibility Strategy

**Author**: Principal macOS Engineer  
**Date**: July 30, 2026  

---

## 1. Extension Architecture & WebExtension Compatibility

- **WebKit WebExtensions Framework**: Leverages Apple's native `WKWebExtension` framework for running Manifest V3 extensions securely.
- **Sandboxed Execution**: Extensions execute inside isolated content script sandboxes with explicit user permission prompts for host access (`ExtensionManager.swift`).
- **Privacy Dashboard Integration**: Extension permission decisions and active content script injections are logged in `PrivacyDashboardView.swift`.
