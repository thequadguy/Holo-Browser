# Holo Browser 1.0 — Default Browser Experience & First Run V2 Plan

**Author**: Product Lead & UX Researcher  
**Date**: July 30, 2026  

---

## 1. Default Browser Onboarding Flow (`WelcomeView.swift`)

1. **Default Browser Button**: 1-click button calling `NSWorkspace.shared.setDefaultApplicationAtURL` to register Holo Browser as default HTTP/HTTPS handler.
2. **Safari & Chrome Bookmark Migration**: Integrated 1-click import using `BrowserImportManager.swift`.
3. **Keychain Password Sync Guidance**: Clear instructions explaining how to export/import passwords securely into Apple Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
4. **Keyboard Shortcut Discovery**: Interactive card highlighting Spotlight `Cmd + K`, `Cmd + Shift + P` profile switching, and `Cmd + T`.
