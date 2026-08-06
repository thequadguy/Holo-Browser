# Holo Browser — Privacy Policy (Draft)

**Effective Date**: July 30, 2026  

Holo Browser Inc ("Holo Browser", "we", "us") respects your privacy. This Privacy Policy details how data is handled by the Holo Browser application for macOS.

## 1. Zero Tracking Telemetry
Holo Browser does NOT track, collect, sell, or transmit your browsing history, bookmarks, open tabs, or search queries to our servers or third parties.

## 2. Local Sandboxed Storage
All browser history, saved bookmarks, session snapshots, and user preferences are stored locally on your device in your Mac's sandboxed application support directory (`~/Library/Application Support/HoloBrowser/`).

## 3. Apple Keychain Security
Saved website passwords and third-party AI provider API keys are stored exclusively in Apple Keychain using `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. Credentials cannot be accessed off-device or synced to cloud servers.

## 4. AI Data Sanitization & Cloud Dispatches
When you interact with AI features:
- Text is sanitized locally via regular expressions to strip passwords, auth headers, JWTs, API keys, private keys, and credit card numbers before dispatch.
- In Private Browsing mode, external cloud AI dispatches (OpenAI / Anthropic) are strictly blocked by default. Local on-device AI models operate entirely offline.

## 5. Contact Us
For questions regarding this privacy policy, contact `privacy@holobrowser.com`.
