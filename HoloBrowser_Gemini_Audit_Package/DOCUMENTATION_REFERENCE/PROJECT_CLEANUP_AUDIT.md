# Holo Browser 1.0 RC1 — Project Cleanup Audit & Strategy Plan

**Engineer**: Lead macOS Browser Engineer  
**Date**: July 29, 2026  
**Target Repository**: Holo Browser 1.0 RC1 (`/Users/jake/Desktop/Holo Browser`)  

---

## 1. Initial Repository Inventory Baseline

| Metric | Measured Baseline |
|---|:---:|
| **Total Disk Usage** | **592 MB** |
| **Total File Count** | **4,480 files** |
| **Swift Source Files** | **149 files** (`HoloBrowser/Sources`) |
| **Swift Unit Test Files** | **2 files** (`HoloBrowser/Tests`) |
| **Build Artifact Footprint** | **591 MB** (`HoloBrowser/.build`) |
| **Root Markdown Audit Files** | **34 files** |
| **Release Shell Scripts** | **4 scripts** (`scripts/`) |

---

## 2. Largest File & Directory Inventory

1. `HoloBrowser/.build/` — **591 MB** (SPM build artifacts, intermediate object files, module maps, debug symbols). Safe to clean via `swift package clean`.
2. `Holo Browser Prototype/` — **320 KB** (Historical UI concepts and initial architectural drafts).
3. `Holo Browser Documentation/` — **252 KB** (Duplicate milestone audit docs).
4. `Holo Browser/` — **4 KB** (Single file `PROJECT_START_HERE.md`).

---

## 3. Duplicate & Obsolete File Detection

* **SPM Build Cache (`HoloBrowser/.build`)**: 591 MB of generated Swift Package Manager artifacts. Safe to clean.
* **Root Markdown Clutter**: 34 milestone, audit, and security reports are sitting in the root directory, making navigation difficult for external reviewers.
* **Nested Outer Folder (`Holo Browser/`)**: Redundant folder containing only `PROJECT_START_HERE.md`.
* **Redundant Documentation Directory (`Holo Browser Documentation/`)**: Contains duplicate milestone audit files copied to root.

---

## 4. Unused / Dead Swift Code Analysis

* **Unreferenced Symbol Audit**:
  * `WeakScriptMessageProxy` — Used by `Tab.swift` and `BrowserViewModel.swift` to prevent WKUserContentController retain cycles. **Must preserve.**
  * `ClosedTabRecord` — Used by `TabManager.swift` for Cmd+Shift+T profile-isolated tab restoration. **Must preserve.**
  * `SourceCollector` — Used by `BrowserActionExecutor.swift` for WebKit DOM extraction. **Must preserve.**
  * `LocalAIProvider` — Used by `AIProviderFactory.swift` for local Ollama host streaming. **Must preserve.**
* **Result**: All 149 Swift source files in `HoloBrowser/Sources` are actively referenced and required for compilation.

---

## 5. Storage & Sensitive Data Audit

* **API Keys & Credentials**: Verified **0 hardcoded API keys**, **0 passwords**, and **0 real user Keychain credentials** in the repository.
* **Browser History & Cookies**: Verified no user history JSON or persistent cookie databases are committed.
* **JSON Schemas**: File storage templates (`credentials.json`, `history.json`, `bookmarks.json`, etc.) are generated at runtime inside `~/Library/Application Support/HoloBrowser/`.

---

## 6. Proposed Cleanup & Reorganization Action Plan

### Action 1: Reorganize Documentation Hierarchy
Create unified `Documentation/` directory with 4 categorized subfolders:
```
Documentation/
├── Audits/         (All 34 audit reports, QA specs, and sign-off documents)
├── Architecture/   (System specifications, technical architecture v2)
├── Release/        (Release notes, beta plan, signing guides)
└── Development/    (Testing strategy, handoff notes, master roadmap)
```

### Action 2: Clean SPM Generated Build Artifacts
Clean `.build/` directory in `HoloBrowser/` via `swift package clean` to reclaim **~591 MB** of disk space prior to external review.

### Action 3: Consolidate Redundant Outer Directories
Move `PROJECT_START_HERE.md` into `Documentation/Development/` and clean empty redundant directories `Holo Browser/` and `Holo Browser Documentation/`.

### Action 4: Final Verification
Execute `swift build` to confirm **0 Errors, 0 Warnings** and total repository buildability.
