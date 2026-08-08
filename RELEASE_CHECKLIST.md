# 🚀 HOLO BROWSER V1.7 — RELEASE ENGINEERING CHECKLIST

## 1. Build Verification & Hardened Runtime

- [x] **Clean Swift Build**: `swift build` finishes with **0 errors and 0 warnings**.
- [x] **TestLab Suite**: `swift run HoloBrowserTestLab` passes **102 / 102 test cases (100% Pass Rate)**.
- [x] **Hardened Runtime**: Enabled in Xcode target build settings (`ENABLE_HARDENED_RUNTIME = YES`).
- [x] **App Sandbox Entitlements**:
  - `com.apple.security.app-sandbox` = `true`
  - `com.apple.security.network.client` = `true`
  - `com.apple.security.files.user-selected.read-write` = `true`
  - `com.apple.security.files.downloads.read-write` = `true`

---

## 2. Developer ID Code Signing & Notarization

```bash
# Step 1: Code Sign Application Bundle with Developer ID Application Certificate
codesign --force --deep --options runtime --sign "Developer ID Application: Your Name (TEAM_ID)" "Holo Browser.app"

# Step 2: Create Distribution ZIP for Notarization
ditto -c -k --keepParent "Holo Browser.app" "HoloBrowser-V1.7.0.zip"

# Step 3: Submit to Apple Notarization Service via xcrun notarytool
xcrun notarytool submit "HoloBrowser-V1.7.0.zip" --keychain-profile "AC_NOTARY" --wait

# Step 4: Staple Notarization Ticket to Bundle
xcrun stapler staple "Holo Browser.app"
```

---

## 3. Data Safety & Privacy Audit

- [x] **Keychain Storage**: Saved passwords & certificates stored strictly in macOS Keychain.
- [x] **Profile Isolation**: Data stores for Personal, Work, and Incognito profiles remain completely isolated.
- [x] **Purge All Browsing Data**: Verified `purgeAllBrowsingDataAndMemories()` safely wipes local databases without leaving residual history.
- [x] **Telemetry & Diagnostics**: Stripped of URLs, page HTML, browsing history, and passwords.

---

## 4. Performance & Memory Thresholds

- [x] **Launch Latency**: `< 3500 ms` cold start.
- [x] **RAM Footprint**: `< 150 MB` idle RAM RSS.
- [x] **UI Frame Rate**: `60 FPS` smooth Liquid Glass rendering.
