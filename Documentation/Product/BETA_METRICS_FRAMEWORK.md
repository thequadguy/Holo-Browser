# Holo Browser 1.0 — Product Decision Metrics Framework

**Author**: Head of Product Analytics  
**Date**: July 30, 2026  

---

## 1. Privacy-First Metrics Hierarchy

All metrics operate under opt-in anonymous aggregation via `PrivacyAnalyticsManager.swift`:

- **Activation Metric**: % of new installs completing the 6-step onboarding wizard (`WelcomeView.swift`). Target: > 85%.
- **Retention Metric**: % of beta testers launching Holo Browser on Day 7 and Day 30. Target: > 40%.
- **Engagement Metric**: Median daily `Cmd + K` Command Palette interactions and AI page summaries per active session. Target: > 6 interactions/day.
- **Satisfaction Metric**: In-app Net Promoter Score (NPS) survey score. Target: > +50.
