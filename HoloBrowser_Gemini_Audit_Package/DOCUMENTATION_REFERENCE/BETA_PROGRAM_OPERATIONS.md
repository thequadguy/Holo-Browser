# Holo Browser 1.0 — Public Beta Program Operations Manual

**Author**: Beta Program Manager & Product Ops Lead  
**Date**: July 30, 2026  

---

## 1. Beta Program Operations Architecture

- **Beta Status View (`BetaStatusView.swift`)**: In-app UI component allowing users to view build information, opt into privacy analytics, export diagnostic text summaries, and submit bug reports directly.
- **Diagnostics Export (`DiagnosticsExporter.swift`)**: Automatically strips URLs, domain names, query parameters, web context, and passwords prior to log export.
- **User Journey Tracking (`UserJourneyTracker.swift`)**: Records milestone completion locally (`firstLaunchCompleted`, `profileCreated`, `commandPaletteUsed`, `aiFeatureActivated`).
