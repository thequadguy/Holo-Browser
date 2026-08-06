# Holo Browser — Critical Remediation Implementation Plan

**Author**: Lead macOS Security Engineer & CTO  
**Target Repository**: Holo Browser (`/Users/jake/Desktop/Holo Browser/HoloBrowser`)  
**Date**: July 30, 2026  

---

## Executive Summary

This implementation plan details the code changes required to remediate the 6 confirmed security, data integrity, crash recovery, and UI reachability issues identified in `AUDIT_VERIFICATION_REPORT.md` and `CRITICAL_REMEDIATION_PLAN.md`.

All implementations will be strictly written in Swift 6 under `@MainActor` or actor isolation, maintaining **0 compiler errors and 0 compiler warnings**.

---

## User Review Required

> [!IMPORTANT]
> - **Code Signing Verification**: `UpdateValidator.swift` will validate Developer ID code signatures using Security.framework's `SecStaticCodeCheckValidity`.
> - **Path Traversal Shield**: `DownloadManager.swift` will enforce strict filename sanitization (`URL(fileURLWithPath: suggestedFilename).lastPathComponent`).
> - **Thread-Safe Storage**: A new `actor DiskStorageActor` will serialize all disk writes in FIFO order.
> - **Corrupted Session Quarantine**: `RecoveryManager.swift` will archive and purge corrupted session data upon safe mode trigger.

---

## Proposed Code Changes

### P0 Critical Security Fixes

#### 1. [MODIFY] [UpdateValidator.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/Core/UpdateValidator.swift)
- Implement `SecStaticCodeCreateWithPath` and `SecStaticCodeCheckValidity` to verify code signatures on downloaded DMG/app update packages.

#### 2. [MODIFY] [DownloadManager.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/Engine/DownloadManager.swift)
- Sanitize `suggestedFilename` to `URL(fileURLWithPath: suggestedFilename).lastPathComponent` and strip all `..` directory traversal sequences before determining `destinationURL`.

---

### P1 Data Integrity & Recovery Fixes

#### 3. [NEW] [DiskStorageActor.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/Storage/DiskStorageActor.swift)
- Create thread-safe `actor DiskStorageActor` for serializing JSON disk writes off `@MainActor`.

#### 4. [MODIFY] [HistoryStore.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/Storage/HistoryStore.swift), [BookmarkStore.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/Storage/BookmarkStore.swift), [SessionManager.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/Sessions/SessionManager.swift)
- Migrate background disk save operations to invoke `DiskStorageActor.shared.write(...)`.

#### 5. [MODIFY] [RecoveryManager.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/Core/RecoveryManager.swift)
- Update `resetCorruptedSessionData()` to move existing `session.json` and `history.json` files to `/CorruptedSessions/` archive directory and reset in-memory arrays.

---

### P2 UI Reachability & Settings Fixes

#### 6. [MODIFY] [NavigationToolbarView.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/UI/Chrome/NavigationToolbarView.swift), [ContentView.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/UI/Window/ContentView.swift)
- Add gear icon button in toolbar and `Cmd+,` keyboard shortcut handler to set `showSettingsSheet = true`.

#### 7. [MODIFY] [SettingsView.swift](file:///Users/jake/Desktop/Holo%20Browser/HoloBrowser/Sources/UI/Settings/SettingsView.swift)
- Replace static placeholder under `case .passwords:` with `PasswordSettingsView(passwordManager: passwordManager)`.

---

## Verification Plan

### Automated Regression Tests
Run `swift test -Xswiftc -sdk -Xswiftc $(xcrun --show-sdk-path)` covering:
1. `testUpdateValidatorRejectsUnsignedPackages`
2. `testDownloadManagerSanitizesPathTraversalFilenames`
3. `testDiskStorageActorSerialWrites`
4. `testRecoveryManagerQuarantinesCorruptedFiles`

### Manual Verification
1. Verify `swift build` compiles cleanly with 0 Errors and 0 Warnings.
