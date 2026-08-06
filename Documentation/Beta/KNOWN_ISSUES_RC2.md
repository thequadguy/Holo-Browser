# Holo Browser 1.0 RC2 — Known Issues & Workarounds

---

## 1. Known Minor Display Items

- **WebExtension Popup Sizing**: Some legacy Manifest V2 WebExtension popovers may require manual resizing on first open.
- **Local LLM Model Pre-warming**: On first launch of local inference mode (`Ollama` / `LocalLLM`), initial token generation may experience a 1-second warm-up latency.

---

## 2. Mitigated & Resolved Issues

- **Fixed in RC2**: Fake update package validation vulnerability resolved via `SecStaticCodeCheckValidity` API.
- **Fixed in RC2**: Download path traversal vulnerability resolved via strict `lastPathComponent` sanitization inside `~/Downloads/`.
- **Fixed in RC2**: Concurrent disk write race condition resolved via `DiskStorageActor`.
- **Fixed in RC2**: Unreachable Settings menu resolved via `Cmd+,` shortcut and native macOS `Preferences...` menu item.
