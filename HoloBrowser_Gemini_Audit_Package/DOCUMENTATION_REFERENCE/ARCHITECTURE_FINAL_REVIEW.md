# Holo Browser 1.0 RC1 — Architecture Final Review

**Date**: July 29, 2026  
**Reviewer**: Lead macOS Architect  
**Scope**: MVVM Architecture, Composition Root, WebKit Lifecycle, Data Store Isolation, and Concurrency  

---

## 1. Composition Root Architecture (`BrowserEnvironment.swift`)

A lightweight composition root was introduced to handle clean dependency instantiation and service injection:

```
BrowserEnvironment
├── TabManager
├── ProfileManager
├── PasswordManager
├── ExtensionManager
├── SessionManager
├── ReadingListManager
├── BookmarkManager
├── AIPrivacyManager
├── AIManager (injecting AIPrivacyManager)
├── PermissionManager
├── ReliabilityManager
└── HistoryStore / BookmarkStore
```

### Architectural Benefits:
- Eliminates ad-hoc service creation across SwiftUI view initializers.
- Maintains strict MVVM separation: `BrowserViewModel` receives pre-configured manager instances without handling singleton instantiations directly.

---

## 2. Profile Data Store Isolation (`TabManager.swift` & `ProfileManager.swift`)

- **Strict Resolution**: Added `TabManager.dataStore(for:profileManager:)` which throws an error if an unknown profile ID is passed.
- **No Default Fallbacks**: Removed silent fallbacks to `WKWebsiteDataStore.default()`. All tab instances must receive an explicit data store matching their originating profile (standard per-profile container or private non-persistent data store).
- **Session Restoration**: Restored tabs look up saved `profileID` and assign the corresponding profile data store, preserving cookie and session boundaries across browser launches.

---

## 3. WebKit Reliability & Process Circuit Breaker (`NavigationManager.swift`)

Implemented a 3-stage circuit breaker in `NavigationManager.webViewWebContentProcessDidTerminate`:

1. **Crash 1**: Immediate reload attempt into a fresh WebContent process.
2. **Crash 2**: 1-second backoff delay followed by reload.
3. **Crash 3+**: Auto-recovery loop terminates to prevent infinite crash spinning; presents user-visible error banner (`"WebContent process crashed repeatedly (3x). Auto-recovery paused. Click reload to try again."`).

---

## 4. Swift 6 Concurrency Compliance

- All UI components, managers, and view models enforce `@MainActor` isolation.
- Off-main-thread I/O operations (JSON persistence, Keychain writes) execute cleanly via `Task.detached(priority: .utility)`.
- Zero data races or un-isolated state mutations across async boundaries.
