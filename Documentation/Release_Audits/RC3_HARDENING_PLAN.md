# Holo Browser — RC3 Hardening Plan & Technical Roadmap

## Executive Summary
Following the **RC2 Founder Private Beta Audit**, all 12 confirmed P0/P1/P2 issues have been remediated in executable Swift code, build configurations, and app bundle packaging. This RC3 Hardening Plan outlines remaining lower-priority technical items, UX enhancements, and future architecture goals for post-beta execution.

---

## 1. Confirmed Issues & Priority Matrix

| ID | Category | Priority | Issue Summary | Status | Resolution / Action Item |
|---|---|---|---|---|---|
| SEC-01 | Security | **P0** | Code Signature Validation Bypass | **FIXED** | Replaced extension-only check with `SecStaticCodeCheckValidity` in `UpdateValidator.swift`. |
| SEC-02 | Security | **P0** | Download Path Traversal Vulnerability | **FIXED** | Stripped `..` tokens and validated `~/Downloads/` path prefix containment in `DownloadManager.swift`. |
| SEC-03 | Security | **P0** | Private Browsing History Leakage | **FIXED** | Added `isPrivate: Bool` guard in `HistoryStore.swift` to drop private history entries. |
| SEC-04 | Security | **P0** | AI Context Sanitization Bypass | **FIXED** | Applied `sanitizeContextForAI` to `userQuery` and `selectionText` in `AIContextBuilder.swift`. |
| CFG-01 | Configuration | **P1** | Bundle Identifier Mismatch | **FIXED** | Updated `BuildConfiguration.bundleIdentifier` to `com.holobrowser.app`. |
| REC-01 | Reliability | **P1** | Crash Loop Recovery Unwired | **FIXED** | Wired `registerAppLaunch()` and 10s `registerStableExecution()` in `AppDelegate.swift`. |
| ONB-01 | UX / Onboarding | **P1** | First Launch Welcome Screen Hidden | **FIXED** | Wired `@AppStorage("hasCompletedOnboarding")` to auto-trigger `WelcomeView` sheet on initial launch. |
| TAB-01 | Isolation | **P1** | Tab Bar '+' Button Cross-Profile Leak | **FIXED** | Updated `TabBarView` '+' button to invoke `viewModel.createNewTab()`, binding active profile's `WKWebsiteDataStore`. |
| UI-01 | UX | **P2** | Native Menu Bar & About Panel Missing | **FIXED** | Added native SwiftUI `.commands` for About, Help, and Feedback in `HoloBrowserApp.swift` and `AboutHoloBrowserView.swift`. |
| FDB-01 | Support | **P2** | In-App Beta Feedback Form Inaccessible | **FIXED** | Created `FeedbackSheetView.swift` and connected to Help menu (`⌘⇧?`) and Settings. |

---

## 2. RC3 Target Milestones & Backlog

### P0 Security (Zero-Tolerance)
- [x] Apple Code Signature verification via `Security.framework`
- [x] Path traversal sanitization in Download Engine
- [x] Isolated private browsing history & AI context scrubbing
- [ ] *RC3 Target*: Implement Gatekeeper Notarization Ticket Stapling validation script in CI/CD pipeline.

### P1 Stability & Crash Resilience
- [x] Actor-isolated FIFO storage queue (`DiskStorageActor`)
- [x] Session crash recovery quarantine (`CorruptedSessions/`)
- [x] Application launch & 10s stability registration loop
- [ ] *RC3 Target*: WebKit Process Termination handler to auto-reload terminated web view content processes without losing tab state.

### P2 User Experience & Accessibility
- [x] Interactive 3-Step Onboarding Flow (Welcome -> Import -> Default Browser)
- [x] Native macOS About Window with versioning and copyright metadata
- [x] In-app Feedback & Privacy-Sanitized Diagnostics Exporter
- [ ] *RC3 Target*: Native Find-in-Page bar (`⌘F`) integration for WKWebView.
- [ ] *RC3 Target*: Tab drag-and-drop reordering within `TabBarView`.

### P3 Nice-to-Have Features (v1.1)
- [ ] Local MLX / Apple Silicon On-Device AI Provider option.
- [ ] Manifest V3 WebExtension full content-script injection runtime.
- [ ] Multi-window workspace session sync.

---

## 3. Verification & Compliance Criteria
1. **Compilation**: `xcrun --sdk macosx swift build -c release` must pass with **0 Errors, 0 Warnings**.
2. **Runtime Memory**: Resident set size under 150MB with 10 tabs active.
3. **Concurrency**: Strict Swift 6 Data Isolation compliance across `@MainActor` and `DiskStorageActor`.
