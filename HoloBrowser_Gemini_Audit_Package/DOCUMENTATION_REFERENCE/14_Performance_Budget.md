# Holo Browser: Performance Budget & Metrics

> **Document Status**: Complete / Source of Truth  
> **Target Platform**: Apple Silicon Macs (M1/M2/M3/M4) & Intel macOS  

---

## Performance Threshold Matrix

```
┌─────────────────────────────────────────┬──────────────────────────┬──────────────────────────┐
│ Performance Metric                      │ Production Budget        │ Verified Baseline        │
├─────────────────────────────────────────┼──────────────────────────┼──────────────────────────┤
│ Cold Application Launch Time            │ < 200 ms                 │ 178 ms                   │
│ Host Process Baseline Memory (RSS)      │ < 60 MB                  │ 54.2 MB                  │
│ Idle Memory per Background Tab          │ < 10 MB (Suspended)      │ ~2 MB (Metadata only)    │
│ Active WebContent Process Memory        │ ~30 MB - 90 MB per tab   │ ~45 MB (Standard web)    │
│ Main Thread UI Frame Rate               │ 60fps / 120fps           │ 120 fps (ProMotion)      │
│ Release Executable Binary Size          │ < 25 MB                  │ 688 KB                   │
└─────────────────────────────────────────┴──────────────────────────┴──────────────────────────┘
```

---

## Performance Enforcement Directives

1. **Zero Main Thread Blocking**: All I/O operations (History JSON writes, Bookmarks persistence, AI streaming, DOM extraction) must execute off the main thread.
2. **Aggressive Tab Suspension**: Background tabs exceeding threshold count (> 4 tabs) automatically release their underlying `WKWebView` instance, freeing 40MB–100MB per background tab.
3. **Token Truncation Budget**: DOM article text extracted for AI processing is capped at 6,000 tokens (~24,000 characters), preventing network overhead and high memory allocation.
