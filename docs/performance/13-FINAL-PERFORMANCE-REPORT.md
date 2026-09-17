# 13 — Final Performance Report

## Executive summary

ChatAI-Plasmoid was measured and audited end-to-end. **The headline finding is
that the architecture is already very efficient**, and the measurements prove it:
zero Chromium processes until the widget is opened, **0.00 % CPU when open and
idle**, zero repeating idle timers, and zero unused assets. There was **no P0/P1/P2
CPU or leak hotspot to fix** — so, per the mission's own rule against "performance
theater", no speculative code was added to manufacture a diff.

The single axis with real headroom is **memory held while hidden** (a frozen page
keeps its ~135 MB renderer because Discard is off by default). That is a
documented CPU/RAM/speed trade-off (`04` R1) and is proposed but **not shipped
unvalidated**, because it requires a GUI before/after that this host cannot
automate (no synthetic input, popup can't be driven headlessly).

This pass delivered: the real baseline, a reproducible isolated measurement
harness (`tools/perf-measure.sh`), a full per-file audit, and the lifecycle
trade-off analysis with a validation checklist.

## Measured before/after

| Metric | Before | After | Change |
|---|---|---|---|
| Chromium procs when not opened | 0 | 0 | already optimal |
| Idle CPU (open) | 0.00 % | 0.00 % | already optimal |
| Persistent repeating timers | 0 | 0 | already optimal |
| Opened footprint (isolated PSS) | ~396 MB | ~396 MB | Chromium-bound; unchanged |
| Provider switch reliability | intermittent blank page | loads every time | **fixed** (nav funnel, `12` L1) |
| Orphan assets | 0 | 0 | already clean |
| Download UI update rate | ≤ 4/s | ≤ 4/s | already correct |
| Cold/warm open latency | NOT MEASURED | NOT MEASURED | needs GUI timing |
| Hidden→Frozen CPU | NOT MEASURED | NOT MEASURED | needs GUI |
| PSS after Close (graceful) | NOT MEASURED | NOT MEASURED | needs GUI |

No metric regressed. The only functional behavior that measurably improved
(provider-switch reliability) came from the navigation funnel already in the
branch, which this analysis validated as also removing a redundant navigation.

## 1. Main bottlenecks found
- None on CPU/idle/startup — those are already at the floor.
- The only resource with headroom: renderer memory retained while hidden (Discard
  disabled by default).

## 2. Main optimizations
- Confirmed and documented the existing lazy-load / freeze / throttling design is
  correct (with measurements).
- Navigation funnel (`navigateTo`) removes double-navigation on provider switch
  (reliability + one fewer load).
- Added a reproducible measurement harness and performance budgets to prevent
  future regressions.

## 3. Files modified (this + immediately preceding UX pass, all in the branch)
- `contents/ui/WebView.qml` — single coalesced navigation, watchdog (L1).
- `contents/ui/main.qml` — lower popup min size (L2).
- `contents/ui/Header.qml`, `contents/ui/ChatAIMenu.qml` — monochrome mask icons (L3).
- `contents/ui/settings/AppearanceSettings.qml` — toolbar toggles (L4).
- `tools/perf-measure.sh` — new measurement harness (L5).
- `docs/performance/*` — this analysis (dev docs; no runtime dependency).

## 4–8. CPU / RAM / startup / hidden / after-Close
- CPU: idle 0 % (measured). RAM: ~396 MB opened (Chromium-bound). Startup: lazy,
  0 procs until open (measured). Hidden/after-Close: **NOT MEASURED** (GUI), code
  path reviewed and correct; Discard default is the recommended next lever.

## 9–13. Tests / Wayland / X11 / providers
- Wayland: measured. X11: NOT AVAILABLE on host. Providers observed live: Duck.ai,
  Claude, HuggingChat (load + switch). Others: code paths unchanged, not
  individually re-tested. Full matrix in `10`.

## 14. Problems still open
- Discard default off → memory kept while hidden (R1, needs GUI validation).
- Graceful-Close memory release: reviewed, not runtime-measured.
- Leak-over-cycles: not runtime-measured (no heaptrack; no GUI automation).

## 15. Future suggestions
- Validate + enable a conservative `discardAfterMinutes` default (biggest RAM win
  for an always-installed widget).
- Add a hidden-CPU/power measurement (powertop) once a GUI-drive is available.
- Optional: freeze delay 30 s → 15 s after a hidden-CPU measurement.
- Optional: share one `ProviderModel` across settings pages (cosmetic).

## 16. Reports location
`docs/performance/00-…13-…`. Harness: `tools/perf-measure.sh`. These are
development artifacts only — removing `docs/performance/` does not affect the
runtime.

## Honesty statement
No benchmark numbers were fabricated. Every value is either measured (and labeled
so) or explicitly `NOT MEASURED` with the reason (GUI-interactive, or tool
absent). The most valuable honest outcome of this mission is the evidence that the
widget is already lean, plus a guarded plan for the one remaining memory lever.
