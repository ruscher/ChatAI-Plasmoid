# 05 — RTL and Layout QA

_Last updated: 2026-09-17_

## Right-to-left (RTL)

Hebrew (`he`) is present as a catalog, and Arabic/Persian may be added later, so
the UI must be RTL-safe.

### Current state

- `he` currently ships as a **clean English fallback** (empty catalog), so no
  RTL text is rendered yet. When it is translated, the layout must be checked in
  a mirrored environment.
- ChatAI's chrome is built from Kirigami / PlasmaComponents3 controls laid out
  with `RowLayout`/`ColumnLayout` and `Layout.*` attached properties. Qt Quick
  Layouts mirror automatically when `LayoutMirroring.enabled` is true, which
  Plasma sets from the application layout direction for RTL locales.

### RTL guidance for contributors

- **Do not hardcode left/right.** Use `Layout.alignment`, `anchors` with
  `LayoutMirroring`, or logical properties; avoid absolute `x` positioning for
  chrome. (The download popup positions itself relative to its anchor with
  `anchor.width - popup.width`; verify this mirrors acceptably before shipping an
  RTL language.)
- **Icons that imply direction** (Back `go-previous`, Forward `go-next`) are
  provided by the Breeze icon theme, which mirrors them under RTL automatically.
- **The embedded web view** manages its own direction from the loaded site; the
  widget does not force a direction on it.
- Test with `QT_LAYOUT_DIRECTION=RTL` and a translated `he` catalog before
  marking Hebrew as shipped.

## Long-text / layout QA (LTR)

Translation lengthens strings; German is the stress test here.

- Toolbar buttons are **icon-only** (`display: IconOnly`) with the translated
  text exposed as tooltip and `Accessible.name`, so button width does not grow
  with translation — only tooltips do, which is safe.
- The toolbar already collapses progressively into the kebab (⋮) menu as width
  shrinks (`overflowLevel` in `Header.qml`), so longer localized menu labels are
  absorbed by the menu rather than overflowing the bar.
- Settings pages use `Kirigami.FormLayout` and `wrapMode: Text.WordWrap` /
  `Text.WrapAnywhere` on descriptive labels, so long German sentences wrap
  instead of clipping.
- Dialog subtitles (e.g. the profile-switch prompt) wrap and are not truncated.

### Checklist for a new language

1. Open Settings at a narrow and a wide popup width; confirm no clipping.
2. Confirm long labels wrap rather than elide where meaning matters.
3. Confirm number/plural strings render with the count in the right place.
4. For RTL: confirm toolbar order mirrors and directional icons flip.
