# Holo Browser RC5 — Installation & Update Experience Audit

**Date:** August 1, 2026  
**Target:** `HoloBrowser-RC3-Beta.dmg` & `Holo Browser.app`  

---

## 1. Installation Flow Audit Matrix

| Verification Item | Audit Procedure | Expected Behavior | Observed Result | Status |
|---|---|---|---|---|
| **DMG Opening** | Double-click `HoloBrowser-RC3-Beta.dmg` | Mounts volume `Holo Browser Beta` on Desktop | Volume mounts cleanly with `Holo Browser.app` & `/Applications` symlink | **PASSED** |
| **Drag Installation** | Drag `Holo Browser.app` to `/Applications` | Copies app bundle to `/Applications/Holo Browser.app` | Copies cleanly without missing resources or icon loss | **PASSED** |
| **First Launch** | Launch app from Finder / Spotlight | Triggers `HoloFirstRunExperience` onboarding | Displays 60-second onboarding walkthrough | **PASSED** |
| **Gatekeeper Alert** | Launch unsigned developer build | macOS prompt: "App downloaded from internet" | Gatekeeper prompts for developer approval; resolved via Right-Click -> Open | **PASSED** |
| **macOS Permissions** | Camera / Microphone request by website | Triggers native `PermissionManager` prompt overlay | User choice prompted ("Allow" / "Deny"); no auto-grant | **PASSED** |
| **Default Browser** | Click "Set as Default Browser" in setup | Opens System Settings -> Default Web Browser | Navigates directly to macOS default browser configuration | **PASSED** |
| **Clean Uninstall** | Drag `Holo Browser.app` to Trash | App bundle removed; Application Support data isolated | Isolated inside `~/Library/Application Support/HoloBrowser/` | **PASSED** |
| **Update Integrity** | Perform mock package update | `UpdateValidator.validateUpdatePackage` checks signature | Rejects unsigned packages, non-matching bundle IDs, or version downgrades | **PASSED** |

---

## 2. Gatekeeper & Notarization Summary

For private beta testing, instructions in `TESTER_ONBOARDING.md` guide testers through macOS Gatekeeper approval via `Right-Click → Open` or `System Settings → Open Anyway`. Official Apple Developer ID signing and `notarytool` stapling scripts are prepared in `./scripts/notarize.sh` for production launch.
