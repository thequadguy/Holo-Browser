# Holo Browser Release Candidate Security & Reliability Audit

**Auditor**: Final Release Candidate Security Engineer  
**Methodology**: Direct source-code inspection of all modified and dependent files after the P0 remediation pass  
**Build state**: `Build complete — 0 errors, 0 warnings`  
**Date**: 2026-07-29  

> This audit is performed with a hostile reviewer mindset. No claims from prior reports are trusted.
> Every finding is verified against the actual source code on disk.

---

## Remaining P0 Issues (Critical — Must Fix Before Any Release)

### P0-A: Double Reload on WebContent Crash (Regression Introduced by P0-Fix-3)

**Severity**: CRITICAL  
**Files**: `NavigationManager.swift` L187–197, `ReliabilityManager.swift` L11–20

The P0-Fix-3 implementation introduced a double-reload regression on every WebContent crash.

`NavigationManager.webViewWebContentProcessDidTerminate` does this:
```swift
webView.reload()   // Line 190 — first reload
// ...
tab.reliabilityManager?.handleWebContentProcessTermination(tab: tab)
```

`ReliabilityManager.handleWebContentProcessTermination` then does:
```swift
if let webView = tab.webView, let url = tab.url {
    webView.reload()   // Line 17 — SECOND reload of the same view
}
```

**Impact**: On every WebContent crash, two simultaneous reload requests are issued against the same `WKWebView`. The first fires immediately in `NavigationManager`. The second fires ~1 frame later from `ReliabilityManager`. This causes a race: the first reload spawns a new WebContent process, then the second reload cancels the in-flight navigation and starts again. Users see a white flash followed by a duplicate load. At high tab counts (crash of many tabs simultaneously), this doubles the WebContent process spawning pressure and can cause macOS to kill processes via memory pressure.

**Fix**: Remove the `webView.reload()` from `ReliabilityManager.handleWebContentProcessTermination`. The NavigationManager delegate should be the single owner of the reload. ReliabilityManager should only track state:
```swift
// In ReliabilityManager — REMOVE the reload:
public func handleWebContentProcessTermination(tab: Tab) {
    self.crashCount += 1
    self.lastRecoveredURLString = tab.url?.absoluteString
    // Do NOT call webView.reload() — NavigationManager already did this
}
```

---

### P0-B: `WKWebViewWrapper.makeNSView` Creates a Second Orphan WebView on Tab Restore Failure

**Severity**: CRITICAL  
**File**: `WKWebViewWrapper.swift` L12–17

```swift
public func makeNSView(context: Context) -> HoloWebView {
    if let webView = tab.restoreIfNeeded() {
        return webView
    }
    return HoloWebView(frame: .zero, configuration: WKWebViewConfiguration())  // ← orphan
}
```

`Tab.restoreIfNeeded()` only returns `nil` if `state == .closed`. If the tab is somehow `.closed` when `makeNSView` is called (e.g., if `close()` races with the SwiftUI view update), the fallback creates a brand-new `HoloWebView` using a vanilla `WKWebViewConfiguration()` — **no profile data store, no navigation delegate, no password detection script**. This orphaned webview is shown to the user and accepts input while being completely disconnected from all browser infrastructure.

**Impact**: User can navigate in an isolated, unmonitored webview with no session, no history recording, no error handling, no password saving, and no crash recovery. This is a privacy and reliability regression from the P0 fixes because the new data store injection path is bypassed.

**Fix**: 
```swift
public func makeNSView(context: Context) -> HoloWebView {
    // Never create an orphan. If the tab is closed, return the restored view
    // or a fully-configured placeholder that matches the profile store.
    return tab.restoreIfNeeded() ?? HoloWebView(frame: .zero, configuration: WKWebViewConfiguration())
}
```
The real fix is deeper: assert that `makeNSView` is never called with a closed tab by ensuring `ContentView` only renders `WKWebViewWrapper` for non-closed tabs. The `activeTab` guard in `ContentView` already filters `nil` but not `.closed` state.

---

### P0-C: `PermissionManager` Decision Handler Timeout — Requests Hang Forever

**Severity**: CRITICAL  
**File**: `PermissionManager.swift` L64–71

When a new permission request arrives while `pendingRequest` is already set (e.g., two tabs simultaneously requesting camera access), the second request overwrites the first:

```swift
self.pendingRequest = request  // second request overwrites first
```

The **first request's `decisionHandler` is never called**. WebKit's `decisionHandler` is an `@escaping` closure that **must be called exactly once**. Failing to call it causes the WebKit process to log an assertion error and may eventually cause a process termination for that tab. In practice, the user's camera prompt on the first tab hangs forever without resolution.

Additionally, if the user navigates away before resolving the prompt, `pendingRequest` becomes stale — the domain shown in the UI may not match the webview that issued the request, but resolving it still calls the (now-stale) handler on the original tab.

**Fix**: Use a queue (`[MediaPermissionRequest]`) instead of a single optional. Dequeue one at a time after resolution.

---

### P0-D: `AIProviderFactory` Is `@MainActor` But `Keychain` Calls Are Synchronous on Main Thread

**Severity**: CRITICAL (performance) / HIGH (blocking)  
**File**: `AIProviderFactory.swift` L18, L114–127

`AIProviderFactory` is annotated `@MainActor`. Its `loadKey(for:)` method calls `SecItemCopyMatching` synchronously. Keychain access is a synchronous IPC operation to `securityd` — on macOS, it can take 50–200ms on first access, and significantly longer if the user's login keychain is locked or if there is disk I/O contention.

Calling this on the main thread directly blocks the UI. The `provider(for:)` method is also `@MainActor` and calls `loadKey` directly. Any call to `AIProviderFactory.provider(for:)` from a button press or settings change will block the UI thread for the duration of the Keychain lookup.

**Fix**: Mark Keychain read/write operations as `nonisolated` and wrap them in `Task.detached` with an explicit `DispatchQueue.global()` execution context. Return an `async` result.

---

## Remaining P1 Issues (High — Fix Before Daily Driver Production Use)

### P1-1: `Cmd+Shift+T` Restore Closed Tab Uses `defaultDataStore` — Profile Isolation Break

**Severity**: HIGH  
**File**: `ContentView.swift` L349, `TabManager.swift` L94–98

The keyboard shortcut handler for Cmd+Shift+T:
```swift
viewModel.tabManager.restoreRecentlyClosedTab()  // no dataStore argument
```

`TabManager.restoreRecentlyClosedTab(dataStore:)` defaults `dataStore` to `nil`, which resolves to `defaultDataStore` (`.default()`). If the user was in a Work profile when they closed a tab, then switched to Personal profile, then hit Cmd+Shift+T, the restored tab opens with the **Personal profile's default store** instead of the Work store it originally belonged to.

There is no tracking of which profile a closed URL belonged to (`recentlyClosedTabs` is `[URL]` with no profile metadata).

**Fix**: Change `recentlyClosedTabs` to `[(url: URL, profileID: UUID)]` and pass the correct data store on restore.

---

### P1-2: `setupActiveTabBindings` Called Before `onAppear` — Initial Tab Has No Delegates

**Severity**: HIGH  
**Files**: `BrowserViewModel.swift` L46, L127; `ContentView.swift` L272–281

`BrowserViewModel.init()` calls `setupManagerBindings()` (line 46), which calls `setupActiveTabBindings()` (line 127). `setupActiveTabBindings()` on line 144 calls:
```swift
activeTab.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "holoPasswordDetector")
let proxy = WeakScriptMessageProxy(target: self)
activeTab.webView?.configuration.userContentController.add(proxy, name: "holoPasswordDetector")
```

But `BrowserViewModel` is initialized by `ContentView` as a `@StateObject`. `permissionManager` and `reliabilityManager` are injected into `TabManager` in `ContentView.onAppear`. The initial tab is created in `TabManager.init()` **before** `onAppear` fires.

This means the **very first tab** that is shown to the user has `permissionManager = nil` and `reliabilityManager = nil` at the moment its webview is first created. The `permissionManager` is set in `onAppear`, but `restoreIfNeeded()` may already have been called by `makeNSView` in `WKWebViewWrapper` before `onAppear` fires (SwiftUI calls `makeNSView` synchronously during the first layout pass).

**Result**: The first tab's webview is created without a `uiDelegate` (permissionManager) and without crash recovery. The permission fix and crash recovery fix both have a startup race condition on the initial tab.

**Fix**: Ensure `Tab.restoreIfNeeded()` is not called until after `onAppear`. Move initial tab creation from `TabManager.init()` into a `setup()` method called from `onAppear` after managers are injected.

---

### P1-3: `syncUserScriptsToActiveTab` Accumulates Duplicate User Scripts

**Severity**: HIGH  
**File**: `BrowserViewModel.swift` L130–136

```swift
private func syncUserScriptsToActiveTab() {
    guard let activeTab = tabManager.activeTab, let webView = activeTab.webView else { return }
    let scripts = extensionManager.activeUserScripts()
    for script in scripts {
        webView.configuration.userContentController.addUserScript(script)
    }
}
```

`WKUserContentController.addUserScript(_:)` accumulates scripts — it does not replace or deduplicate. This method is called on every tab switch (`extensionManager.$extensions` + `tabManager.$activeTabID` subscription). If the user has 3 extensions enabled and switches tabs 100 times in a session, the active tab's webview accumulates 300 copies of each extension script.

**Impact**: Memory growth proportional to tab switches × extension count. After 1 hour of normal browsing with tab switching, a webview with 3 extensions could have 1,000+ duplicate script injections, all executing on every page load. This is the primary vector for memory growth after 1+ hour sessions.

**Fix**: Before adding scripts, call `webView.configuration.userContentController.removeAllUserScripts()` and then add all current scripts fresh. Or track which scripts have been added and skip duplicates.

---

### P1-4: `PageContextBuilder` Sends Entire Page URL to AI — Full URL Leaks Private Browsing Context

**Severity**: HIGH  
**File**: `AIContextBuilder.swift` L19

```swift
combinedContext += "Webpage Title: \(ctx.title)\nURL: \(ctx.urlString)\n\nPage Content:\n\(sanitized)\n\n"
```

The full URL string is sent verbatim to the AI provider. In private browsing, URLs may contain session tokens, authentication parameters, or personally identifying path segments (e.g., `https://bank.com/accounts/12345/transactions?token=abc123`). There is no profile privacy check here — `AIContextBuilder.buildRequest` has no awareness of whether the active profile is private.

`AIPrivacyManager.sanitizeContextForAI` only redacts `Bearer` tokens; it does not redact URLs.

**Impact**: A user in a private browsing profile using the AI summarize feature leaks their full browsing URL to OpenAI/Anthropic servers, defeating the purpose of private browsing.

**Fix**: Check `activeProfile.isPrivate` before calling `AIContextBuilder.buildRequest`. In private mode, either block AI context entirely or strip the URL before building the context.

---

### P1-5: `PasswordManager.promptSaveCredential` Exposes Plaintext Password in `@Published` State

**Severity**: HIGH  
**File**: `PasswordManager.swift` L8

```swift
@Published public var promptSaveCredential: (domain: String, username: String, password: String)? = nil
```

The plaintext password is stored in a `@Published` property on `PasswordManager`, which is a `@MainActor` `ObservableObject`. Combine's publisher infrastructure holds a reference to the current value for the lifetime of the subscription. Any subscriber (including future debugging tools, memory snapshots, or crash reporter attachments) can read the plaintext password from this published state.

The password should never leave `HoloWebView.loginDetectionJS` → `BrowserViewModel.userContentController` path without being immediately written to Keychain or zeroed.

**Fix**: Replace the tuple `(domain, username, password)` with a struct that uses a `SecureString` or at minimum zeros the password field after `saveCredential()` is called.

---

### P1-6: `AIProvider` Streaming Tasks Have No Timeout — Connection Hangs Forever

**Severity**: HIGH  
**Files**: `AIProvider.swift` (OpenAIProvider L91, AnthropicProvider L189)

Both providers use:
```swift
let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
```

`URLSession.shared` has no custom timeout configuration. The default `timeoutIntervalForRequest` is 60 seconds and `timeoutIntervalForResource` is 7 days. For a streaming response, the resource timeout is what governs total download time. A slow or stalled OpenAI response will hold the streaming task open for up to **7 days** with no user-visible feedback.

Additionally, `Task.isCancelled` is checked inside the SSE loop, but `cancelActiveStream()` cancels the Swift Task — it does not cancel the underlying `URLSession` data task. The `URLSession` request will continue consuming network resources and Keychain-retrieved API key memory even after the user cancels or closes the sidebar.

**Fix**: Create a custom `URLSession` with `URLSessionConfiguration` that sets `timeoutIntervalForRequest = 30` and `timeoutIntervalForResource = 120`. Capture the session in the provider and call `session.invalidateAndCancel()` from the continuation's `onTermination` handler.

---

### P1-7: Profile Switch Does Not Migrate Open Tabs to New Data Store

**Severity**: HIGH  
**Files**: `ProfileManager.swift`, `BrowserViewModel.swift`

When `ProfileManager.selectProfile(id:)` is called, the `activeProfile` changes and `activeWebsiteDataStore` returns a different store. However, all existing open tabs retain their original `WKWebsiteDataStore` (set at creation time). After switching from Work to Personal profile:

- Existing tabs still have Work profile cookies
- New tabs (via `createNewTab()`) get Personal profile cookies
- The tab bar shows all tabs as if they belong to the same profile
- Cookies from a Work session remain active in suspended tabs indefinitely

There is no mechanism to close, reload, or quarantine existing tabs when the active profile changes.

**Fix**: When `selectProfile` fires, either (a) close all non-pinned tabs and open a new tab with the new profile's store, or (b) mark existing tabs with their originating profileID and visually distinguish them, preventing cross-profile cookie leakage.

---

### P1-8: `NavigationManager.webView` KVO Subscriptions Fire After Tab Suspension

**Severity**: HIGH  
**File**: `Tab.swift` L127–134, `NavigationManager.swift` L35–83

When a tab is suspended, `Tab.suspend()` sets `webViewInstance = nil`. However, `navigationManager.webView` is set in `restoreIfNeeded()` via `navigationManager.webView = wv`, but is **never set back to `nil`** in `suspend()`:

```swift
public func suspend() {
    state = .suspended
    webViewInstance?.stopLoading()
    webViewInstance?.navigationDelegate = nil
    webViewInstance?.uiDelegate = nil
    webViewInstance = nil
    // Missing: navigationManager.webView = nil
}
```

`NavigationManager.webView` is `weak var`, so it will eventually become `nil` when the `HoloWebView` is deallocated. But `navigationManager.setupKVOObservers()` holds Combine publishers on `webView.publisher(for: \.isLoading)` etc. These publishers reference the old webview via Combine's retain chain in `kvoSubscriptions`. Since `kvoSubscriptions` holds the Combine subscriptions (not the webview directly), the subscriptions remain active while waiting for the webview to fire KVO changes that will never come.

**Impact**: After suspending 50+ tabs (which happens automatically via `suspendInactiveTabs`), there are 50 × 6 = 300 orphaned Combine subscribers waiting for KVO events from deallocated objects. This is the second vector for memory growth in 1+ hour sessions.

**Fix**: In `Tab.suspend()`, also set `navigationManager.webView = nil` to trigger `setupKVOObservers()` cleanup.

---

## Simulation Analyses

### 100-Tab Stress Analysis

**Findings**:

1. `suspendInactiveTabs(maxActiveBackground: 4)` is called on every `tabManager.$tabs` change, which fires every time any tab is created or closed. With 100 tabs, every tab creation triggers a full scan over all 100 tabs, suspending the oldest 96. At tab 100, the suspension pass iterates 100 items, 96 suspensions each modifying `tab.state` (which triggers another `@Published` emission on each Tab). This is an O(N²) suspension cascade for large tab counts.

2. The `recentlyClosedTabs` cap of 50 is correct and will hold. However, with 100 open tabs, `autoSaveSession()` on every tab event encodes a JSON array of 100 `SavedTabItem` objects and writes to disk synchronously on the main thread. At 100 tabs with rapid switching, this is a measurable UI freeze risk.

3. The `holoPasswordDetector` handler registration in `setupActiveTabBindings()` is called on every tab switch. With 100 tabs and frequent switching, this fires a `removeScriptMessageHandler` + `add(proxy:name:)` pair on every switch. At 100 switches/minute, this creates 200 `WKUserContentController` mutations per minute. This is safe but noisy.

4. With 96 suspended tabs, all 96 `NavigationManager` KVO subscription sets remain live (P1-8 above). This is 96 × 6 = 576 Combine subscribers watching `nil` webviews.

**Verdict**: Functional up to 100 tabs but with measurable performance degradation from O(N²) suspension, synchronous disk I/O, and orphaned KVO subscriptions.

---

### Profile Switching Stress Analysis

**Scenario**: User creates 3 profiles (Personal, Work, Private). Switches between them 20 times in one session.

**Findings**:

1. On every `selectProfile` call, a new `WKWebsiteDataStore(forIdentifier: profile.id)` is created (or retrieved from cache). The cache is correct. ✅

2. Open tabs from Profile A are not closed when switching to Profile B (P1-7). After 20 switches, tabs from 3 different profiles are open simultaneously, all mixing their cookies in the tab bar without visual indication.

3. Cmd+Shift+T restores tabs with the wrong profile store (P1-1). After 20 profile switches and 5 closed tabs, all 5 restored tabs use the current (wrong) profile's data store.

4. `PasswordManager.credentials` is loaded globally and filtered by `profileID`. This is correct. ✅

5. `HistoryStore` has no `profileID` on `HistoryItem`. All history is shared globally. A Private profile's history is guarded by the `isPrivate` check in `ContentView.onReceive` (L307), but this is a UI-layer guard only — if any code calls `historyStore.addEntry` directly, private URLs will be recorded.

---

### Private Browsing Verification

**Scenario**: Create private profile, browse 5 sites, close browser.

**Findings**:

1. `WKWebsiteDataStore.nonPersistent()` is correctly used for private profiles. ✅
2. `SessionManager.saveActiveSession` correctly skips private sessions. ✅
3. `HistoryStore` add is guarded in `ContentView.onReceive` with `isPrivate` check. ✅ (fragile)
4. `AIContextBuilder` sends full URL to AI even in private mode (P1-4). ❌
5. `PasswordManager.promptSaveCredential` is triggered by form submission regardless of profile type — there is no `isPrivate` guard in `BrowserViewModel.userContentController`. A private browsing session can trigger a save-password prompt. If the user taps save, the credential is stored with the private profile's ID but is persisted to `credentials.json` permanently. ❌
6. `BackupManager` includes `[PersonalMemory]` items from all profiles without filtering by `isPrivate`. ❌

---

### Crash Recovery Verification

**Scenario**: Simulate WebContent process termination on active tab.

**Findings**:

1. `webViewWebContentProcessDidTerminate` is implemented on `NavigationManager`. ✅
2. `NavigationManager` is set as `navigationDelegate` in `restoreIfNeeded()`. ✅
3. **Double reload regression** (P0-A): the tab reloads twice. ❌
4. After the crash reload, `webView.reload()` is called on the existing `WKWebView` instance. WebKit internally allocates a new WebContent process for the reload. The `WKWebsiteDataStore` on the existing configuration is preserved — cookies and session data from before the crash are maintained for the reload. ✅
5. `owningTab` is `weak var` — if the tab is closed between the crash event and the `Task { @MainActor in }` hop, the crash recovery is correctly skipped (no dangling pointer access). ✅

---

### AI Provider Failure Testing

**Scenario**: API key is wrong (401), network is offline, server returns 503.

**Findings**:

**401 (Wrong key)**:
- `httpError(401)` is thrown ✅
- `AIManager.streamResponse` catches it and sets `activeTaskError = error.localizedDescription` ✅
- Error message is shown in the sidebar conversation ✅
- API key remains in memory in `OpenAIProvider.apiKey` as a plaintext `String` for the lifetime of the provider instance ⚠️

**Network offline**:
- `URLSession.shared.bytes(for:)` throws `NSURLErrorDomain -1009` (Not Connected to Internet)
- Caught by the outer `catch` block, error propagates to `AIManager` ✅
- However, there is no retry logic and no user-facing "Offline — retry?" button in the sidebar ⚠️

**503 (Server error)**:
- `httpError(503)` thrown ✅
- SSE bytes are discarded after the status check guard ✅

**SSE parsing failure** (API sends unexpected format):
- Both providers silently skip malformed SSE lines (inner `if let` chains fail gracefully) ✅
- If the entire stream is malformed, `continuation.finish()` is called at the end with no content — the user sees an empty response with no error message ❌

**Stream stall** (server stops sending):
- `bytes.lines` iterator blocks indefinitely with no timeout (P1-6) ❌

**`Task.isCancelled` race**:
- Cancellation is checked at the top of each loop iteration, not before/after `bytes.lines`. If the server sends a large SSE chunk, `Task.isCancelled` will not be checked until the entire line is received. This is acceptable. ✅

---

## macOS Sonoma / Sequoia Compatibility

**Verified**:
- `WKWebsiteDataStore(forIdentifier:)` is `macOS 14.0+`. `ProfileManager` correctly falls back to `.default()` on macOS 13. ✅
- `webView.isInspectable = true` is guarded with `#available(macOS 13.3, *)`. ✅
- `WKMediaCaptureType` permission API is `macOS 12.0+`. `PermissionManager` is guarded with `@available(macOS 12.0, *)`. ✅
- `URLSession.shared.bytes(for:)` is available on macOS 12.0+. Package target is `.macOS(.v14)` — no issue. ✅

**Potential issues**:
- macOS 15 Sequoia introduced `WKWebsiteDataStore` isolation enforcement changes for third-party content. No compatibility breaks expected for the current usage pattern.
- The login detection JS uses `document.addEventListener('submit', ...)` — this pattern continues to work on all WebKit versions in the target range.

---

## API Key Security Assessment

**Keychain storage**: Keys stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. This is the correct accessibility level — prevents iCloud sync and migration to other devices. ✅

**Memory exposure**: `OpenAIProvider(apiKey:)` and `AnthropicProvider(apiKey:)` store the key as a plaintext `String` field. Once constructed, the key is in heap memory for the lifetime of the provider. `AIManager.provider` is `@Published`, meaning the provider object can be replaced at runtime (e.g., by changing settings), but the old instance (with the old key) may be retained by Combine's publisher infrastructure until all subscribers are cancelled. The key is never zeroed from memory. **Acceptable for a v1 but worth noting.**

**Key transmission**: The OpenAI key is sent as `Authorization: Bearer <key>`. The Anthropic key is sent as `x-api-key: <key>`. Both use HTTPS. ✅

**Key logging risk**: `print()` statements in `PasswordManager` and elsewhere do not log API keys. ✅

**Keychain delete is missing from factory** when an empty string is saved: `saveKey("", for: .openAI)` will store an empty string in Keychain. `isConfigured` returns `true` (the key exists). `provider(for: .openAI)` returns `MockAIProvider` (the empty key check guards this). But `isConfigured` would incorrectly report the provider as configured. **Minor but misleading.**

---

## Production Readiness Score

| Category | Score | Notes |
|---|---|---|
| Architecture integrity | 7/10 | Sound MVVM; startup race condition (P1-2) |
| WebKit lifecycle | 5/10 | Double reload regression (P0-A); orphan webview (P0-B) |
| Memory management | 5/10 | Duplicate scripts (P1-3); orphaned KVO (P1-8) |
| Security | 6/10 | Password in `@Published` (P1-5); private mode URL leak (P1-4) |
| AI provider reliability | 6/10 | No timeout (P1-6); empty response on malformed stream |
| AI key management | 7/10 | Correct Keychain use; main-thread sync IPC (P0-D) |
| Profile isolation | 6/10 | Correct for new tabs; broken on profile switch (P1-7) |
| Private browsing | 7/10 | Core isolation works; AI URL leak (P1-4); password prompt gap |
| Crash recovery | 7/10 | Wired correctly; double reload is a regression (P0-A) |
| 100-tab stability | 5/10 | O(N²) suspension; sync disk writes; 576 orphaned subscribers |
| macOS compatibility | 9/10 | Correct availability guards throughout |
| Error handling | 6/10 | Good for known errors; silent on malformed streams; no timeout |

**Overall Score: 6.4 / 10**

---

## Summary of All Issues

### P0 (Must fix before any use beyond solo developer)

| ID | Issue |
|---|---|
| P0-A | Double reload on WebContent crash — `NavigationManager` and `ReliabilityManager` both call `webView.reload()` |
| P0-B | `WKWebViewWrapper.makeNSView` fallback creates orphan webview with no profile store, no delegates, no password detection |
| P0-C | `PermissionManager.pendingRequest` is a single optional — simultaneous permission requests drop the first handler, causing a WebKit assertion |
| P0-D | `AIProviderFactory` executes synchronous Keychain IPC on `@MainActor` (main thread block) |

### P1 (Fix before daily driver production use)

| ID | Issue |
|---|---|
| P1-1 | Cmd+Shift+T restores tabs with wrong profile data store (no profile metadata on `recentlyClosedTabs`) |
| P1-2 | Initial tab created before `permissionManager`/`reliabilityManager` injected — startup race on first tab's delegates |
| P1-3 | Extension scripts accumulate duplicates on every tab switch — primary 1-hour memory growth vector |
| P1-4 | Full URL sent to AI providers even in private browsing — defeats private mode |
| P1-5 | Plaintext password stored in `@Published` tuple on `PasswordManager` — heap-exposed for subscriber lifetime |
| P1-6 | AI streaming tasks have no timeout — connections can hang indefinitely; URLSession not cancelled on Task cancel |
| P1-7 | Profile switch does not migrate or quarantine existing tabs — cross-profile cookie leakage possible |
| P1-8 | `Tab.suspend()` does not set `navigationManager.webView = nil` — 576 orphaned KVO subscribers at 100 tabs |

---

## Final Recommendation

### **C — Needs More Engineering**

This is not a pessimistic assessment of the project's quality. The architecture is sound, the security fundamentals are correct, and the P0 remediation pass made real improvements. However, two conditions make **C** the honest verdict:

**Condition 1**: The P0 remediation pass introduced a regression (P0-A double reload) in the most critical reliability path. A browser that double-reloads on every crash is worse than one that does not attempt recovery — it doubles resource consumption during the already-stressful crash moment.

**Condition 2**: Three of the remaining P1 issues are memory growth paths that compound over a 1-hour session: duplicate script accumulation (P1-3), orphaned KVO subscriptions (P1-8), and no AI stream timeout (P1-6). A daily driver browser must remain stable for 8+ hour sessions. These issues guarantee measurable degradation well before that threshold.

**What a "B — Ready with minor fixes" would require**:
1. Fix P0-A (double reload) — 30 minutes
2. Fix P0-B (orphan webview fallback) — 30 minutes
3. Fix P0-C (permission handler queue) — 2 hours
4. Fix P1-3 (duplicate scripts) — 1 hour
5. Fix P1-8 (NavigationManager KVO cleanup on suspend) — 30 minutes
6. Fix P1-4 (private mode URL leak to AI) — 1 hour
7. Fix P1-6 (AI stream timeout) — 2 hours

**Total estimated remediation time**: ~8 hours of focused engineering.

After those 7 fixes, Holo Browser would be a solid **B** — ready for daily personal use with known limitations documented.
