# 08 — Assets and Startup Footprint

## Assets (`contents/ui/assets/`, 480 KB)
- **Orphan check: 0 unused SVGs.** Every file maps to a `ProviderModel` `iconId`
  (colorful/filled/outlined variants) or is a logo (`logo.svg`, `logo-light.svg`,
  `logo-dark.svg`). Verified by cross-referencing filenames against
  `builtInProviders`.
- Largest: `colorful/lobechat.svg` 51 KB, then `filled/google-*.svg` ~24 KB.
  These load **only** when their provider is enabled and shown at that icon style,
  so they are off the startup path.
- Icons are loaded on demand by the selector/panel; none are eagerly loaded at
  startup. No bitmap conversion attempted (would break HiDPI; SVG is correct).
- SVG minification (dropping Inkscape/sodipodi metadata) could shave a few KB but
  is **not worth the risk** of altering rendering; skipped (would be theater).

## Startup footprint (widget in panel, not opened)
- Only `CompactRepresentation` + `ProviderModel` + root QML instantiate. No
  Chromium, no timers running. Measured: 0 QtWebEngineProcess (see `01`).
- `ProviderModel.builtInProviders` builds a ~21-entry array with ~40 `i18n()`
  lookups once at instantiation — microseconds, acceptable on the startup path.

## Observation (low priority): multiple ProviderModel instances
- `main.qml` creates one `ProviderModel` (needed at startup). Each settings page
  (`AppearanceSettings`, `AboutSettings`, `SitesSettings`, …) also declares its
  own `ProviderModel { id: internalModel }` as a fallback default, instantiated
  even when the runtime model is passed in.
- Impact: a transient extra model (~40 i18n lookups) each time a settings page
  loads — **not** on the startup or open path, only when settings are opened.
  Negligible; converting to a lazy/shared model would add a Loader/plumbing for no
  measurable gain. **Left as-is** (documented for future consideration).

No asset or startup changes warranted.
