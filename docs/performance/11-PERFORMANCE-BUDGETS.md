# 11 — Performance Budgets

Budgets grounded in the measured baseline (`01`). "Target" = a realistic bar to
hold, not an invented number. Where the baseline is `NOT MEASURED`, the budget is
provisional and needs the GUI measurement first.

| Metric | Baseline (measured) | Budget / target | Rationale |
|---|---|---|---|
| Chromium processes when NOT opened | 0 | **0** (hard) | lazy start must never regress |
| Idle CPU, open | 0.00% | **< 0.5%** | keep event-driven; no polling |
| Persistent repeating timers | 0 | **0** (hard) | no idle polling ever |
| Opened footprint (isolated PSS) | ~396 MB | **≤ ~410 MB** | dominated by Chromium; guard against QML-side growth |
| Renderer PSS (provider page) | ~135 MB | provider-dependent | not the plasmoid's to bound |
| Orphan/unused assets | 0 | **0** (hard) | keep the package lean |
| Package size (`contents/`) | 1.1 MB | **≤ 1.3 MB** | |
| Hidden CPU before Frozen | NOT MEASURED | target < 1% | needs GUI |
| PSS held while hidden (with Discard on) | NOT MEASURED | target → near browser-only after discard | R1 (`04`) |
| PSS after Close | NOT MEASURED | target → ~0 extra over pre-open | graceful Close validation |
| Cold open latency (click→first paint) | NOT MEASURED | target < ~400 ms to UI (Chromium load separate) | needs GUI timing |
| Download UI update rate | ≤ 4/s (250 ms) | **≤ 4/s** (hard) | already enforced |

## Enforcement
- `tools/perf-measure.sh` reproduces the isolated footprint / idle CPU / process
  count budgets on demand.
- `tools/validate.sh` guards package hygiene (no dev files, qmllint, i18n).
- The hard budgets (0 procs when idle, 0 repeating timers, 0 orphan assets,
  ≤4/s download UI) are the ones a future change must never break.
