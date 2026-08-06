# Holo Browser 1.0 — Auto-Update Architecture Documentation

**Author**: Senior macOS Release Engineer  
**Target Class**: `UpdateManager.swift` (`HoloBrowser/Sources/Core/UpdateManager.swift`)  
**Date**: July 30, 2026  

---

## 1. Sparkle Auto-Update Architecture

`UpdateManager.swift` encapsulates automated updates using the Sparkle update framework on macOS:

- **HTTPS Update Feed**: Connects to `https://update.holobrowser.com/appcast.xml`.
- **EdDSA Signature Verification**: Enforces cryptographic signature checks on downloaded app binaries before mounting.
- **Rollback & Data Safety**: Preserves all local `~/Library/Application Support/HoloBrowser/` profiles, Keychain items, and session snapshots during version replacements.
- **Channel Support**: Supports `.beta` and `.stable` update channels via preference toggles.
