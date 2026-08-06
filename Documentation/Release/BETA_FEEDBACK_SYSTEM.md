# Holo Browser — Beta Feedback System Design

**Author**: DevRel Lead & Beta Program Manager  
**Date**: July 30, 2026  

---

## 1. Multi-Tier Feedback System Architecture

### Tier 1: In-App Diagnostics Logger (`Preferences > Diagnostics`)
- Users can click **Export Diagnostic Log** to generate a local text summary.
- **Privacy Assurance**: The logger automatically strips URLs, domain paths, personal credentials, and web content before export.

### Tier 2: Interactive Bug Reporting
- **Required Report Fields**:
  - macOS Version (e.g., 14.5 or 15.0)
  - Mac Model (e.g., M2 MacBook Air, 16GB)
  - Issue Summary & Steps to Reproduce
  - Optional Sanitized Screenshot / Error Text

### Tier 3: Public Roadmap & Feature Voting Board
- Hosted feature voting board allowing beta testers to upvote and comment on requested feature enhancements (e.g., mobile companion sync, customizable keyboard shortcuts).

### Tier 4: Micro Surveys
- **NPS Survey**: Triggered via non-intrusive banner after 7 days of active daily usage ("How likely are you to recommend Holo Browser to a Mac user?").
- **Switching Survey**: Asks users which browser Holo Browser replaced (Safari, Arc, Chrome, Brave) and their top reason for switching.
