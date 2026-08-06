# Holo Browser: Engineering Testing & QA Strategy

> **Document Status**: Complete / Source of Truth  
> **Testing Pillars**: Unit Testing (XCTest) + Memory Leak Auditing + Performance Benchmarking + XCUITest UI Automation  

---

## 1. Automated Testing Hierarchy

```
                      ┌────────────────────────────────────────┐
                      │        XCUITest End-to-End             │
                      │   (Window, Tabs, Navigation, Sidebar)  │
                      ├────────────────────────────────────────┤
                      │       Performance Benchmarks           │
                      │    (Launch Time, Memory, Frame Rate)   │
                      ├────────────────────────────────────────┤
                      │         XCTest Core Unit Tests         │
                      │ (URLSanitizer, TokenCounter, Stores)   │
                      └────────────────────────────────────────┘
```

---

## 2. Unit Testing Strategy (`XCTest`)

### Core Unit Test Suites
1. **`URLSanitizerTests`**: Validates URL prepending (`apple.com` $\rightarrow$ `https://apple.com`), explicit HTTPS handling, and search engine query fallbacks.
2. **`TokenCounterTests`**: Validates token estimations and context truncation limits.
3. **`MemorySearchTests`**: Validates natural language keyword search matching over page summaries.
4. **`TabManagerTests`**: Validates tab creation, active tab index selection, tab closure, and background tab suspension thresholds.

---

## 3. Memory Leak & Retain Cycle Testing

### Xcode Instruments & `leaks` Command Line Tool
Every release build must be audited for memory leaks using macOS command-line diagnostic tools:

```bash
# Execute leaks tool against active HoloBrowser process
leaks HoloBrowser
```

### Mandatory Teardown Invariants
* **`Tab.suspend()`**: Must drop `WKWebView` instance and detach `navigationDelegate`.
* **`TabManager.closeTab()`**: Must verify process deallocation for closed tab nodes.
* **Combine Subscriptions**: All Combine `sink` closures must capture `[weak self]`.
