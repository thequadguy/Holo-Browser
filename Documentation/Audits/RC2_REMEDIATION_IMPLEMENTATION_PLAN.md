# Holo Browser — RC2 Remediation & Security Implementation Plan

**Author**: Lead macOS Security Engineer & Senior Swift Architect  
**Date**: August 1, 2026  
**Target Build**: Holo Browser 1.0 RC2  

---

## 1. Executive Summary

This document outlines the execution plan for the **RC2 Security Hardening & Beta Readiness Pass**. The objective is to resolve all confirmed security vulnerabilities, storage concurrency risks, and recovery failures identified in previous audits, transforming Holo Browser into a fully hardened, public-beta-ready macOS application.

---

## 2. Confirmed Issues & Affected Files

| Priority | Issue Description | Target File(s) | Primary Fix Required |
|---|---|---|---|
| **P0** | **Insecure Update Validation** | `HoloBrowser/Sources/Core/UpdateValidator.swift` | Replace filename extension check with `SecStaticCodeCheckValidity` API and bundle identifier matching. |
| **P0** | **Download Path Traversal** | `HoloBrowser/Sources/Engine/DownloadManager.swift` | Strip relative and absolute directory traversal paths (`..`, `/`), enforcing strict destination bounds inside `~/Downloads`. |
| **P1** | **Unserialized Disk I/O** | `HoloBrowser/Sources/Core/Storage/DiskStorageActor.swift` | Create a centralized `DiskStorageActor` to enforce FIFO serialized atomic disk writes across `HistoryStore`, `BookmarkStore`, `SessionManager`, `ProfileManager`, and `MemoryStore`. |
| **P1** | **RecoveryManager Session Quarantine** | `HoloBrowser/Sources/Core/RecoveryManager.swift` | Implement corrupted session quarantine (`CorruptedSessions/session.corrupt.TIMESTAMP.json`) and automated clean state restoration. |
| **P2** | **Settings Menu & Shortcut Access** | `HoloBrowser/Sources/App/AppDelegate.swift`, `ContentView.swift` | Register native macOS `Preferences…` menu item (`Cmd+,`) and wire setting sheet triggers. |
| **P2** | **Password Management UI Access** | `HoloBrowser/Sources/UI/Settings/SettingsView.swift` | Replace static password placeholder with active `PasswordSettingsView`. |

---

## 3. Architecture & Implementation Plan

### Phase 1: P0 Security Hardening
- **Code Signature Verification**:
  - Update `UpdateValidator.swift` using `Security.framework` (`SecStaticCodeCreateWithPath`, `SecStaticCodeCheckValidity`).
  - Validate bundle identifier `com.holobrowser.app` and enforce version comparison to block downgrade attacks.
- **Path Traversal Shield**:
  - Sanitize input filename in `DownloadManager.swift` using `URL(fileURLWithPath: suggestedFilename).lastPathComponent`.
  - Validate that destination canonical path starts with `~/Downloads/`.

### Phase 2: Reliability Architecture
- **Unified Disk Storage Actor**:
  - Create `DiskStorageActor.swift` in `HoloBrowser/Sources/Core/Storage/` (or `HoloBrowser/Sources/Storage/`).
  - Migrate all store `saveAsync()` methods to invoke `DiskStorageActor.shared.write(...)`.
- **Corrupted Session Recovery**:
  - Update `RecoveryManager.swift` to archive corrupted `.json` files under `CorruptedSessions/` using formatted timestamps.

### Phase 3: UX Completion & Access
- **Native macOS Menu Item**:
  - Connect `Cmd+,` and `Preferences...` menu item to toggle `showSettingsSheet = true` in `ContentView.swift`.
- **Password Settings UI**:
  - Instantiate `PasswordSettingsView` under `.passwords` tab in `SettingsView.swift`.

---

## 4. Testing & Verification Strategy

- Run `xcrun --sdk macosx swift build` to verify **0 Errors, 0 Warnings**.
- Run `xcrun --sdk macosx swift test` to verify unit and performance test suites.
- Add new test cases:
  - `testUpdateValidatorRejectsUnsignedAndInvalidBundles`
  - `testDownloadPathTraversalAttacksBlocked`
  - `testDiskStorageActorSerialExecution`
  - `testRecoveryManagerQuarantinesCorruptedFiles`
