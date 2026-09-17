# 02 — Profiling and Hotspots

Profiling method on this host: no QML profiler / heaptrack / valgrind available,
so this is (a) runtime measurement of CPU/PSS via `plasmawindowed` + `/proc`
(see `01`) and (b) a full manual audit of every QML/JS file for hot-path work.
Idle CPU measured **0.00%**, which already rules out busy-loop/polling hotspots.

## Hotspot table

| Hotspot | File | Frequency | Measured/estimated cost | Severity | Action |
|---|---|---|---|---|---|
| `providerForUrl()` linear scan (×~21) | ProviderModel.qml | on `url` change; also via `nameForUrl` | ~21 string matches × ~4 bindings per switch | P3 | **Keep** — user-action frequency, not per-frame |
| `currentProvider` computed in 3 files | main/WebView/AiSelector | on `url` change | 3× `providerForUrl` | P3 | Keep — infrequent |
| `isAuthUrl()` (regex + ~25 rule scan) | ProviderModel.qml | per main-frame nav + new-window | not per-frame | P3 | Keep |
| `downloadSummary` = `Downloads.summarize(downloadItems())` | WebView.qml | on `downloadsRevision` change | O(n) over model, throttled to ≤4/s | P3 | Keep (throttled; n usually 0–2) |
| `enabledProviders` filter | ProviderModel.qml | on any `showX` config change | O(21) | — | Keep (config-change only) |
| width-driven bindings (`overflowLevel`, `cssViewportWidth`, `searchInBar`…) | Header/WebView | during resize drag | trivial arithmetic | — | Keep |
| `builtInProviders` array (~21 × 2 i18n) | ProviderModel.qml | once per model instance | ~40 gettext lookups at creation | P3 | Keep (µs; see `08` note on multiple instances) |
| Timers | all | see `07` | none repeating at idle | — | Keep |

**No P0/P1/P2 code hotspots were found.** The design already avoids per-frame JS,
idle polling and unthrottled event storms.

## WebView.qml (the largest / most important file) — findings

- `WebEngineProfilePrototype` + `WebEngineView` created once per `WebView`
  lifetime; profile built in `Component.onCompleted` (correct — building it in a
  binding crashes `setProfile`).
- Downloads: `receivedBytesChanged`/`totalBytesChanged` are throttled through
  `scheduleDownloadUpdate()` (≤ `downloadUiIntervalMs` = 250 ms); `stateChanged`
  and `isPausedChanged` apply immediately. Handlers are **connected on start and
  disconnected on finish**; `downloadCache[id]` is deleted on finish → no handler
  or cache leak.
- `Notification` objects use `onClosed: destroy()` → no accumulation.
- `authPopupLoader` / `devToolsLoader` / `fullScreenLoader` are `active: false`
  by default → **DevTools/FullScreen/Auth cost nothing until used**, destroyed on
  close.
- After the optimization work: navigation is funnelled through a single deferred,
  coalesced `navigateTo()` with no reactive `url` binding (see `04`/`12`).

## Verdict

The correct conclusion — supported by the 0.00% idle CPU measurement and the
audit — is that CPU-side there is nothing to "optimize"; spending effort inventing
micro-changes here would be performance theater. The remaining, real opportunity
is **memory lifecycle when hidden/closed** (see `04`).
