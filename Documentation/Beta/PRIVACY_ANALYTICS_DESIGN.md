# Holo Browser 1.0 — Privacy-First Analytics Design Document

**Author**: Privacy Engineer & Head of Product Analytics  
**Date**: July 30, 2026  

---

## 1. Implementation Architecture (`PrivacyAnalyticsManager.swift`)

- **Opt-In Default**: Disabled by default (`isOptedIn = false`). Requires explicit user toggle in onboarding or settings.
- **Zero PII Guarantee**: Strictly excludes URLs, domain names, browsing history, search terms, AI prompts, passwords, and IP addresses.
- **Payload Structure**:
  ```json
  {
    "event": "CommandPaletteUsed",
    "timestamp": "2026-07-30T02:10:00Z",
    "appVersion": "1.0.0",
    "osVersion": "macOS 15.0",
    "architecture": "arm64 (Apple Silicon)"
  }
  ```
