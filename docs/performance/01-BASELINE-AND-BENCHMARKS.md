# 01 — Baseline and Benchmarks

All numbers below are **measured** on the test host (Plasma 6.6.6, Wayland, 6 CPU)
with `tools/perf-measure.sh`, which runs the plasmoid **isolated** in
`plasmawindowed` so its cost is separated from `plasmashell`. Memory is reported
as **PSS** (proportional set size, from `/proc/<pid>/smaps_rollup`) because RSS
double-counts shared Qt/Chromium libraries across the process tree.

> Not fabricated: where a value could not be obtained it says `NOT MEASURED` with
> the reason. GUI-interactive scenarios need the real systray popup driven by
> hand and are marked.

## How to reproduce

```bash
# on the test host, inside a running Plasma session:
bash tools/perf-measure.sh 12     # 12 s settle
```

The script imports the live session env, launches `plasmawindowed ChatAI-Plasmoid`,
walks the process tree, prints per-process PSS/RSS, total footprint, WebEngine
child count, and a 4 s idle CPU sample, then kills the isolated instance.

## Cenário A — installed, never opened

- QtWebEngineProcess in the system attributable to ChatAI: **0** ✅
- No Chromium browser/renderer/zygote/gpu processes exist until the popup is
  first expanded. The lazy `Loader` (`active: !webviewClosed && (expanded || …)`)
  works as designed.
- Marginal cost = the `CompactRepresentation` + `ProviderModel` + root QML inside
  `plasmashell`. Not separable from `plasmashell` on this host (no
  `plasmoidviewer`); estimated negligible (static QML, no timers running when
  collapsed — see `04`/`07`). **Isolated idle sub-MB cost: NOT MEASURED** (would
  need plasmoidviewer).

## Cenário B — first open (isolated, `plasmawindowed`, 12 s settle)

| Process | type | PSS | RSS |
|---|---|---:|---:|
| plasmawindowed | host: QML + Qt + WebEngine **browser process (in-process)** | 236.3 MB | 438.9 MB |
| QtWebEngineProcess | zygote | 13.9 MB | 61.9 MB |
| QtWebEngineProcess | zygote | 7.4 MB | 61.9 MB |
| QtWebEngineProcess | zygote | 3.8 MB | 13.3 MB |
| QtWebEngineProcess | renderer | 134.7 MB | 205.7 MB |
| **TOTAL** | 5 processes (4 WebEngine children) | **≈ 396 MB PSS** | — |

Notes:
- Qt WebEngine runs the **browser (UI) process in the host application**, so in
  the real widget that share lands inside `plasmashell`, not a separate process.
- The renderer (~135 MB PSS) is the page (duck.ai default). This is **provider
  content**, largely outside the plasmoid's control — the lever is *when* it
  exists, not its size.
- `plasmawindowed` adds its own Qt/QML host overhead that the embedded case does
  not have, so 236 MB is an **upper bound** for the host share.
- Cold-vs-warm open latency (click→interface, click→WebView): **NOT MEASURED** —
  requires timing the real systray popup (GUI-interactive). `plasmawindowed`
  start-to-settled here was ≤12 s wall (includes X/Wayland window creation +
  duck.ai load), not comparable to popup latency.

## Cenário D — popup open and idle

- Idle CPU of the whole ChatAI process tree over a 4 s `pidstat` window: **0.00%** ✅
- No repeating timer fires while the loaded page sits idle (all timers are
  one-shot/debounce/state-gated — see `07`).

## Cenário E/F — hidden→Frozen→Discarded / Close release

- **NOT MEASURED here.** `plasmawindowed` keeps the widget permanently visible,
  so `WebView.hidden` never becomes true and the freeze/discard path cannot be
  triggered in isolation. These require collapsing/closing the real systray
  popup. Code path verified by review (`04`); runtime before/after is a GUI test.
- Observation from the live panel widget (user had it open/pinned): while
  open+pinned it holds ~6 QtWebEngineProcess — expected for an Active page.

## Footprint / package

| Metric | Value |
|---|---|
| Runtime package (`metadata.json` + `contents/`) | 1.1 MB |
| Assets (`contents/ui/assets/`) | 480 KB |
| Largest SVG | `colorful/lobechat.svg` 51 KB (lazy: only if LobeChat+colorful) |
| Orphan/unused assets | **0** (all referenced) |
| Persistent repeating timers at idle | **0** |

## Statistical note

CPU idle was 0.00% across the sample, so multi-run min/median/p95 is
uninformative here. Memory PSS is deterministic within ±a few MB between runs
(page-load variance in the renderer). Cold/warm distinction applies to the
open-latency metric which is `NOT MEASURED` (GUI).
