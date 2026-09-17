# 09 — UX / Perceived Performance

## Feedback already present (good)
- Load progress bar (`topOverlays` `ProgressBar`, top of the view) during page
  load.
- `slowResponseTimer` (12 s) surfaces an InlineMessage with Retry / Open in
  Browser when an anti-bot front end stalls — good perceived-latency handling.
- Mobile-viewport hint when the page falls to a mobile layout.
- Error overlay (`ErrorView`) with Retry / Open externally.
- No continuous spinner while idle (correct — matches 0% idle CPU).

## First-frame / open latency
- The header renders immediately; the `WebView` `Loader` is `asynchronous: true`,
  so the popup UI appears before Chromium finishes coming up. Good.
- Perceived open latency (click→interface, click→first paint) is **NOT MEASURED**
  (GUI). Recommend timing it on the real popup as the primary perceived-speed KPI.

## Reliability fix that improves perceived speed
- The provider-switch navigation was intermittently leaving a blank page (a
  stop()+assign race + a reactive binding competing with `goHome()`). Rebuilt as a
  single coalesced `navigateTo()` + a 2.5 s watchdog. Now a switch reliably loads
  — the biggest perceived-quality issue observed, now fixed (see `03`/`12`).

## Considered but rejected
- Skeleton loaders: the provider page paints its own UI; adding a skeleton would
  duplicate/flash. Not added.
- Pre-warming Chromium at login: exists as opt-in `loadOnStartup`; default stays
  off to honor low idle footprint (user chooses RAM vs. instant-open).

No further UX changes made in this pass beyond the navigation reliability fix.
