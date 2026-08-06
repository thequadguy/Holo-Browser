# Holo Browser — 10-File Gemini Audit Package

## Overview
This package reorganizes Holo Browser's core codebase into 10 structured upload batches containing **no more than 10 files each**, allowing Google Gemini to review the repository subsystem-by-subsystem without hitting upload limits.

---

## 📋 Recommended Upload Sequence & Workflow

| Upload Step | Target Batch Folder | File Count | Prompt to Attach | Subsystem Objective |
|---|---|:---:|---|---|
| **Step 1** | `Batch_01_Core_Architecture/` | 9 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit composition root, app entry points, & ViewModel. |
| **Step 2** | `Batch_02_Security_Privacy/` | 9 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit Keychain access control, password security, & privacy. |
| **Step 3** | `Batch_03_AI_System/` | 10 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit `AIContextGatekeeper`, AI providers, & sanitization. |
| **Step 4** | `Batch_04_Browser_WebKit/` | 7 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit WebKit engine, navigation, & crash circuit breaker. |
| **Step 5** | `Batch_05_Tabs_Profiles/` | 10 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit tab management, profile isolation, & classification. |
| **Step 6** | `Batch_06_Data_Storage/` | 8 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit non-blocking disk persistence, history, & bookmarks. |
| **Step 7** | `Batch_07_UI_UX/` | 8 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit UI reachability (`SmartTabSuggestionView`, etc.). |
| **Step 8** | `Batch_08_Release_Operations/` | 6 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit release scripts, notarization, & update validation. |
| **Step 9** | `Batch_09_Tests/` | 5 files | `GEMINI_BATCH_REVIEW_PROMPT.md` | Audit unit test coverage & performance benchmarks. |
| **Step 10** | `Batch_10_Documentation_Context/` | 2 files | `GEMINI_FINAL_COMPARISON_PROMPT.md` | Compare findings against `REPOSITORY_TRUTH_AUDIT.md`. |

---

## 🔒 Verification & Compliance Notice
- **File Limit Compliance**: Every folder contains between 2 and 10 files (100% compliant with 10-file upload limit).
- **Original Source Integrity**: The original Holo Browser source code in `/HoloBrowser/Sources` was untouched.
