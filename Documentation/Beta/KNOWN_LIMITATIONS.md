# Holo Browser RC2 — Known Limitations

*Last updated: August 2026*

## Browser Engine

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| WebKit-only rendering engine | Some Chrome/Firefox-specific sites may render differently | Use Safari as reference for rendering compatibility |
| No WebExtension API support (yet) | Cannot install Chrome/Firefox extensions | Use built-in Command Palette (⌘K) for productivity |
| Web Inspector requires manual enable | ⌘⌥I toggles `isInspectable` but doesn't auto-open DevTools | After pressing ⌘⌥I, right-click → Inspect Element |

## AI Assistant

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| Cloud AI requires external API key | AI features need OpenAI/Anthropic API key configuration | Configure in Settings → AI Assistant |
| No local on-device AI (yet) | All AI processing goes through cloud providers | Planned for v1.1 with MLX integration |
| Private browsing blocks external AI | AI sidebar is non-functional in private profiles (by design) | Switch to a non-private profile to use AI |

## Profiles & Privacy

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| Profile data on macOS 13 shares default store | Profile isolation requires macOS 14+ for `WKWebsiteDataStore(forIdentifier:)` | Upgrade to macOS 14+ for full isolation |
| Bookmark import limited to HTML format | Cannot directly import Safari/Chrome binary bookmark databases | Export bookmarks as HTML from other browsers first |

## Downloads

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| All downloads go to ~/Downloads | No download location picker | Move files manually after download |
| No download progress tracking | Progress bar shows 50% until complete | Download completes normally; just no granular progress |

## UI & Platform

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| No tab drag-and-drop reordering | Cannot rearrange tabs by dragging | Use ⌘1-9 to switch tabs |
| No split-view or tab groups | Cannot view two pages side by side | Use multiple windows (⌘N) |
| No Find in Page (⌘F) | Cannot search text within a page | Use ⌘K Command Palette or browser AI |
| No Print dialog (⌘P) | Cannot print pages | Use screenshot or PDF export as workaround |

## Performance

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| Memory grows with many WebKit processes | 100+ tabs may consume significant RAM | Tab suspension kicks in automatically after 4 background tabs |
| No process-per-tab architecture | A crash in one tab may affect others sharing the same WebKit process | Session recovery will restore tabs after restart |

## Updates

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| No automatic update system | Must manually download new versions | Check the beta landing page for new releases |
| Code signing not active for beta | macOS Gatekeeper may block unsigned builds | System Settings → Privacy & Security → Open Anyway |
