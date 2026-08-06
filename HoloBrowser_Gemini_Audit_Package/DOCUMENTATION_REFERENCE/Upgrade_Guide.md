# Holo Browser 1.0 — Auto-Upgrade & Rollback Guide

## Automatic Updates via Sparkle
Holo Browser includes automatic update checking powered by Sparkle framework (`UpdateManager.swift`).

- **Checking for Updates**: Select **Holo Browser > Check for Updates...** from the menu bar.
- **Background Downloads**: Updates download securely over HTTPS with EdDSA signature verification.
- **Rollback Safety**: Previous session history and profile data stores are preserved atomically across version upgrades.
