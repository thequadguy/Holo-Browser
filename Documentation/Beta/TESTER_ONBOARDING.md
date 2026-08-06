# Holo Browser Private Beta — Tester Onboarding Guide

Welcome to the Holo Browser Private Beta! Thank you for helping us build the next-generation macOS browser.

## Getting Started

### Installation

1. Unzip `HoloBrowser-RC2-Beta.zip`
2. Drag **Holo Browser.app** to your **Applications** folder
3. Double-click to launch
4. If macOS blocks the app: **System Settings → Privacy & Security → Open Anyway**

### First Launch

On first launch, you'll see a Welcome screen that walks you through:
- Privacy overview (how Holo protects your data)
- Bookmark import (from Safari, Chrome, or HTML files)
- Setting Holo as your default browser (optional)

### Key Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘T | New Tab |
| ⌘W | Close Tab |
| ⌘L | Focus Address Bar |
| ⌘K | Command Palette (search everything) |
| ⌘⇧A | Toggle AI Sidebar |
| ⌘⇧T | Restore Closed Tab |
| ⌘, | Preferences |
| ⌘1-9 | Switch to Tab 1-9 |
| ⌘⌥I | Web Inspector |

### Profiles

Holo Browser supports isolated browsing profiles. Each profile has its own cookies, sessions, and data. Switch profiles from the toolbar.

**Private Profile**: A private profile stores nothing to disk — no history, no cookies, no session data.

### AI Assistant

Press ⌘⇧A or click the sparkle icon (✨) to open the AI sidebar. The AI assistant:
- Never sends data from private browsing tabs
- Sanitizes all context before sending (removes passwords, tokens, API keys)
- Requires human approval before taking browser actions

---

## Reporting Issues

### From the App
**Help → Send Feedback** (⌘⇧?)

### Via Template
Use the `BUG_REPORT_TEMPLATE.md` in this folder for structured reports.

### What to Include
- Steps to reproduce
- Expected vs actual behavior
- macOS version
- Screenshots if applicable
- Diagnostic export (from the feedback form)

---

## Known Limitations

See `KNOWN_LIMITATIONS.md` for the current list of known issues and workarounds.

## Privacy Promise

- **Zero telemetry by default** — opt-in only
- **No URLs, history, or passwords** are ever collected
- **Diagnostics** include only system version and crash stack traces
- **AI context** is sanitized to remove all sensitive data before transmission
