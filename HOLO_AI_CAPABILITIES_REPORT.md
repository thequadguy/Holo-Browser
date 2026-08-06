# HOLOMIND — AI CAPABILITIES & CHIEF OF STAFF REPORT

## HoloMind Core Architecture

HoloMind operates as an on-device personal chief of staff, synthesizing page content, tab clusters, and user-approved memory indexes into actionable intelligence.

---

## Core AI Features & Action Matrix

| AI Action | Trigger Method | Execution Mechanics | User Approval Requirement |
| :--- | :--- | :--- | :---: |
| **Summarize Page / Tabs** | `Cmd+J` or `h summarize` | `PageContextBuilder` extracts text DOM selection; generates executive bullet summary. | Displayed in sidebar |
| **Compare Products / Tabs** | `h compare` | Extracts pricing, specs, and reviews across open tabs; generates comparison matrix. | Displayed in sidebar |
| **Extract Research Information** | `h extract` | Parses code snippets, references, citations, and key insights into Research Notes. | User confirmation card |
| **Autonomous Missions** | `m [goal]` | `HoloMissionSystem` decomposes multi-step tasks (e.g. price tracking, travel planning). | Explicit user approval step |
| **Personal Memory Indexing** | Automatic / `h remember` | On-device vector/keyword storage (`MemoryPrivacyManager.swift`) with JSON export/purge. | Full user transparency |

---

## AI Activity & Transparency Gatekeeper
- **"What H Saw"**: Displays exact extracted page text and selection context used by the model.
- **"What H Used"**: Shows stored memory items or search queries referenced.
- **"Why H Suggested It"**: Explains model reasoning and confidence score.
- **"What Will Happen Next"**: Outlines browser actions prior to state mutation.
