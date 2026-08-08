# HOLO BROWSER — KNOWN ISSUES & LIMITATIONS (V1.3 BETA)

## 📌 Non-Blocking Known Limitations

1. **CloudKit Device Sync**: Cross-device sync for bookmarks and HoloMind memories is currently local-only (`DiskStorageActor`). Full E2EE CloudKit sync is scheduled for V1.4.
2. **Metal 3 Liquid Shaders**: Window backdrops currently use Apple's native `NSVisualEffectView` optical vibrancy. Custom GPU fluid caustics are scheduled for V1.4.
3. **Legacy Chrome Extension Manifest V2**: Holo Browser natively supports lightweight WebKit extensions; legacy Chrome MV2 NPAPI plugins are not supported.

## 🛠️ Workarounds & Mitigations

- **Tab Restoration**: If a website crashes due to extreme memory spikes, press `Cmd+Shift+T` to restore the tab state cleanly.
- **AI Token Rate Limits**: If custom OpenAI/Claude API keys exceed rate limits, HoloMind automatically falls back to local heuristic extraction mode.
