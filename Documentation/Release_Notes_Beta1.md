# Holo Browser Beta 1 Release Notes

Welcome to the first public beta of Holo Browser. This release represents a major milestone in transitioning from a prototype to a daily driver for macOS. 

## New Features
- **Holo Command Center**: A completely reimagined start page featuring the H Daily Briefing, presenting unfinished research, active missions, and AI-filtered opportunities.
- **Holo Visual Engine**: A premium native UI utilizing Liquid Glass, spectral glowing accents, and a dynamic animated background.
- **Proactive Intelligence**: The `HoloInsightRankingEngine` now silently evaluates browser activity to offer high-confidence insights (like price drops and tab clutter) while filtering out low-value notifications.
- **Browser Import Wizard**: Seamlessly import bookmarks, folders, and history from Safari, Chrome, and Brave.
- **Private Mode Enhancements**: Distinct visual indicators and immediate pausing of all AI memory writes.

## Privacy Notes
- **Local First**: Your Holo Memory is stored locally on your device in the `~/.holo` directory and never transmitted unless you explicitly enable remote Sync.
- **Data Isolation**: Profiles operate in strict isolation. Cross-profile cookie leakage is mathematically impossible thanks to distinct `WKWebsiteDataStore` architectures.

## Known Limitations
- Background tabs are currently throttled but full "Tab Sleep" is still in development.
- The web extension API currently supports basic Chrome extensions, but some background workers may fail to initialize.

## Feedback Instructions
Please submit all crash reports and UI feedback via the built-in HoloDoctor "Send Feedback" button, or via our developer portal.
