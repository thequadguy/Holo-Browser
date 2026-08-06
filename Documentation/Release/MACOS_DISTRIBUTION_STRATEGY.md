# Holo Browser — macOS Distribution Channels Strategy

**Author**: Head of Product & Release Engineering Lead  
**Date**: July 30, 2026  

---

## 1. Distribution Channel Analysis & Comparison

| Channel | Key Advantages | Limitations / Constraints | Strategic Timing |
|---|---|---|:---:|
| **Option A: Apple Notarized Web Download (`.dmg`)** | Direct user relationship, zero App Store sandbox restrictions, instant update shipping via Sparkle | Requires Developer ID certificate & Apple `notarytool` submission | **IMMEDIATE (Public Beta Launch)** |
| **Option B: Mac App Store (MAS)** | Trusted distribution channel for mainstream consumers, high organic search discoverability | Strict Apple App Store review guidelines & WebKit process restriction rules | **POST 1.0 OFFICIAL LAUNCH** |
| **Option C: Setapp Subscription Network** | Access to 500,000+ paying Mac power users, recurring subscription revenue stream | Curated acceptance requirement | **90 DAYS POST LAUNCH** |
| **Option D: Homebrew Cask (`brew install --cask holobrowser`)** | Standard developer installation workflow, automated CLI updates | Developer/CLI audience focus | **LAUNCH DAY** |

---

## 2. Recommended Launch Distribution Mix

1. **Launch Target (Day 1)**: Primary distribution via **Option A (Notarized Web DMG)** with Sparkle auto-updates + **Option D (Homebrew Cask)**.
2. **Follow-On Expansion (Post 1.0)**: Submit to Mac App Store and apply for Setapp inclusion after 90 days of proven beta stability.
