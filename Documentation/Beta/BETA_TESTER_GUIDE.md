# Holo Browser 1.0 RC2 — Private Beta Tester Guide

Welcome to the Holo Browser Private Beta program!

---

## 1. Quick Installation

1. Download `HoloBrowser_1.0_RC2.dmg`.
2. Open the DMG package and drag **Holo Browser.app** into your `/Applications` folder.
3. Launch **Holo Browser** from Spotlight (`⌘Space`) or Launchpad.

---

## 2. Getting Started & Key Features

- **Command Palette (`⌘K`)**: Access tabs, commands, bookmarks, and AI features instantly.
- **Isolated Profiles**: Create work, personal, and research profiles via the toolbar profile switcher. Each profile runs in its own isolated cookie and data storage sandbox.
- **Preferences & Password Settings (`⌘,`)**: Access preferences and view saved credentials in Apple Keychain securely.
- **AI Assistant**: Click the sparkles icon or press `⌘ShiftA` to open the human-in-the-loop AI sidebar.

---

## 3. Privacy Overview

- All password credentials are stored exclusively in **Apple Keychain** (`Security.framework`).
- Private browsing mode writes **zero history or session data to disk** and redacts URLs before AI context processing.
- AI actions require your explicit human approval before taking browser steps.

---

## 4. How to Report Feedback

If you encounter a bug or crash:
1. Open Preferences (`⌘,`) -> Diagnostics -> **Export Diagnostic Report**.
2. Fill out the `BETA_FEEDBACK_TEMPLATE.md` and submit your issue to `beta@holobrowser.app`.
