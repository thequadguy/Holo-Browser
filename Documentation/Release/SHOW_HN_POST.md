# Show HN: Holo Browser — A native SwiftUI/WebKit Mac browser with strict AI privacy

Hey HN,

We built Holo Browser because we loved Arc's modern UI workflow, but were frustrated by Electron RAM bloat, battery drain, and cloud AI context data leaks.

Holo Browser is built 100% natively for macOS using SwiftUI and WebKit:
- **Zero-Telemetry & Device-Only Keychain**: Passwords and API keys stay in Apple Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
- **Profile Data Isolation**: Per-profile `WKWebsiteDataStore` containers prevent cookie bleed.
- **Mandatory AI Context Scrubbing**: Regex context sanitization scrubs JWTs, API keys, CCs, passwords, and tokens before sending context to LLMs.
- **Spotlight Command Palette**: `Cmd + K` search for open tabs, profiles, and AI actions.

Try the public beta: https://holobrowser.com
We'd love your feedback!
