# HOLO BROWSER — CLOSED BETA LAUNCH CHECKLIST (V1.4)

## 📋 Release Candidate Pre-Flight Matrix

- [x] **Native Swift Build**: 0 compilation errors, 0 warnings (`swift build`).
- [x] **App Sandbox Entitlements**: Validated `HoloBrowser.entitlements` with outbound network client & `~/Downloads` read-write sandbox permissions.
- [x] **Keychain Security**: All saved passwords stored under `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- [x] **HoloMind AI Privacy Shield**: Regex token sanitizer strips API keys, Bearer tokens, and credit card numbers before LLM submission.
- [x] **First-Run Onboarding**: `HoloOnboardingView.swift` spotlight tutorial and instant skip button.
- [x] **Empty State UI**: `HoloEmptyStateView.swift` integrated across Bookmarks, History, Downloads, and HoloMind sidebar.
- [x] **In-App Beta Feedback**: `FeedbackSheetView.swift` with sanitized diagnostic log export to clipboard.
- [x] **User Data Purge**: `ProfileManager.purgeAllBrowsingDataAndMemories()` complete data wipe workflow.

## 🚀 Binary Distribution Checklist

- [ ] **Developer ID Certificate**: Sign executable with `Developer ID Application: Holo Browser Inc.`.
- [ ] **Hardened Runtime**: Enable Hardened Runtime in Xcode build settings (`ENABLE_HARDENED_RUNTIME = YES`).
- [ ] **Apple Notarization Ticket**: Submit DMG/ZIP archive to `xcrun notarytool` and staple notarization ticket (`xcrun stapler staple`).
- [ ] **Checksum Hash Verification**: Generate `SHA-256` checksum for distribution archive.
