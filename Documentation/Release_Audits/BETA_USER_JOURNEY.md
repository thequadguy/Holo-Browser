# Holo Browser 1.0 — Beta User Journey Documentation

**Author**: DevRel Lead & Product Ops Lead  
**Date**: July 30, 2026  

---

## 1. User Journey Mapping

1. **Discovery**: User finds Holo Browser via Show HN, Product Hunt, or Reddit `r/macapps`.
2. **Download & Mount**: User downloads `HoloBrowser.dmg` from `download.html` and drags `HoloBrowser.app` to `/Applications`.
3. **Gatekeeper Validation**: Apple Notarization ticket passes Gatekeeper evaluation (`verify_release.sh`).
4. **Onboarding**: User chooses initial profile and configures AI provider in `WelcomeView.swift`.
5. **Daily Browsing**: User navigates, creates profiles, uses Spotlight `Cmd + K`, and streams AI summaries.
6. **Diagnostics & Feedback**: User exports diagnostic log via `Preferences > Diagnostics` or submits feedback.
7. **Auto-Updates**: Sparkle checks update appcast and applies seamless background updates.
