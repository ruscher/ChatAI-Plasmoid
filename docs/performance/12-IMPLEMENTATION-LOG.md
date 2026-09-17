# 12 — Implementation Log

Each entry: problem → hypothesis → change → validation → kept/reverted.

## L1 — Navigation funnel (WebView.qml) — KEPT
- **Problem:** switching provider intermittently left a blank page.
- **Root cause:** the reactive `url: plasmoid.configuration.url` binding started a
  navigation that raced `goHome()`'s `stop()`+assign (same tick), and after the
  first imperative assign the binding was dead anyway — inconsistent path.
- **Change:** removed the reactive `url` binding; all navigation goes through a
  single `navigateTo(url)` that sets `pendingUrl`, `stop()`s, and loads on the
  **next tick** via `Qt.callLater(startPendingNavigation)`, coalescing multiple
  same-tick calls (`navScheduled`). Initial load moved to `Component.onCompleted`;
  `onUrlChanged` + `goHome()` both funnel through `navigateTo`. A 2.5 s
  `navWatchdog` forces the load if it never took; `pendingUrl` cleared on
  `LoadSucceeded`.
- **Validation:** qmllint clean; validate.sh PASS; verified live over repeated
  provider switches (loads every time). Correctness + reliability win.
- **Perf effect:** removes a redundant navigation per switch (no double load).

## L2 — Popup minimum size (main.qml) — KEPT
- **Problem:** popup could not be dragged smaller than ~780 px.
- **Change:** `Layout.minimumWidth/Height` lowered to `gridUnit*18`. Default size
  unchanged; mobile-layout hint already warns if too narrow.
- **Validation:** qmllint/validate PASS. UX win, no perf regression.

## L3 — Toolbar/menu icon rendering (Header.qml, ChatAIMenu.qml) — KEPT
- Back/forward + overflow-menu + three menu entries rendered as monochrome masks
  (`Kirigami.Icon isMask`) so multicolour icon themes (kora) don't show light/odd
  icons; disabled back/forward stay legibly greyed.
- **Validation:** qmllint clean; verified via screenshots. Cosmetic/UX; no perf
  impact (icon count unchanged).

## L4 — Appearance toggles (AppearanceSettings.qml) — KEPT
- Added "Hide Toolbar Automatically" + "Always hide the toolbar". i18n added for
  de/es/pt/pt_BR. No perf impact.

## L5 — Measurement harness (tools/perf-measure.sh) — ADDED
- Isolated PSS/CPU/process measurement via `plasmawindowed`. Dev tool, not in the
  package.

## Proposed / NOT shipped (pending GUI validation)

### P1 — Discard default (`contents/config/main.xml`)
- Proposed: `discardAfterMinutes` default `0 → 30`.
- Diff (when validated):
  ```xml
  <entry name="discardAfterMinutes" type="Int"><default>30</default></entry>
  ```
- Validation checklist BEFORE keeping: hide popup > 30 min (or temporarily set a
  small value), confirm `lifecycleState==Discarded`, reopen → page reloads
  correctly, login/session survive, no blank page, PSS of renderer returns while
  discarded. Revert if any regression.

### P3 — Freeze delay (`WebView.qml` freezeTimer 30 s → 15 s)
- Only with a hidden-CPU before/after measurement showing a real gain.

## Reverted
- None (no speculative change was shipped).
