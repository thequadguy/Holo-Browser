# Holo Browser 1.0 RC1 — Final Public Beta Test Plan

**Author**: Beta Program Manager & QA Lead  
**Date**: July 30, 2026  

---

## 1. Beta Testing Milestones & Scenarios

### Milestone 1: Fresh Installation & Gatekeeper Verification (Day 1)
- Verify `HoloBrowser.dmg` mounts and installs cleanly.
- Confirm Developer ID signature and Apple Notarization staple pass Gatekeeper assessment (`spctl`).

### Milestone 2: Multi-Profile & Private Browsing Isolation (Day 2–7)
- Test cookie and session isolation across Work, Personal, and Private profiles.
- Verify cloud AI dispatches are strictly blocked in Private Browsing mode.

### Milestone 3: High Tab Count & Memory Profiling (Day 8–15)
- Open 50+ concurrent tabs across multiple profiles.
- Verify background tab memory suspension operates cleanly.

### Milestone 4: Diagnostic Feedback Collection (Day 16–30)
- Collect diagnostic logs (`Preferences > Diagnostics`) and NPS surveys.
- Issue maintenance micro-updates via Sparkle.
