# Holo Browser — Engineering Operations & Velocity Guide

**Author**: VP of Engineering  
**Date**: July 30, 2026  

---

## 1. Code Base Conventions & Concurrency Rules

- **Swift 6 Concurrency**: All UI components, managers, and view models must enforce `@MainActor` isolation.
- **Disk I/O Offloading**: All file writing and disk JSON serialization must execute off `@MainActor` via `Task.detached(priority: .utility)`.
- **Zero Plaintext Credentials**: Passwords and API keys must be saved in Security.framework with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- **Code Hygiene**: 0 `fatalError()`, 0 force unwraps (`try!`, `as!`), and 0 warnings allowed in main branch builds.
