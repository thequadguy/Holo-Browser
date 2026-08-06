# Holo Browser: Release Code Signing & Notarization Guide

---

## 1. Developer ID Application Signing

Production builds of Holo Browser must be signed using an official **Developer ID Application** certificate issued by Apple Developer Program.

### Command Execution:
```bash
codesign --force --options runtime --deep --sign "Developer ID Application: Holo Browser Inc (TEAM_ID)" .build/release/HoloBrowser
```

---

## 2. Hardened Runtime Entitlements

The signed bundle includes `HoloBrowser.entitlements`:
* `com.apple.security.app-sandbox`: Enabled.
* `com.apple.security.network.client`: Enabled (Outbound web requests).
* `com.apple.security.files.user-selected.read-write`: Enabled.
* `com.apple.security.keychain`: Enabled.

---

## 3. Apple Notarization Workflow

Submitting signed distribution archives to Apple's automated notary service:

```bash
xcrun notarytool submit HoloBrowser.dmg --keychain-profile "HoloNotaryProfile" --wait
xcrun stapler staple HoloBrowser.dmg
```

---

## 4. Verification

Confirm Gatekeeper compliance prior to release:

```bash
spctl --assess --type execute --verbose .build/release/HoloBrowser
```
