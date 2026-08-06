# Holo Browser 1.0 — Production Update & Migration Strategy

**Author**: Release Manager & Operations Lead  
**Target Components**: `UpdateManager.swift`, `UpdateValidator.swift`, `MigrationManager.swift`  
**Date**: July 30, 2026  

---

## 1. Release Update Pipeline

- **Sparkle Framework**: Checks HTTPS appcast feed (`https://update.holobrowser.com/appcast.xml`).
- **EdDSA Signature Verification**: Enforced via `UpdateValidator.validateUpdatePackage`.
- **Database & Data Schema Migration**: `MigrationManager.performPendingMigrations` executes sequential data schema updates on startup while preserving profile identities and local Keychain credentials.
- **Rollback Safety**: Previous binary version is backed up atomically before replacing `.app` bundle.
