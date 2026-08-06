# Holo Browser 1.0 — Public Beta Testing Program & Scenarios

**Author**: Beta Program Manager & Product Analytics Lead  
**Date**: July 30, 2026  

---

## 1. Beta Tester Cohorts & Target Demographics

| Cohort | Target Audience | Focus Areas | Key Success Indicator |
|---|---|---|:---:|
| **Cohort A** | Safari Switchers | Low RAM footprint, battery life, native macOS HIG | > 70% retention after 7 days |
| **Cohort B** | Chrome / Arc Power Users | Spotlight `Cmd + K`, multi-tab performance, profiles | Daily `Cmd + K` usage > 5x |
| **Cohort C** | Privacy Advocates | Keychain `ThisDeviceOnly`, regex AI scrubbing, 0 telemetry | Zero privacy friction complaints |
| **Cohort D** | Mac Developers & AI Enthusiasts | Local Ollama LLM integration, offline summaries | Successful local AI queries |

---

## 2. Structured Testing Scenarios

1. **Bookmark & History Import**: Verify importing bookmarks from Chrome/Safari HTML files (`BrowserImportManager.swift`).
2. **Heavy Multi-Tab Usage**: Run 30+ tabs across 3 distinct profiles to test WebKit background tab memory suspension.
3. **Private Browsing Shield**: Confirm cloud AI dispatches are strictly blocked in Private Mode (`AIPrivacyManager.swift`).
4. **Diagnostic & Feedback Flow**: Export privacy-sanitized diagnostic text via `Preferences > Diagnostics` or `BetaStatusView.swift`.
