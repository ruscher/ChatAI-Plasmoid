# 03 — Translation Strategy

_Last updated: 2026-09-17_

## Principle: correct English fallback over bad translation

gettext falls back to the English source whenever a message is untranslated or
marked fuzzy. A clean, fully-English catalog therefore produces a **correct,
coherent UI** — far better than a half-machine-translated one with wrong or
mixed-language labels.

The guiding rule for this project:

> Ship a language only when its translations are verifiable at native quality.
> Otherwise ship a clean English fallback and invite native contributions.

A non-empty `msgstr` is **not** proof of translation. The old `attranslate`
catalogs had non-empty entries that were simply wrong (see
[00-I18N-AUDIT.md](00-I18N-AUDIT.md)); those were discarded.

## What ships now

- **Fully translated & reviewed (5):** English (source), Portuguese (`pt`),
  Brazilian Portuguese (`pt_BR`), Spanish (`es`), German (`de`) — 335/335
  messages, 0 fuzzy, 0 format errors.
- **Clean English fallback (24):** `bg cs da el et fi fr he hr hu is it ja ko
  nl no pl ro ru sk sv tr uk zh` — empty catalogs with correct `Plural-Forms`
  headers, so every string renders as valid English.

The full per-language table lives in
[07-FINAL-REPORT.md](07-FINAL-REPORT.md).

## Why not machine-translate the other 24?

- The project maintainers cannot verify quality in 24 languages.
- Machine output routinely mistranslates UI terms of art ("Home", "Pin",
  "Profile", "Downloads") and breaks placeholder/plural rules.
- A wrong translation is worse than English: it misleads users and erodes trust.

Native speakers are welcome to fill any of the 24 catalogs — see
[../../CONTRIBUTING.md](../../CONTRIBUTING.md) if present, or open a PR editing
`locale/<lang>.po`.

## Quality bar for a language to be marked "translated"

1. 335/335 messages translated, 0 fuzzy.
2. All placeholders (`%1`, `%2`, `%n`) preserved and correctly ordered.
3. Correct plural forms for the locale.
4. `msgfmt --check --check-format` clean.
5. `tools/check-po.py` reports 0 errors.
6. Reviewed by someone fluent in the language.

## metadata.json Name/Description — decision

The plasmoid's `metadata.json` carries `Name` ("ChatAI") and a `Description`
("Access AI chat assistants…"). The current gettext pipeline extracts strings
only from the QML/JS sources, so these two metadata fields are **not** in the
catalog and remain English in the app launcher / "Add Widgets" list.

**Decision:** leave them English for 1.0.1.

- `Name` is a proper noun ("ChatAI") and should not be translated anyway.
- The `Description` is the only untranslated user-visible metadata string. The
  in-widget UI (including the "ChatAI" title, which *is* an `i18n()` call) is
  fully covered.
- Localizing metadata cleanly requires either KDE's desktop-file localization
  convention or adding `metadata.json` to the extraction step; this is tracked
  as a possible future enhancement rather than shipped half-done.

This keeps the "no bad translations" rule intact: nothing user-visible is shown
in a wrong or mixed language.
