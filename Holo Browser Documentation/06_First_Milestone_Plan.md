# Holo Browser: Milestone 1 Detailed Implementation Plan

> **Document Status**: Complete / Source of Truth  
> **Milestone Goal**: Build a real, working, single-window native macOS web browser.  
> **Strict Focus**: Foundation ONLY. Zero tabs, zero AI, zero complex glass shaders, zero workspaces.  
> **Target Platform**: macOS 14.0+ / 15.0+  

---

## 1. Milestone Objective & Scope

The objective of Milestone 1 is to establish a rock-solid, production-grade native browser core using **Swift, SwiftUI, AppKit, and WKWebView**. 

At the conclusion of Milestone 1, the user must be able to launch Holo Browser, type any valid URL into a native address bar, press `Enter`, view the real rendered web page, and navigate forward, backward, or reload the page with complete stability and progress feedback.

---

## 2. File Creation List for Milestone 1

The implementing developer/agent MUST create exactly these 8 core files within the designated folder paths:

```
HoloBrowser/
├── App/
│   ├── HoloBrowserApp.swift            # 1. Main SwiftUI App entry point
│   └── AppDelegate.swift               # 2. NSApplicationDelegate lifecycle handler
├── Engine/
│   ├── HoloWebView.swift               # 3. WKWebView subclass & configuration pool
│   └── WKWebViewWrapper.swift          # 4. NSViewRepresentable bridge to SwiftUI
├── Navigation/
│   └── NavigationManager.swift         # 5. Core navigation state machine
├── ViewModels/
│   └── BrowserViewModel.swift          # 6. Main window state & reactive bindings
└── UI/
    ├── Chrome/
    │   ├── AddressBarView.swift        # 7. Native text field & URL submission
    │   └── NavigationToolbarView.swift # 8. Toolbar with Back/Forward/Reload buttons
```

---

## 3. Step-by-Step Implementation Protocol

### Step 1: Create clean Xcode Project
* Target: macOS Application (App bundle).
* Technology: Interface = SwiftUI, Language = Swift.
* Deployment Target: macOS 14.0 (Sonoma) minimum.
* Sandboxing & Entitlements: Enable **Outgoing Network Connections (Client)** in `HoloBrowser.entitlements` to allow HTTP/HTTPS web traffic.

### Step 2: Configure WKWebView Core (`HoloWebView.swift`)
* Create `HoloWebView` as a subclass of `WKWebView`.
* Instantiate shared `WKWebViewConfiguration` with default non-persistent or persistent `WKWebsiteDataStore`.
* Implement `WKNavigationDelegate` to observe:
  * `didStartProvisionalNavigation`
  * `didCommit`
  * `didFinish`
  * `didFail` / `didFailProvisionalNavigation`

### Step 3: Construct SwiftUI Web Bridge (`WKWebViewWrapper.swift`)
* Conform to `NSViewRepresentable`.
* Implement `makeNSView(context:)` returning the `HoloWebView` instance.
* Implement `updateNSView(_ nsView:context:)` binding navigation actions triggered by `BrowserViewModel`.

### Step 4: Build Navigation State Machine (`NavigationManager.swift`)
* Maintain active `URL`, `canGoBack: Bool`, `canGoForward: Bool`, `isLoading: Bool`, and `estimatedProgress: Double`.
* Implement methods:
  * `load(urlString: String)`
  * `goBack()`
  * `goForward()`
  * `reload()`
  * `stopLoading()`

### Step 5: Implement URL Sanitizer & Address Bar (`AddressBarView.swift`)
* Implement smart URL input parsing:
  * `apple.com` → `https://apple.com`
  * `https://google.com` → `https://google.com`
  * `swift concurrency tutorial` → `https://www.google.com/search?q=swift+concurrency+tutorial`
* Provide an interactive `TextField` with active focus, select-all on focus, and `Enter` key execution.

### Step 6: Assemble Navigation Toolbar & Main Window (`NavigationToolbarView.swift`)
* Create horizontal toolbar containing:
  * Back Button (`◄` / `chevron.left`) — Disabled when `canGoBack == false`.
  * Forward Button (`►` / `chevron.right`) — Disabled when `canGoForward == false`.
  * Reload Button (`↻` / `arrow.clockwise`) — Switches to Stop (`✕`) while `isLoading == true`.
  * AddressBarView filling remaining window width.
  * Linear progress indicator bound to `estimatedProgress`.

### Step 7: Wire Main Browser Window (`HoloBrowserApp.swift` / `ContentView.swift`)
* Stack `NavigationToolbarView` vertically on top of `WKWebViewWrapper`.
* Ensure flexible frame sizing allowing full native window drag and resize.

---

## 4. Milestone 1 Verification & Testing Checklist

Before completing Milestone 1, run these explicit test verifications:

```
[ ] Verification 1: Build & Execution
    - Project compiles cleanly with ZERO warnings.
    - Application cold launches in < 500ms.

[ ] Verification 2: Page Loading & Web Compliance
    - Navigate to "https://apple.com" -> Renders full CSS, images, and interactive web elements.
    - Navigate to "https://wikipedia.org" -> Renders layout accurately.
    - Navigate to "https://fast.com" -> Executes JavaScript speed test accurately.

[ ] Verification 3: URL Handling & Search Fallback
    - Input "example.com" -> Auto-prepends "https://" and loads site.
    - Input "what is the capital of France" -> Redirects to default search engine.

[ ] Verification 4: Navigation Control Dynamics
    - Click link on page -> Back button enables (`canGoBack == true`).
    - Click Back button -> Returns to previous page; Forward button enables (`canGoForward == true`).
    - Click Forward button -> Re-navigates to original page.
    - Click Reload button -> Re-fetches active URL payload.

[ ] Verification 5: Error Resilience
    - Input invalid domain "https://thisdomaindoesnotexist12345.org" -> Displays clean error UI without host app crash.
    - Turn off WiFi while loading -> Catches network error cleanly.
```

---

## 5. STRICT PROHIBITION LIST FOR MILESTONE 1

To guarantee rapid execution and bulletproof stability, the developer/agent **MUST NOT** include any of the following in Milestone 1:

❌ **NO Multi-Tab functionality or tab bar UI.**  
❌ **NO Liquid glass shaders or complex material customization.**  
❌ **NO AI Panel, summaries, or LLM integrations.**  
❌ **NO Workspaces or multi-profile isolated data stores.**  
❌ **NO Bookmarks bar or browsing history databases.**  
❌ **NO Extension support or custom script injection.**
