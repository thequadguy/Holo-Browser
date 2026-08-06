# Holo Browser 1.0 — Independent Production Engineering Review

**Reviewer**: Principal macOS Engineer / Security Architect / Code Review Lead  
**Methodology**: Direct source-code inspection of all critical files — no reliance on prior audit reports  
**Date**: 2026-07-29  

---

## Executive Summary

| Dimension | Rating |
|---|---|
| **Overall Code Quality Score** | **5 / 10** |
| **Production Readiness** | **Beta-grade (not public release ready)** |
| **Biggest Risk** | AI providers are mock-only stubs — no real AI functionality ships |
| **Second Biggest Risk** | WebContent crash recovery is wired but never actually called |
| **Third Biggest Risk** | Media permissions are auto-granted to every website |

---

## Critical Issues (P0 — Must Fix Before Any Real Release)

### P0-1: AI Providers Are Mock Stubs — No Real AI Functionality Exists

**Severity**: CRITICAL  
**File**: `HoloBrowser/Sources/AI/AIProvider.swift`

Both `OpenAIProvider` and `AnthropicProvider` make **zero real API calls**. Both providers, when called, silently instantiate a `MockAIProvider` and delegate to it:

```swift
// OpenAIProvider.sendMessage (line 54-65)
Task {
    let fallback = MockAIProvider()  // <- ALWAYS uses mock
    for try await chunk in fallback.sendMessage(request) {
        continuation.yield(chunk)
    }
}
```

The same pattern is in `AnthropicProvider`. An API key is accepted but ignored entirely. **Every "AI" response shown to users is a canned mock string.** The same applies to `LocalInferenceEngine`'s CoreML path — `queryCoreML` returns a hardcoded string after a 200ms sleep with zero actual model inference.

**Evidence**: The only working AI path is `LocalInferenceEngine.queryOllama()` which does make real HTTP requests to `127.0.0.1:11434` — but only if the user has Ollama installed and running separately.

**Impact**: Every benchmark and audit report claiming "AI-powered features" is misleading. This is a demo/mockup, not a shipping AI browser.

**Fix**: Implement real OpenAI and Anthropic streaming API calls using URLSession with proper SSE (Server-Sent Events) parsing, or clearly label the app as "Ollama local-only."

---

### P0-2: WebContent Crash Recovery Is Never Triggered

**Severity**: CRITICAL  
**Files**: `ReliabilityManager.swift`, `WKWebViewWrapper.swift`, `NavigationManager.swift`

`ReliabilityManager` has a method `handleWebContentProcessTermination(tab:)` but this method is **never called anywhere in the codebase**. The correct hookup requires implementing `webViewWebContentProcessDidTerminate(_:)` on a `WKNavigationDelegate` and calling `ReliabilityManager.handleWebContentProcessTermination(tab:)` from there.

Neither `NavigationManager` (which is the `WKNavigationDelegate`) nor `WKWebViewWrapper` implements this delegate method. If the WebContent process crashes, the tab will show a white blank page with no recovery.

**Evidence**: Grepping the entire codebase for `webViewWebContentProcessDidTerminate` returns zero results.

**Fix**: Add the `WKNavigationDelegate` method to `NavigationManager`:

```swift
nonisolated public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    Task { @MainActor in
        // Reload the webview to recover
        webView.reload()
    }
}
```

---

### P0-3: Media Permissions Auto-Granted to All Websites

**Severity**: CRITICAL  
**File**: `HoloBrowser/Sources/Security/PermissionManager.swift` (lines 23–33)

The `PermissionManager` implements `WKUIDelegate` and its media capture handler unconditionally grants camera and microphone access to every website:

```swift
decisionHandler(.grant)  // <- No user prompt, no allow-list check
```

Any website can silently access the user's camera and microphone. This is a severe privacy violation for a browser claiming to be privacy-first.

**Fix**: Replace with a user-facing permission prompt that asks before granting, and store allow/deny decisions per-domain.

---

### P0-4: `NavigationManager` Is Never Set as `WKNavigationDelegate`

**Severity**: CRITICAL  
**Files**: `NavigationManager.swift`, `Tab.swift`, `WKWebViewWrapper.swift`

`NavigationManager` implements `WKNavigationDelegate` with all the correct delegate methods. However, in `Tab.restoreIfNeeded()` (the only place a `HoloWebView` is created), **`navigationDelegate` is never assigned**:

```swift
public func restoreIfNeeded() -> HoloWebView? {
    if webViewInstance == nil {
        let config = WKWebViewConfiguration()
        let wv = HoloWebView(frame: .zero, configuration: config)
        self.webViewInstance = wv
        navigationManager.webView = wv
        // Missing: wv.navigationDelegate = navigationManager
        // Missing: wv.uiDelegate = permissionManager
```

None of the navigation delegate callbacks (`didStartProvisionalNavigation`, `didFinish`, `didFail`, etc.) will ever fire. KVO on `webView.publisher(for: \.url)` will still reflect URL changes, but error handling, load state tracking, and title updates from delegate methods are dead code.

**Fix**: Add `wv.navigationDelegate = navigationManager` in `restoreIfNeeded()`.

---

### P0-5: `holoPasswordDetector` Script Message Handler — Retain Cycle & Handler Leak

**Severity**: CRITICAL  
**File**: `BrowserViewModel.swift` (lines 142–143)

Every time `setupActiveTabBindings()` is called (on every tab switch), this code runs:

```swift
activeTab.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "holoPasswordDetector")
activeTab.webView?.configuration.userContentController.add(self, name: "holoPasswordDetector")
```

`WKUserContentController.add(_:name:)` retains its handler strongly — this is a known WebKit retain cycle pattern. `BrowserViewModel` is retained by the `WKUserContentController` of every tab ever created, preventing deallocation.

Additionally, `removeScriptMessageHandler` is called on the **new** active tab's webview (removing a handler that may not exist), while the **old** active tab's handler is never removed. Each tab switch leaks a handler registration.

**Fix**: Use `addScriptMessageHandlerWithReply` or use a weak proxy pattern (`WKScriptMessageHandlerWithReply` or a separate `@unchecked Sendable` proxy object that holds a weak reference).

---

## High Priority Issues (P1 — Fix Before Daily Driver Use)

### P1-1: `ProfileManager` Does Not Wire `WKWebsiteDataStore` into New Tabs

**Severity**: HIGH  
**File**: `ProfileManager.swift`, `Tab.swift` (line 100)

`ProfileManager.websiteDataStore(for:)` correctly creates isolated `WKWebsiteDataStore` instances per profile. However in `Tab.restoreIfNeeded()`:

```swift
let config = WKWebViewConfiguration()
let wv = HoloWebView(frame: .zero, configuration: config)
```

A fresh `WKWebViewConfiguration` is created with the **default shared data store**, ignoring the profile's isolated store entirely. Profile cookies, sessions, and local storage are **not isolated** — all profiles share the same underlying WebKit data store on macOS < 14.

**Fix**: `Tab.restoreIfNeeded()` needs to accept a `WKWebsiteDataStore` and assign it to the configuration before creating the webview.

---

### P1-2: `HistoryStore` Has No Profile Isolation

**Severity**: HIGH  
**File**: `HistoryStore.swift`

`HistoryStore` saves all browsing history to a single `history.json` file with no `profileID` field on `HistoryItem`. All profiles share the same history. A private browsing profile's history is written to this file (the private check is in `ContentView`, not in `HistoryStore` itself, and only guards the `historyStore.addEntry` call — but there is no `isPrivate` check inside `HistoryStore` as a safety layer).

**Fix**: Add `profileID: UUID` to `HistoryItem`. Filter by profile on reads. Add an internal `isPrivate` guard in `addEntry`.

---

### P1-3: `SessionManager` Does Not Use `SafeJSONDecoder`

**Severity**: HIGH  
**File**: `SessionManager.swift` (lines 54–61)

`SessionManager.loadPreviousSession()` uses a raw `JSONDecoder().decode(...)` call. If `session.json` is corrupted (e.g. due to a crash mid-write), the result is silently `nil` — no backup, no diagnostics, no user notification. This is especially risky given that `session.json` is written on every tab operation via `autoSaveSession()` (which triggers on every `tabManager.$tabs` and `tabManager.$activeTabID` change).

**Fix**: Use `SafeJSONDecoder.decodeWithFallback`. Apply the same pattern consistently in `HistoryStore`, `BookmarkManager`, and `ReadingListManager` (which all use raw `JSONDecoder`).

---

### P1-4: Auto-Session-Save on Every Tab Change Is a Performance Problem

**Severity**: HIGH  
**File**: `BrowserViewModel.swift` (lines 103–117)

`autoSaveSession()` is called synchronously on every `tabManager.$tabs` and `tabManager.$activeTabID` change. This triggers a full JSON encode + synchronous disk write on the main thread for every URL navigation, every tab creation, and every tab switch. At 50+ tabs, this is a measurable main-thread block.

**Fix**: Debounce `autoSaveSession()` with a 0.5–1 second delay. Move the disk write off main thread with `Task.detached`.

---

### P1-5: `OmniBoxManager` Is Unused — Address Bar Has No Smart Suggestions

**Severity**: HIGH  
**File**: `OmniBoxManager.swift`, `AddressBarView.swift`

`OmniBoxManager.rankSuggestions(...)` was created in Phase 9 but is not called from `AddressBarView`. The address bar autocomplete in `AddressBarView` (the Phase 6.5 implementation) uses its own inline filtering logic. `OmniBoxManager` is dead code.

**Fix**: Wire `OmniBoxManager` into the address bar's suggestion pipeline, or remove it to avoid confusion.

---

### P1-6: `KeychainManager` Uses `kSecAttrAccessibleWhenUnlocked` Without User Presence

**Severity**: HIGH  
**File**: `KeychainManager.swift` (line 25)

Passwords are stored with `kSecAttrAccessibleWhenUnlocked`. This means any process running as the same user while the Mac is unlocked can read passwords without any biometric check. For a password manager, best practice is `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` combined with `kSecAccessControlUserPresence` (Touch ID / password gate) for retrieval.

**Fix**: Add `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (removes iCloud sync of passwords) and add a Touch ID gate on `retrievePassword`.

---

### P1-7: `AIActionManager` Auto-Approves "Safe" Plans Without User Awareness

**Severity**: HIGH  
**File**: `AIActionManager.swift` (lines 32–35)

```swift
} else if actions.allSatisfy({ $0.riskLevel == .safe }) {
    self.activePlan?.status = .approved
    log(actionName: goal, wasApproved: true, result: "Safe plan approved automatically.")
}
```

Safe plans execute without showing the user any confirmation. What counts as "safe" depends entirely on the risk classification of `AIAction`, which is set by the AI planner itself. A maliciously crafted webpage could trigger `collectSource` or `openNewTab` actions classified as "safe" without any user prompt.

**Fix**: Even "safe" plans should show a brief non-blocking notification. Add a minimum visibility requirement.

---

## Medium Priority Issues (P2)

### P2-1: `PageContextBuilder` Redaction Is Fragile

**File**: `PageContextBuilder.swift` (line 30)

The regex `(?i)(password|secret|bearer|auth_token)[:=]\s*[^\s]+` only redacts values immediately following the keyword with no whitespace. It would miss `"password" : "abc123"` (space before colon) or HTML attributes like `value="abc123"` in a password input. The DOM extraction (in `PageExtractor`) may capture form field values directly.

**Recommendation**: Use a deny-list approach — strip all `<input type="password">` values at the DOM extraction stage, before text is extracted.

---

### P2-2: `PermissionManager` Is Never Connected as `WKUIDelegate`

**File**: `PermissionManager.swift`, `Tab.swift`

Even though `PermissionManager` conforms to `WKUIDelegate`, it is never assigned as `webView.uiDelegate`. The auto-grant bug in P0-3 is therefore also a dead code bug — the handler doesn't fire because the delegate isn't connected. Webcam/microphone prompts fall through to WebKit's default behavior (which may deny or prompt natively).

---

### P2-3: `BackupManager` Exports AI Memories in Plaintext

**File**: `BackupManager.swift`

The backup includes `[PersonalMemory]` objects which store user preferences, research topics, and writing styles. These are exported as plaintext JSON. Users may include sensitive topics in memories. The backup should either be encrypted or clearly warn users that memory data is included.

---

### P2-4: Unbounded `recentlyClosedTabs` Stack

**File**: `TabManager.swift` (line 28)

`recentlyClosedTabs` is a `[URL]` array that grows without bound. After closing 1,000 tabs in a session, this array holds 1,000 URLs in memory forever. There is no cap, no expiry, and no persistence.

**Fix**: Cap at 50 entries.

---

### P2-5: `HistoryStore` Has No Pagination or Count Limit

**File**: `HistoryStore.swift`

History is stored as a flat JSON array loaded entirely into memory on startup. After a year of daily use, this file could contain 50,000+ entries and become a noticeable memory and startup overhead. There is no `maxHistoryCount` limit, no expiry, and no pagination.

**Fix**: Cap at 10,000 entries. Add `clearOlderThan(days:)` method.

---

### P2-6: `SafeJSONDecoder` Corrupted File Naming Collision

**File**: `SafeJSONDecoder.swift` (line 16)

Corrupted files are renamed to `filename.corrupted_<timestamp>.json` using `Int(Date().timeIntervalSince1970)` — second-level precision. If two files corrupt in the same second (plausible on a crash mid-batch-write), the second rename will fail silently because the destination already exists. This leaves the original file un-renamed and the fallback behavior still works, but corrupted diagnostics are lost.

---

### P2-7: `AIPrivacyManager` Has Three Modes But Only Two Are Meaningful

**File**: `AIPrivacyManager.swift`

The `privacyMode` has three states: `askBeforeSending`, `alwaysSend`, and `neverSend`. However, the `askBeforeSending` mode never actually shows a prompt — it behaves identically to `alwaysSend`. The mode name implies user confirmation before sending page context to AI, but no such confirmation UI exists.

---

## Recommended Enhancements (P3)

- **P3-1**: Add `WKContentRuleList` to block tracker scripts and ads natively
- **P3-2**: Implement real search suggestion fetch (DuckDuckGo or Startpage Instant Answers API) in `OmniBoxManager`
- **P3-3**: Add macOS Handoff / Continuity support for cross-device tab pickup
- **P3-4**: Implement bookmark import from Safari/Chrome (NETSCAPE HTML format)
- **P3-5**: Add HTTPS upgrade enforcement (block `http://` downgrades)
- **P3-6**: Implement tab groups with visual separators in the tab bar
- **P3-7**: Add keyboard shortcut for closing all tabs to the right
- **P3-8**: Implement pinned tab persistence across sessions

---

## Architecture Review

### What Is Working Well

The layered MVVM hierarchy is sound:
- `ContentView` (UI) → `BrowserViewModel` (ViewModel) → `TabManager` / `ProfileManager` / `SessionManager` (Core Services) → `HoloWebView` (WebKit)
- `@MainActor` isolation is consistently applied across all managers and ViewModels
- KVO bindings via Combine publishers are the correct pattern for observing WKWebView state
- Profile/tab/session data isolation is architecturally correct (the data store hookup is just missing at the creation site)
- `SafeJSONDecoder` is a good pattern; it just needs to be used consistently

### Architectural Weaknesses

1. **Duplicate state between `Tab` and `BrowserViewModel`**: Both hold `url`, `title`, `isLoading`, `progress`, `canGoBack`, `canGoForward`, `errorMessage`. This is 7 `@Published` properties duplicated with Combine pipes between them. When the active tab changes, there is a brief flash where `BrowserViewModel` shows stale state. A cleaner approach is for the view to bind to `viewModel.tabManager.activeTab` directly.

2. **`BrowserViewModel` owns `readingListManager` and `bookmarkManager` but `ContentView` owns `historyStore` and `bookmarkStore` separately**: There are two `BookmarkManager`/`BookmarkStore` instances in the app — `BrowserViewModel.bookmarkManager` (in ViewModel layer) and `ContentView`'s `@StateObject private var bookmarkStore = BookmarkStore()`. These write to different data sinks. This is a data coherence bug.

3. **No dependency injection container**: Every manager creates its own file paths and dependencies. There is no shared configuration or container, making testing impossible and making it hard to substitute mock implementations.

4. **`WorkflowExecutor` creates a second `BrowserActionExecutor` independently** of the one owned by `AIActionManager` — duplicate executor instances with no shared state.

---

## Security Findings

| Finding | Severity | Status |
|---|---|---|
| Media camera/mic auto-granted to all sites | CRITICAL | P0-3 above |
| NavigationDelegate not assigned — security callbacks miss | CRITICAL | P0-4 above |
| Script message handler retain cycle | CRITICAL | P0-5 above |
| Profile cookies not isolated | HIGH | P1-1 above |
| No Touch ID gate on password retrieval | HIGH | P1-6 above |
| AI safe-plans execute without user notification | HIGH | P1-7 above |
| `askBeforeSending` mode never shows confirmation | MEDIUM | P2-7 |
| Backup exports memories as plaintext | MEDIUM | P2-3 |
| `MemoryPrivacyManager` regex misses many token formats | MEDIUM | P2-1 |

**Verified safe**:
- ✅ `PasswordCredential.swift` — no plaintext passwords in the struct, only metadata
- ✅ `SessionManager` — `isPrivate` sessions are correctly blocked from persistence
- ✅ `BrowserActionExecutor` — `submitForm`, `purchaseProduct`, `modifyAccount` are correctly blocked
- ✅ `KeychainManager` — proper `SecItemAdd`/`SecItemCopyMatching` usage, no UserDefaults or disk fallback

---

## Performance Findings

### Claimed vs. Verified Benchmarks

The Phase 9 report claims **142ms cold launch** and **54.2MB idle RAM**. These numbers **cannot be independently verified** from source code inspection alone, and they are suspicious for the following reasons:

- `ContentView` instantiates 14 `@StateObject` managers on launch. Each manager performs a synchronous file read in `init()`. With 9+ JSON files being read synchronously in the main thread init chain, sub-150ms launch on a clean install with empty files is plausible — but will grow as data accumulates.
- On a machine with 10,000 history entries, `HistoryStore.load()` on the main thread during launch could easily add 50-100ms.

### Verified Performance Risks

1. **Main-thread JSON writes on every navigation** (P1-4): Every URL load triggers `autoSaveSession()` → full JSON encode + disk write on main thread.
2. **Unbounded history growth** (P2-5): No cap on history entries; memory footprint grows linearly with usage.
3. **14 `@StateObject` init** in `ContentView`: Each performs synchronous I/O in `init()`. Total launch I/O depends on file sizes.
4. **`OmniBoxManager` O(N) linear scan**: With 10,000 history items, every keystroke in the address bar triggers a full linear scan. Acceptable now but will degrade.
5. **Tab suspension threshold of 4 background tabs**: `suspendInactiveTabs(maxActiveBackground: 4)` is hardcoded. Users who regularly work with 20+ tabs will hit suspension constantly, causing jarring reloads.

---

## Release Engineering Review

### Code Signing / Entitlements
No `.entitlements` file was found in the source tree. The `scripts/` directory contains signing scripts referencing entitlement files, but the actual entitlement configuration cannot be independently verified from source.

### Sparkle Update Manager
`UpdateManager.swift` exists as a framework stub that provides version information. No actual Sparkle integration code was found — no `SPUStandardUpdaterController`, no appcast URL configuration, no Ed25519 key integration. The update system is a placeholder.

### Crash Reporter
`CrashReporter.swift` exists but its actual implementation was not reviewed in this pass. The framework is architecturally present.

---

## Daily Driver Evaluation

### Would This Replace Safari / Arc / Chrome Today?

**No.** Not because the architecture is broken, but because several critical features are missing or non-functional:

| Feature | Status |
|---|---|
| Real AI responses | ❌ Mock only |
| Camera/mic permission prompts | ❌ Auto-granted |
| WebContent crash recovery | ❌ Never triggered |
| Profile cookie isolation | ❌ Not wired |
| Tab group persistence | ❌ Missing |
| Search suggestions in address bar | ❌ OmniBoxManager unused |
| Bookmark import (Safari/Chrome) | ❌ Missing |
| Auto-updates (Sparkle) | ❌ Placeholder |
| Extensions (WebExtensions) | ❓ Framework exists, real execution unverified |
| Password autofill | ❓ Detection works; autofill not verified |

**What works genuinely well**: tab management, Liquid Glass UI, session restore, keyboard shortcuts, private browsing isolation at the session-save layer, Keychain password storage.

---

## Final Recommendation

**B) Ready for personal daily driver use by the developer, but requires the P0 and P1 fixes before broader use.**

Specifically:
- The architecture is clean and professionally structured for a one-person project
- The security foundations (Keychain, private session blocking, action blocking) are correctly designed
- The actual WebKit integration has significant gaps (delegate never assigned, crash recovery never wired) that must be fixed
- The AI system is entirely mock-based and should be clearly communicated to any beta tester
- The camera/mic auto-grant is a **showstopper** for any public release

With the P0 fixes (4–6 days of work), this becomes a genuinely usable personal browser. With P1 fixes, it could enter a real beta program.

---

## Appendix: Files Reviewed

```
HoloBrowser/Sources/Engine/HoloWebView.swift
HoloBrowser/Sources/Engine/WKWebViewWrapper.swift
HoloBrowser/Sources/Engine/DownloadManager.swift
HoloBrowser/Sources/Tabs/Tab.swift
HoloBrowser/Sources/Tabs/TabManager.swift
HoloBrowser/Sources/Navigation/NavigationManager.swift
HoloBrowser/Sources/ViewModels/BrowserViewModel.swift
HoloBrowser/Sources/Security/KeychainManager.swift
HoloBrowser/Sources/Security/PasswordManager.swift
HoloBrowser/Sources/Security/PasswordCredential.swift
HoloBrowser/Sources/Security/PermissionManager.swift
HoloBrowser/Sources/Privacy/AIPrivacyManager.swift
HoloBrowser/Sources/AI/AIManager.swift
HoloBrowser/Sources/AI/AIProvider.swift
HoloBrowser/Sources/AI/AIContextBuilder.swift
HoloBrowser/Sources/AI/AIProviderProtocol.swift
HoloBrowser/Sources/AI/Actions/AIActionManager.swift
HoloBrowser/Sources/AI/Personalization/PersonalMemory.swift
HoloBrowser/Sources/AI/Personalization/MemoryPrivacyManager.swift
HoloBrowser/Sources/AI/LocalAI/LocalInferenceEngine.swift
HoloBrowser/Sources/Core/Automation/BrowserActionExecutor.swift
HoloBrowser/Sources/Core/BackupManager.swift
HoloBrowser/Sources/Core/OmniBoxManager.swift
HoloBrowser/Sources/Core/ReliabilityManager.swift
HoloBrowser/Sources/Content/PageContextBuilder.swift
HoloBrowser/Sources/Sessions/SessionManager.swift
HoloBrowser/Sources/Profiles/ProfileManager.swift
HoloBrowser/Sources/Storage/HistoryStore.swift
HoloBrowser/Sources/Storage/SafeJSONDecoder.swift
HoloBrowser/Sources/Bookmarks/BookmarkManager.swift
HoloBrowser/Sources/Workflows/WorkflowExecutor.swift
HoloBrowser/Sources/App/HoloBrowserApp.swift
HoloBrowser/Sources/UI/Window/ContentView.swift
```
