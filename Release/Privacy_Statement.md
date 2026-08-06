# Holo Browser — Privacy Statement

At Holo Browser, privacy is a fundamental architecture requirement, not a feature flag.

- **Zero Analytics Tracking**: Holo Browser contains no telemetry beacons, tracking pixels, or user behavior analytics.
- **Local Data Ownership**: History, bookmarks, passwords, and sessions remain strictly on your Mac under local sandboxed storage.
- **Device-Only Keychains**: Passwords and API keys use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` to prevent iCloud cloud exposure.
- **Mandatory AI Redaction**: AI queries scrub passwords, tokens, API keys, JWTs, and credit card numbers prior to transmission.
- **Private Browsing Isolation**: Private browsing tabs use non-persistent storage and strictly block cloud AI dispatches by default.
