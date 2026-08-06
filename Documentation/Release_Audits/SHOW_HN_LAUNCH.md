# Show HN Launch Package — Holo Browser 1.0

**HN Post Title**: Show HN: Holo Browser — A native SwiftUI/WebKit Mac browser with strict AI privacy

---

## Technical Highlights for Hacker News Discussion:

1. **Native SwiftUI & WebKit**:
   - Zero Electron or Chromium dependency.
   - Compiles under Swift 6 complete strict concurrency checking (`-strict-concurrency=complete`).
2. **Profile Data Store Isolation**:
   - Manages independent `WKWebsiteDataStore(forIdentifier:)` instances per profile (`ProfileManager.swift:L31`).
3. **Mandatory Regex AI Privacy Pipeline**:
   - Automatically redacts JWTs, API keys (`sk-*`), Bearer auth headers, passwords, credit card numbers, and private key blocks in `AIPrivacyManager.swift` before queries leave the Mac.
4. **Non-Blocking Utility Storage I/O**:
   - All 18 JSON disk serialization components execute off `@MainActor` via `Task.detached(priority: .utility)`.
5. **WebKit Crash Circuit Breaker**:
   - Implements a 3-stage process crash recovery loop protection in `NavigationManager.swift`.
