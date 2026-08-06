# Holo Browser 1.1 — Feature Implementation Specifications

**Author**: Principal Engineer & Product Lead  
**Date**: July 30, 2026  

---

## 1. Feature Specifications Breakdown

### A. Smart Tab Intelligence (`SmartTabEngine.swift` / `SmartTabManager.swift` / `TabClassifier.swift`)
- **Data Model**: `TabGroupSuggestion(id, categoryName, tabIDs)`
- **Concurrency**: `@MainActor` isolation with background classification queues.
- **Storage**: Persists custom manual category overrides (`manualOverrides`) in Application Support JSON files off `@MainActor` via `Task.detached(priority: .utility)`.

### B. Privacy Dashboard (`PrivacyDashboardView.swift` / `PrivacyDashboardManager.swift`)
- **Data Model**: On-device metric counts for blocked trackers, AI context sanitizations, and private mode shield events.
- **UI Structure**: Native SwiftUI cards displaying real-time security feature status.

### C. Research Workspace (`ResearchWorkspaceView.swift` / `ResearchManager.swift`)
- **Data Model**: `ResearchSession(id, title, topic, sources, notes)`
- **AI Pipeline**: Routes all multi-source synthesis requests through `AIContextGatekeeper.shared`.
- **Export System**: 1-click Markdown export to system clipboard (`copyMarkdownExport`).
