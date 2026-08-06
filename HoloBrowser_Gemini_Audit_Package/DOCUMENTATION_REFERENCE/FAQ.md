# Holo Browser 1.0 — Frequently Asked Questions (Support)

### Q: Is Holo Browser based on Chromium or Electron?
**A**: No. Holo Browser is built 100% natively for macOS using Apple's SwiftUI and WebKit engines.

### Q: How does Holo Browser protect my AI queries?
**A**: All page context runs through a local regex privacy pipeline that scrubs passwords, API keys, JWTs, and credit card numbers before query dispatch. In Private Browsing mode, cloud AI dispatches are strictly blocked by default.

### Q: Where are my saved passwords stored?
**A**: Passwords are saved exclusively in Apple Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` access protection. They never leave your device.
