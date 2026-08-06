# Holo Browser RC5 — Private Beta Testing Framework

**Target Audience:** 25–100 macOS daily-driver testers  
**Program Duration:** 14 Days  
**Distribution Channel:** `HoloBrowser-RC3-Beta.dmg`  

---

## 1. Tester Onboarding & Invitation Process

1. **Invitation Email**: Selected testers receive invitation link with release notes, security overview, and download link for `HoloBrowser-RC3-Beta.dmg`.
2. **First-Run Experience**: Upon launching `Holo Browser.app`, the interactive 60-second `HoloFirstRunExperience` guides testers through:
   - Why Holo Browser exists (Native Swift vs heavy Electron bloat)
   - Privacy guarantee (Zero cloud history, regex AI sanitization, Apple Keychain)
   - Intelligent AI Assistant & Cmd+K features
   - Bookmark HTML importing & setting Holo as default browser
3. **Opt-in Telemetry**: Testers are informed that anonymous local crash metrics (`LocalUsageMetrics`, `CrashReportManager`) remain strictly local to their machine.

---

## 2. Installation & Gatekeeper Instructions

- **Download**: Double-click `HoloBrowser-RC3-Beta.dmg`.
- **Install**: Drag `Holo Browser.app` to the `Applications` folder shortcut.
- **First Launch (macOS Gatekeeper)**:
  - If macOS displays "App downloaded from internet / Unidentified Developer":  
    Right-click `Holo Browser.app` → Select **Open** → Click **Open** in dialog.  
    *Or*: Open **System Settings → Privacy & Security → Click "Open Anyway"**.

---

## 3. Bug Severity Definitions

| Severity Level | Definition | Response SLA | Action Required |
|---|---|---|---|
| **P0 — Critical Security / Crash** | Vulnerability, crash loop, data corruption, or unlaunchable app | < 2 Hours | Emergency patch & build hotfix |
| **P1 — Major Functional Defect** | Core feature broken (e.g. downloads failing, profile switch error) | < 12 Hours | Target fix in next RC build |
| **P2 — Minor UX Defect** | UI glitch, wrong layout margin, missing keyboard shortcut | < 48 Hours | Schedule for polish pass |
| **P3 — Polish / Feature Request** | Cosmetic enhancement, request for new preference toggle | Backlog | Evaluate for v1.1 roadmap |

---

## 4. Crash Reporting & Feedback Workflow

- **In-App Feedback**: Testers press **⌘⇧?** or select **Help → Send Feedback…** in the menu bar.
- **Diagnostic Export**: Click **Export Diagnostics** to copy privacy-sanitized diagnostic system text (`DiagnosticsExporter.swift`).
- **Local Crash Logs**: In Settings → System Health, testers can inspect recorded subsystem crashes and run `HoloDoctor` 1-click repairs.

---

## 5. Privacy Expectations & Guarantees

- **No Remote Tracking**: Browsing URLs, page content, search queries, cookies, and passwords are **NEVER** sent to external servers.
- **Keychain Storage**: All passwords remain encrypted in Apple Keychain via `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- **AI Sanitization**: AI requests scrub API keys, Bearer headers, JWTs, and credit card numbers automatically.
