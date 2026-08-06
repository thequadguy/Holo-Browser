# Holo Browser — Feedback & Diagnostics System Documentation

**Author**: Lead Engineer & Privacy Officer  
**Date**: July 30, 2026  

---

## 1. Privacy-Preserving Feedback System

The feedback and diagnostics pipeline enforces zero-telemetry rules:

- **Diagnostics Export (`Preferences > Diagnostics`)**: Generates an anonymized diagnostic report containing macOS version, CPU architecture, build number, and crash recovery counters.
- **Zero Raw Data Policy**: Automatically strips URLs, domain names, query parameters, web context, and passwords before exporting text summaries.
