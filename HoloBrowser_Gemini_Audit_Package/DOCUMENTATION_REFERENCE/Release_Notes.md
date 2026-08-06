# Holo Browser 1.0 RC1 — Public Beta Release Notes

**Version**: 1.0.0 (Build 100)  
**Release Date**: July 30, 2026  
**Target OS**: macOS 14.0 (Sonoma) & macOS 15.0 (Sequoia)  

---

## 🚀 Key Features & Highlights

- **Native SwiftUI & WebKit Architecture**: Built from the ground up for macOS using Apple's high-performance SwiftUI and WebKit engines.
- **Strict Profile Isolation**: Work, Personal, and Custom browser profiles maintain strictly isolated `WKWebsiteDataStore` containers for cookies, sessions, and cache.
- **Non-Persistent Private Browsing**: Private windows utilize non-persistent storage engines that flush memory immediately upon tab closure.
- **Mandatory AI Privacy Pipeline**: Context-aware AI assistance features scrub passwords, bearer tokens, JWTs, credit card numbers, and API keys before sending queries off-device.
- **Private Mode AI Shield**: Cloud AI queries are strictly blocked during Private Browsing mode by default while permitting local AI execution.
- **Apple Keychain Integration**: Passwords and API keys are stored exclusively in Apple Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` protection.
- **WebKit Process Crash Circuit Breaker**: 3-stage automatic process crash recovery prevents infinite crash loops.

---

## 🛠 Fixes & Improvements in RC1

- Enforced 30-second timed reveal lifecycles and instant `.onDisappear` memory zeroing for saved passwords.
- Offloaded disk serialization across all 18 storage components to background utility queues (`Task.detached(priority: .utility)`).
- Implemented `BrowserEnvironment` composition root for clean dependency injection.
- Added Spotlight-style Cmd+K Command Palette (`CommandPaletteView.swift`).
