# Holo Browser — Real-World Beta Test Scenarios & Test Cases

**Author**: QA & Beta Testing Lead  
**Date**: July 30, 2026  

---

## 1. Persona Test Cases

### Test Suite 1: Power User (High Tab Volume & Workflows)
- **TC-1.1**: Open 50+ concurrent tabs across 3 distinct profiles. Verify background tab memory suspension operates without UI stutter.
- **TC-1.2**: Launch Spotlight Command Palette (`Cmd + K`) and execute multi-tab synthesis.
- **TC-1.3**: Trigger session restore after quitting the application. Verify all 50 tabs recreate under their original profile data stores.

### Test Suite 2: Privacy Advocate (Zero-Data Exposure Verification)
- **TC-2.1**: Open a Private Window (`Cmd + Shift + N`). Verify dark purple private theme applies.
- **TC-2.2**: Attempt cloud AI query in Private Browsing. Verify request is blocked with privacy warning while local AI functions offline.
- **TC-2.3**: Save credentials on a login page. Verify passwords store in Keychain with `ThisDeviceOnly` access attributes.

### Test Suite 3: Developer & Researcher (Web Standards & Local AI)
- **TC-3.1**: Inspect web application DOM via DevTools context menu.
- **TC-3.2**: Connect local Ollama server endpoint in Preferences. Perform local LLM query and verify zero network packets leave the device.
- **TC-3.3**: Install WebExtension manifest. Verify extension runs cleanly under sandboxed container.

### Test Suite 4: Everyday Consumer (Daily Browsing & Media)
- **TC-4.1**: Stream 4K video playback. Verify hardware-accelerated WebKit video decoding operates without frame drops.
- **TC-4.2**: Import bookmarks from Chrome HTML export (`BrowserImportManager.swift`). Verify imported items populate under "Imported".
