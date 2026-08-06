# Holo Browser — Critical Remediation & Security Action Plan

**Author**: Principal Security Engineer & CTO  
**Target Repository**: Holo Browser (`/Users/jake/Desktop/Holo Browser/HoloBrowser`)  
**Date**: July 30, 2026  

---

## Executive Remediation Strategy

This plan establishes the prioritized engineering fixes required for the confirmed issues identified in `AUDIT_VERIFICATION_REPORT.md`.

---

## 🛠 Prioritized Action Items & Remediation Specifications

### Phase 1: P0 Critical Security & Privacy Fixes

#### Item 1.1: Fix Update Package Signature & Code Validity (`UpdateValidator.swift`)
- **Target File**: `HoloBrowser/Sources/Core/UpdateValidator.swift`
- **Remediation Specification**: Update `validateUpdatePackage` to execute `SecStaticCodeCreateWithPath` and `SecStaticCodeCheckValidity` using Apple Code Signing APIs to verify Developer ID signatures before accepting update packages.
- **Required Regression Test**: `testUpdateValidatorRejectsUnsignedPackages` in `SubsystemUnitTests.swift`.

#### Item 1.2: Fix Download Directory Traversal Vulnerability (`DownloadManager.swift`)
- **Target File**: `HoloBrowser/Sources/Engine/DownloadManager.swift`
- **Remediation Specification**: Sanitize input filename in `download(_:decideDestinationUsing:suggestedFilename:)`:
  `let safeFilename = URL(fileURLWithPath: suggestedFilename).lastPathComponent`
  Verify `destinationURL` remains strictly rooted inside `~/Downloads`.
- **Required Regression Test**: `testDownloadManagerSanitizesPathTraversalFilenames`.

---

### Phase 2: P1 Data Integrity & Recovery Fixes

#### Item 2.1: Implement Serialized File Storage Writes (`HistoryStore.swift`, `BookmarkStore.swift`)
- **Target Files**: `HoloBrowser/Sources/Storage/HistoryStore.swift`, `BookmarkStore.swift`, `SessionManager.swift`
- **Remediation Specification**: Route disk writes through a dedicated background `actor StorageWriter` to enforce strict FIFO serial execution.

#### Item 2.2: Quarantine Corrupted Session & History Files (`RecoveryManager.swift`)
- **Target File**: `HoloBrowser/Sources/Core/RecoveryManager.swift`
- **Remediation Specification**: Update `resetCorruptedSessionData()` to move existing `session.json` and `history.json` files into `/CorruptedSessions/` archive directory and reset active data stores upon safe mode activation.
- **Required Regression Test**: `testRecoveryManagerQuarantinesCorruptedFiles`.

---

### Phase 3: P2 UI Reachability & Access Fixes

#### Item 3.1: Enable Settings Window & Shortcut Routing (`ContentView.swift`)
- **Target File**: `HoloBrowser/Sources/UI/Window/ContentView.swift`, `NavigationToolbarView.swift`
- **Remediation Specification**: Connect gear button in toolbar and `Cmd+,` keyboard shortcut handler to toggle `showSettingsSheet = true`.

#### Item 3.2: Wire PasswordSettingsView into Preferences Window (`SettingsView.swift`)
- **Target File**: `HoloBrowser/Sources/UI/Settings/SettingsView.swift`
- **Remediation Specification**: Replace static placeholder under `case .passwords:` with `PasswordSettingsView(passwordManager: passwordManager)`.
