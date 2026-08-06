# Holo Browser — On-Device Privacy-Safe Memory System

**Author**: Principal Architect & Privacy Lead  
**Target Components**: `MemoryManager.swift`, `MemoryIndexer.swift`, `ContextRetriever.swift`  
**Date**: July 30, 2026  

---

## 1. On-Device Indexing Architecture

- **Local Storage**: Visited page titles, research notes, and user preferences store locally under Application Support JSON files.
- **Privacy Filtering**: `ContextRetriever.shared` filters out any note containing passwords, secret tokens, or sensitive keywords.
- **Zero Cloud Sync**: Memory indexes never leave the device.
