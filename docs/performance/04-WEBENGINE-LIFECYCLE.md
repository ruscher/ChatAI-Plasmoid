# 04 — WebEngine Lifecycle (the main lever)

Qt WebEngine/Chromium dominates the footprint (baseline: ~135 MB PSS renderer +
in-host browser process). The plasmoid cannot shrink Chromium; the win is
controlling **when** it exists and how much it holds while hidden.

## Current policy (from `WebView.qml` + `main.qml`)

```
not opened            → no WebView, no Chromium            (measured: 0 procs) ✅
open + interacting    → Active                                                  ✅
open + idle           → Active, 0% CPU                       (measured: 0.00%)  ✅
hidden ≥ 30 s (safe)  → Frozen        (freezeTimer, 30 s)                       ✅ code
hidden ≥ N min        → Discarded     (discardTimer, discardAfterMinutes)      ⚠ default 0 = OFF
Close                 → WebView destroyed, Chromium released                    ✅ code
```

Freeze/Discard are correctly **guarded by `busy`**: loading, `recentlyAudible`,
active downloads, pending permission, DevTools, fullscreen, auth popup, and
`recommendedState === Active`. `tryFreeze()` retries later instead of freezing
during important work. This is correct and must be preserved.

## What is verified vs. what needs GUI validation

- **Verified by measurement:** lazy start (0 processes until open), idle 0% CPU.
- **Verified by code review only (needs GUI before/after):**
  - hidden → `Frozen` after 30 s (cannot trigger under `plasmawindowed`, which
    never hides the view);
  - hidden → `Discarded` after `discardAfterMinutes`;
  - `Close` → renderer/zygotes actually exit and PSS returns to ~0 extra.

A quick abrupt `kill` of `plasmawindowed` left a host-less QtWebEngineProcess
briefly (reparented to init) — that is the **abrupt-kill** path, not the app's
graceful `Close` (`Loader.active=false` → `WebEngineView` destructor). The
graceful path must still be confirmed with the real popup (see `10`).

## Recommendation R1 — a sane Discard default (P1, the "disappear when idle" goal)

Today `discardAfterMinutes` defaults to **0 (never discard)**: a hidden page
freezes (CPU→0) but keeps its ~135 MB renderer indefinitely. For a widget meant to
live permanently in the panel, that is the opposite of "disappears from a resource
point of view when idle".

Proposal: default `discardAfterMinutes` to a conservative value (e.g. **30**):
- short hides (< 30 min) keep the frozen page → instant reopen, no reload;
- long idle (≥ 30 min) discards → renderer memory returned to the system;
- reopen after discard reloads the provider (a few seconds; state that lived only
  in the page is re-fetched — acceptable for a long-idle assistant).

Trade-off (RAM ↓ vs. occasional reload). It stays **user-tunable** (Advanced →
"discard after N minutes"; 0 keeps the old behaviour).

**Status: NOT shipped in this pass.** Reason: honest application of
`MEASURE → VALIDATE → KEEP`. The discard→reopen path must be validated on the
real popup (hide long enough to discard, reopen, confirm the page reloads
correctly and login/session survive) before changing a default. Changing it blind
would be exactly the unvalidated move the mission forbids. See `12` for the
proposed change and the validation checklist; ready to enable once tested.

## Recommendation R2 — freeze delay (P3)

`freezeTimer` = 30 s. Freezing sooner (e.g. 15 s) cuts the window in which a hidden
provider's JS keeps running, saving CPU/power on laptops. `Frozen` resumes
instantly with no data loss and is `busy`-guarded, so it is low-risk — but the
gain is small and, like R1, best confirmed with a hidden-CPU measurement on the
real popup. **Not shipped without that measurement.**

## Non-goals (explicitly rejected)

- No Chromium security/isolation flags, no `--no-sandbox`, no disabling GPU, no
  forcing software rendering, no cache-wipe on start. None of these are safe or
  aligned; they would break providers/login or hurt warm performance.
