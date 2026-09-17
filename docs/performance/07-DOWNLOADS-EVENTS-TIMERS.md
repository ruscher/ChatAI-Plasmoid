# 07 — Downloads, Events, Timers

## Timer census (all 8)

| Timer | File | interval | repeat | starts when | stops when | idle? |
|---|---|---|---|---|---|---|
| saveSizeTimer | main.qml | 500 ms | no | popup resized | fires once | no |
| hideTimer | main.qml | 3 s | no | auto-hide + hover ends | fires once | only if auto-hide on |
| freezeTimer | WebView | 30 s | no | `hidden` becomes true | freeze or retry | no (one-shot on hide) |
| discardTimer | WebView | N min | no | `hidden` + `discardAfterMinutes>0` | fires once | no |
| slowResponseTimer | WebView | 12 s | no | load starts | load progresses/ends | no |
| navWatchdog | WebView | 2.5 s | no | after a navigation | fires once | no |
| downloadFlushTimer | WebView | 250 ms | no | pending throttled download update | no pending updates | only while downloading |
| hideStatusText | WebView | 750 ms | no | link-hover text shown | fires once | no |

**No repeating (`repeat: true`) timer exists.** Every timer is one-shot /
debounce / state-gated. Nothing polls at idle — consistent with the measured
0.00% idle CPU. This is the correct, event-driven design; no change needed.

## Download event coalescing (already good)
- Chromium emits `receivedBytesChanged` hundreds of times/second; these are
  routed through `scheduleDownloadUpdate()` → at most one UI update per
  `downloadUiIntervalMs` (250 ms → ≤4/s) via `downloadFlushTimer`.
- `stateChanged`/`isPausedChanged` apply immediately (rare, important).
- `downloadSummary` recomputes on `downloadsRevision` only.

Verified: many engine events → few UI updates. As specified.

## Model cost
- `downloadItems()`/`downloadIndex()` are O(n) over `downloadsModel`, n normally
  0–2. No O(n²). Building a map/index would add complexity for no gain at real n.
- **Note (low priority):** `downloadsModel` has no automatic pruning of finished
  entries within a long session; `clearFinished()` is user-triggered. Only a
  concern under pathological download counts. Left as-is (pruning finished
  downloads automatically could surprise users who expect their list to persist).

No changes warranted; the throttling design is already correct.
