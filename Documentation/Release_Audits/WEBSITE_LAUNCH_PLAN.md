# Holo Browser — Public Launch Website Specification & Plan

**Author**: Head of Product & DevRel Lead  
**Date**: July 30, 2026  
**Target URL**: `https://holobrowser.com`  

---

## 1. Homepage Architecture & Copy Specification

### Section 1: Hero Section
- **Headline**: "The Native Mac Browser Built for Speed, Privacy, and AI."
- **Subheadline**: "Experience Arc's modern workflow with Safari's battery life and uncompromising data privacy. Built with SwiftUI and WebKit."
- **Call-to-Action Buttons**:
  - Primary: `[ Download Public Beta for Mac (Universal) ]`
  - Secondary: `[ View Source on GitHub ]`
- **Sub-hero Badge**: "macOS 14+ | Apple Silicon & Intel | Apple Notarized & Gatekeeper Safe"

### Section 2: Product Explanation & Visual Mockups
- **Visual Asset 1**: Interactive 3D app screenshot demonstrating the Spotlight-style `Cmd + K` Command Palette and glassmorphic UI.
- **Visual Asset 2**: Split-screen demo showing Work and Personal profile isolation with custom color badges.
- **Visual Asset 3**: Privacy Shield animation showing regex redaction of JWTs, passwords, and API keys before sending context to AI providers.

### Section 3: Core Features Matrix
- **⚡️ Native Swift Performance**: Sub-0.5s cold startup, ultra-low RAM footprint, and maximum battery efficiency on Apple Silicon.
- **🔒 Strict Profile Isolation**: Work, Personal, and Private profiles utilize independent `WKWebsiteDataStore` containers.
- **🛡 Mandatory AI Privacy**: Automatic regex context scrubbing removes credentials, tokens, and credit cards before AI dispatch.
- **🔑 Apple Keychain Security**: Credentials and API keys store strictly in Apple Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- **💜 Private Browsing AI Shield**: External cloud AI requests are strictly blocked in Private Browsing mode by default.

### Section 4: Credible Performance & Privacy Promise
> "We believe browsers should serve users, not ad networks. Holo Browser contains zero tracking telemetry, zero analytics beacons, and zero cloud history sync. Your data never leaves your Mac."

### Section 5: Frequently Asked Questions (FAQ)
1. **Is Holo Browser built on Chromium or Electron?**  
   No. Holo Browser is built 100% natively for macOS using Apple's SwiftUI and WebKit frameworks.
2. **How does Holo Browser protect my AI queries?**  
   Holo Browser runs all webpage context through a local regex privacy pipeline that scrubs passwords, API keys, JWTs, and credit card numbers before queries leave your device.
3. **Is Holo Browser free?**  
   Yes, the Public Beta is free to download and use on macOS.
