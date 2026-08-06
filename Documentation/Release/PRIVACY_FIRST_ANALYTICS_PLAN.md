# Holo Browser — Privacy-First Measurement & Zero-Telemetry System Design

**Author**: Head of Engineering & Data Privacy Officer  
**Date**: July 30, 2026  

---

## 1. Zero-Telemetry Measurement Principles

Traditional browser analytics collect user browsing history, search terms, and page URLs. Holo Browser rejects invasive telemetry entirely.

### What Holo Browser NEVER Collects:
- ❌ Browsing history, URLs, or domain names
- ❌ Search terms or address bar queries
- ❌ AI context text, user prompts, or AI responses
- ❌ Saved passwords, usernames, or API keys
- ❌ IP addresses or personal identifiers

---

## 2. Privacy-Preserving Opt-In Metrics (Aggregated Only)

If a user explicitly opts in via **Preferences > Privacy**:

1. **App Version & Build**: Aggregated build number (`1.0.0-build100`) to track active release adoption.
2. **Crash Frequency Count**: Numerical tally of WebContent process crash recovery events (e.g. `crash_count: 1`).
3. **Feature Usage Counters**: Anonymized integer counts for feature interactions (e.g. `command_palette_launched: 5`, `ai_summary_used: 3`). Zero text payload is captured.
