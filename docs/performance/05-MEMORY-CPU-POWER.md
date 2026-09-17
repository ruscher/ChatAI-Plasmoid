# 05 — Memory, CPU, Power

## Memory
- Measured opened footprint: **≈396 MB PSS** isolated (see `01`), dominated by the
  Chromium renderer (~135 MB, provider content) + the in-host browser process.
- Leak audit (code, since heaptrack/valgrind absent):
  - download handlers connected on start / disconnected on finish; `downloadCache`
    entry deleted on finish → **no leak**.
  - `Notification` objects `destroy()` on close → **no accumulation**.
  - Auth/DevTools/FullScreen loaders deactivate → objects freed.
  - `downloadsModel` grows with download history within a session; `clearFinished()`
    exists but is user-triggered. Potential unbounded growth only under extreme
    download counts in one session — see `07` (low priority; n is normally 0–2).
- Runtime leak over open/close/settings/auth/fullscreen cycles: **NOT MEASURED**
  (needs GUI cycling + `/proc` PSS sampling; harness step described in `10`).

## CPU
- Open + idle: **0.00%** (measured). Nothing to reduce.
- Hidden CPU (before Frozen): **NOT MEASURED** (needs collapsed popup). The 30 s
  freeze delay (R2 in `04`) is the only knob here.

## Power / wakeups
- `powertop` not available. No repeating idle timer exists (`07`), so ChatAI
  contributes no periodic wakeups while collapsed/idle beyond what a Frozen/absent
  Chromium contributes. Laptop impact when idle is therefore expected to be
  minimal; a `powertop --time` before/after would confirm — `NOT MEASURED`.

Conclusion: memory is the axis with headroom, and only via lifecycle (Discard,
`04` R1). CPU/power are already at/near the floor when idle.
