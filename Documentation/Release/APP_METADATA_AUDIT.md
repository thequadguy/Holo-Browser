# Holo Browser 1.0 — Application Metadata & Entitlements Audit Report

**Author**: Lead macOS Release Engineer  
**Date**: July 30, 2026  

---

## 1. App Entitlements Audit (`HoloBrowser.entitlements`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.device.microphone</key>
    <true/>
    <key>com.apple.security.print</key>
    <true/>
</dict>
</plist>
```

- **App Sandbox**: Enforced (`com.apple.security.app-sandbox` = `true`).
- **Network Permissions**: Client (web browsing) & Server (local Ollama AI binding) enabled.
- **Hardware Access**: Camera & Microphone enabled for WebKit media permissions.

---

## 2. Privacy Usage Description Strings

- `NSCameraUsageDescription`: "Holo Browser requires camera access for web applications and video calls."
- `NSMicrophoneUsageDescription`: "Holo Browser requires microphone access for voice input and web calls."

---

## 3. Metadata Verification Summary

- **Bundle Identifier**: `com.holobrowser.app`
- **Category**: `public.app-category.productivity` / `public.app-category.developer-tools`
- **Minimum macOS Version**: `14.0` (Sonoma)
- **Copyright**: `Copyright © 2026 Holo Browser Inc. All rights reserved.`
