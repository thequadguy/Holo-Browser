# Holo Browser RC6 — Product Priority Matrix & Roadmap

**Strategic Principle:** Build ONLY features that directly increase 7-day retention and user trust. Avoid building low-value or high-bloat features.

---

## 1. Feature Priority Categorization Matrix

| Feature / Initiative | Category | Retention Rationale | Target Release |
|---|---|---|---|
| **Apple Developer ID & Notarization** | **MUST BUILD BEFORE PUBLIC BETA** | Eliminates macOS Gatekeeper warning dialog on initial download. Critical for trust. | **RC7 / v1.0 Launch** |
| **Tab Drag & Drop Reordering** | **MUST BUILD BEFORE PUBLIC BETA** | Core tab interaction expected by 100% of browser users. | **RC7 / v1.0 Launch** |
| **Native Find-in-Page (`⌘F`) Bar** | **MUST BUILD BEFORE PUBLIC BETA** | Essential in-page text search expected during daily web reading. | **RC7 / v1.0 Launch** |
| **Configurable Download Directory** | **MUST BUILD BEFORE PUBLIC BETA** | Allows power users to choose custom download folder destination in Settings. | **RC7 / v1.0 Launch** |
| **End-to-End Encrypted iCloud Sync** | **SHOULD BUILD LATER** | Syncs bookmarks, history, and workspace notes across Macs securely. | **v1.1** |
| **Local MLX On-Device AI Provider** | **SHOULD BUILD LATER** | Provides 100% offline local LLM execution on Apple Silicon M-series chips. | **v1.1** |
| **Chrome WebExtension MV3 Runtime** | **SHOULD BUILD LATER** | Allows installing extensions from Chrome Web Store. Complex engineering effort. | **v1.2** |
| **Mobile Companion (iOS / iPadOS)** | **SHOULD BUILD LATER** | Extends Holo Browser to iPhone and iPad. | **v1.5** |
| **Vertical Tab Sidebar** | **SHOULD BUILD LATER** | Alternate vertical tab layout option for wide monitors. | **v1.2** |
| **Built-in Crypto Wallet / Web3** | **AVOID BUILDING** | Unnecessary bloat; degrades performance and user trust. | **NEVER** |
| **Third-Party Data Analytics Trackers** | **AVOID BUILDING** | Violates Holo's core privacy guarantee. | **NEVER** |
| **Intrusive Sponsored News Feeds** | **AVOID BUILDING** | Degrades user experience; violates Liquid Glass design principles. | **NEVER** |

---

## 2. Next Sprint Focus (RC7 Target)

1. Implement Apple Developer ID signing & notarization ticket stapling.
2. Implement native SwiftUI tab drag-and-drop reordering.
3. Implement native `WKWebView` find-in-page (`⌘F`) search bar.
