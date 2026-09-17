# 00 — Master Plan (Performance Engineering)

> Development documentation only. Nothing in the ChatAI runtime reads `docs/`.
> Deleting `docs/performance/` must not affect the widget.

## Method

`MEASURE → UNDERSTAND → OPTIMIZE → MEASURE AGAIN → VALIDATE → KEEP OR REVERT`

No cosmetic changes, no "performance theater". A change is kept only if it
produces a measurable gain or clearly improves the architecture **without
regressions**, with 100% of functionality preserved.

## Test environment (as measured)

- Remote test host, Plasma **6.6.6**, Qt **6.10.2**, KF **6.24**, session type
  **Wayland** (`wayland-0`). Kubuntu/Mainuan base. 6 CPU.
- Icon theme: kora-cyan.
- Tooling present: `plasmawindowed`, `pidstat`, `perf`, `/usr/bin/time`,
  `qmllint`. **Absent**: `plasmoidviewer`, `heaptrack`, `valgrind/massif`,
  `qmlprofiler`, `ps_mem`, `smem`, `powertop`.
- Consequence: process/RSS/PSS/CPU measurable via `plasmawindowed` isolation and
  `/proc`. Deep allocation profiling (heaptrack/massif) and the QML profiler are
  **not available** — QML analysis is done by code review + `QSG_RENDER_TIMING`
  where relevant. GUI-interactive scenarios (collapse→freeze→discard, Close
  release, login, downloads) require the popup to be driven by hand and are
  marked accordingly.
- **X11/Xorg session not available on the host** → X11 lifecycle is reasoned
  from code, not measured. Marked `NOT TESTED` in the matrix.

## Architecture (as read from source)

Plasmoid (`main.qml`, `PlasmaoidItem`):
- `compactRepresentation` = `CompactRepresentation.qml` (panel icon; icon source
  chosen by `iconMode`, uses bundled `assets/logo-*.svg` or provider favicon).
- `fullRepresentation` = a `ColumnLayout` with `Header` + a lazy `Loader` for the
  `WebView` and a lazy `Loader` for `SettingsPanel`.
- Single source of truth for providers: `ProviderModel.qml` (a `QtObject` with a
  ~21-entry `builtInProviders` array + parsed custom providers).

Critical paths:
- **Startup (widget installed, panel):** only `CompactRepresentation` +
  `ProviderModel` + `main.qml` root exist. No `WebView`, no Chromium. `Migration.run()`
  runs once in `main.qml Component.onCompleted`.
- **First open (cold):** `webviewLoader.active` becomes true → `WebView.qml`
  created asynchronously → `WebEngineProfilePrototype.instance()` +
  `configureProfile()` + `applyZoom()` + `goHome()` (deferred, coalesced) →
  Chromium browser process (in the host), zygotes, renderer spawn.
- **Hide (popup collapsed):** `WebView.hidden = true` → `freezeTimer` (30 s) →
  `Frozen`; optional `discardTimer` (`discardAfterMinutes`, default 0 = off) →
  `Discarded`. Guarded by `busy` (loading, audible, downloads, permission,
  devtools, fullscreen, auth).
- **Close:** `webviewClosed = true` → `Loader.active = false` → `WebView`
  destroyed → Chromium processes released.

## Hotspot classification (after baseline + full code audit)

| # | Item | Severity | Verdict |
|---|------|----------|---------|
| 1 | Lazy WebEngine (no Chromium until opened) | — | **Already optimal** (measured: 0 QtWebEngineProcess when not opened) |
| 2 | Idle CPU while open | — | **Already optimal** (measured: 0.00%) |
| 3 | Freeze/Discard/Destroy lifecycle | P1 | Implemented; correctness of Discard→reopen and Close→release needs GUI validation |
| 4 | Memory held while hidden (renderer ~135 MB kept, Discard off by default) | P1 | **Main lever** for "disappear when idle" — a discard default is a documented CPU/RAM/speed trade-off |
| 5 | `providerForUrl` / `isAuthUrl` linear scans | P3 | Run on user actions/navigation, not per-frame → **do not optimize** (would add complexity for no measurable gain) |
| 6 | Download byte-update throttling | — | Already implemented (coalesced to ≤4/s) |
| 7 | Timers (8 total) | — | All debounce/one-shot or state-gated; **no idle polling** |
| 8 | Assets | — | No orphan SVGs; all referenced. Largest: `lobechat.svg` 51 KB (loaded only if LobeChat + colorful) |

There are **no P0 findings** and **no P2+ code hotspots**. See `02` for the
per-file audit and `04` for the lifecycle deep-dive.

## Strategy / order

Because the app is already lean, the plan is: (1) establish and document the real
baseline; (2) audit every hot path and lifecycle transition; (3) make only
safe, verifiable changes; (4) document the lifecycle trade-offs that need
GUI-interactive validation and provide a reproducible harness.

## Rollback

All work happens on a dedicated branch; every change is qmllint + `validate.sh`
clean and re-measured via `tools/perf-measure.sh` before keeping. Any change
without a measurable gain is reverted (see `12-IMPLEMENTATION-LOG.md`).
