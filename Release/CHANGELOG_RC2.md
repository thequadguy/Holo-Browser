# Holo Browser 1.0 RC2 — Changelog

---

## 🛡️ Security Hardening (RC2)

- **Apple Code Signature Verification**: `UpdateValidator.swift` now uses `SecStaticCodeCheckValidity` to verify Developer ID signatures and bundle ID `com.holobrowser.app`.
- **Download Path Traversal Shield**: `DownloadManager.swift` enforces strict destination bounds inside `~/Downloads/`.
- **Private Browsing History Guard**: Explicit `isPrivate: Bool` guard prevents private URLs from touching disk storage.

---

## ⚡ Performance & Reliability (RC2)

- **Unified Serial Disk Storage**: Created `DiskStorageActor` to enforce FIFO atomic writes and safe decodable reads across all data stores.
- **Corrupted Session Quarantine**: `RecoveryManager.swift` archives corrupted files to `CorruptedSessions/` with timestamped naming.

---

## 🎨 User Experience & Access (RC2)

- **Preferences & Password Management**: Native macOS `Preferences...` menu item (`Cmd+,`) opens `SettingsView` with active `PasswordSettingsView` access.
- **Interactive Multi-step Onboarding**: Guided 3-step first launch modal for bookmark imports and default browser setup.
