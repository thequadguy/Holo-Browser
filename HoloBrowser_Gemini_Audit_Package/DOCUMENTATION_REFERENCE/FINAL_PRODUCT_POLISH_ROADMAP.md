# Holo Browser 1.0 — Final Product Polish Roadmap

**Role**: Senior macOS Product Manager  
**Date**: July 30, 2026  

---

## 1. Before Public Beta (Must Fix)
- [x] Enforce 30-second timed reveal and instant `.onDisappear` memory clearance for saved passwords (`PasswordSettingsView.swift`).
- [x] Offload disk serialization across all 18 storage components to background utility queues (`Task.detached(priority: .utility)`).
- [x] Enforce `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` across all Keychain items.
- [x] Verify Apple Notarization and Gatekeeper signing automation (`scripts/notarize.sh`).

---

## 2. Post-Public Beta Improvements (v1.1)
- [ ] Add customizable keyboard shortcut remapping in Preferences.
- [ ] Expand built-in AI workflow templates for academic PDF research.
- [ ] Enhance web error page illustration assets.

---

## 3. Future Feature Enhancements (v1.2+)
- [ ] Mobile companion sync app using end-to-end encrypted CloudKit sync.
- [ ] Extended WebAssembly widget pipeline for sidebar micro-apps.
