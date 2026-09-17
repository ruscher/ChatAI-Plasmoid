# 10 — Regression Test Matrix

Legend: PASS / FAIL / NOT TESTED / NOT AVAILABLE. Honest status as of this pass.
No test is marked PASS unless actually exercised.

## Environment
| Item | Status |
|---|---|
| Wayland session | PASS (all runtime measurement done here) |
| X11/Xorg session | NOT AVAILABLE (host runs Wayland only) |
| Plasma 6.6.6 / Qt 6.10.2 / KF 6.24 | PASS (target platform) |
| `qmllint` all QML | PASS (clean) |
| `tools/validate.sh` (json/xml/qmllint/msgfmt/check-po/package) | PASS |
| `tools/perf-measure.sh` isolated run | PASS (numbers in `01`) |

## Functional (must not regress)
| Case | Status | Note |
|---|---|---|
| Widget loads in panel (no errors) | PASS | plasmashell restart clean, no QML errors |
| Lazy start (no Chromium until open) | PASS | measured 0 procs |
| Open popup → page loads | PASS (live widget observed loading duck.ai/Claude/HuggingChat) |
| Provider switch loads reliably | PASS | fix verified over repeated live switches |
| Idle CPU when open | PASS | 0.00% |
| ChatGPT / Claude / Gemini / DeepSeek | PARTIAL | Claude, HuggingChat, Duck.ai observed live; others NOT individually re-tested this pass |
| Custom provider | NOT TESTED |
| Login / Google / Microsoft / OAuth / popup / postMessage | NOT TESTED this pass | unchanged code paths; navigation fix preserves `isAuthUrl`/AuthPopup routing |
| Downloads (small/large/pause/resume/cancel/retry) | NOT TESTED this pass | throttling code unchanged |
| Notifications / permissions / mic / camera / clipboard / screen share | NOT TESTED this pass | code unchanged |
| Zoom / Find / Fullscreen / PDF / MHTML / DevTools | NOT TESTED this pass | code unchanged |
| Settings pages open/close | PARTIAL | Appearance changed (added toggles), qmllint clean; runtime open not re-cycled this pass |
| Translations (pt_BR etc.) | PASS | new strings translated, msgfmt/check-po clean |
| Dark / light theme, HiDPI | NOT TESTED this pass |
| Freeze after hide | NOT TESTED | needs GUI collapse (see `04`) |
| Discard after N min | NOT TESTED | default off; R1 pending validation |
| Close → memory released | NOT TESTED (graceful path) | needs GUI Close + PSS sampling |

## Memory-leak cycle test (recommended, not run)
Because heaptrack/valgrind are absent, use PSS sampling:
```
for i in $(seq 20); do  # driven on the real popup
  open; sleep 3; close; sleep 3
  grep Pss /proc/$(pgrep -x plasmashell)/smaps_rollup
done
```
Look for monotonic growth. **NOT RUN** (requires GUI automation not available on
this host — no wtype/ydotool).

## Honest summary
Runtime functional coverage this pass was limited to what could be observed on the
live Wayland popup (load, provider switch, idle). The optimization work touched
only: navigation funnel (WebView), popup min-size (main), toolbar/menu icon
rendering (Header/ChatAIMenu), and an Appearance toggle — none of which alter
login/download/permission code paths. Full A–K scenario validation and X11 remain
`NOT TESTED`/`NOT AVAILABLE` and are listed as follow-ups.
