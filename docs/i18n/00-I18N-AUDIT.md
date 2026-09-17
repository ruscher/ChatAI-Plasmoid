# 00 — Internationalization Audit

_Last updated: 2026-09-17 · ChatAI-Plasmoid 1.0.1_

This document records the state of internationalization (i18n) and localization
(l10n) in ChatAI-Plasmoid at the time of the i18n overhaul: what was found, what
was fixed, and what the code guarantees going forward.

## Scope

ChatAI-Plasmoid is a KDE Plasma 6 widget written in QML/JavaScript on top of
Qt 6 and Qt WebEngine. All user-facing text lives in the QML/JS sources under
`contents/ui/` and `contents/config/`. The embedded web pages (ChatGPT, Claude,
etc.) are third-party sites and are **out of scope** — they localize themselves
according to the user's account and browser locale.

## Method

1. Enumerated every user-facing string in the QML/JS sources
   (`text`, `title`, `subtitle`, `placeholderText`, `Accessible.name`, tooltip
   text, menu labels, dialog copy, notification text).
2. Verified each is wrapped in a KDE `KLocalizedString` call — `i18n`, `i18nc`,
   `i18np`, or `i18ncp`.
3. Extracted the message catalog with `xgettext` and compared against the
   sources for drift.
4. Audited the legacy translation assets (`locale/*.json`, the old
   `attranslate` cache) and the compiled catalogs (`contents/locale/**/*.mo`).
5. Validated placeholders, plural forms and formats across every `.po`.

## Findings

### English source strings — clean

The English source is already the single source of truth. Every user-facing
string is wrapped in an i18n function. The extracted catalog contains:

| Metric | Count |
| --- | ---: |
| Unique source messages | 335 |
| Plural messages (`i18np`) | 8 |
| Context-qualified messages (`i18nc`) | 18 |
| `i18n()` calls in source | 353 |
| `i18nc()` calls in source | 18 |
| `i18np()` calls in source | 8 |
| Source files contributing strings | 27 |

A scan for hardcoded user-facing literals returned only three intentional
non-translatable literals, all of which are correct to leave untranslated:

- `Header.qml` — `placeholderText: "https://…"` (a URL affordance, not prose).
- `AboutSettings.qml` — `text: "GPL-2.0-or-later"` (an SPDX license identifier).
- `SitesSettings.qml` — `placeholderText: "https://example.com/chat"` (an
  example URL).

### Legacy JSON translation cache — removed

The repository carried 28 `locale/*.json` files produced by a third-party
`attranslate` tool, plus a dormant `translate-and-build-package.yml` workflow
that consumed them. These were:

- **Unused at runtime** — Plasma loads compiled `.mo` files, never the JSON.
- **Low quality** — spot-checks found clear mistranslations (e.g. Bulgarian
  "Sites" rendered as "URL на сайта" / *site URL*, "Downloads" as "Папка за
  изтегляне" / *download folder*).

They were deleted. The canonical pipeline is now pure GNU gettext (see
[02-GETTEXT-PIPELINE.md](02-GETTEXT-PIPELINE.md)).

### Compiled catalogs — regenerated

All 29 `.mo` catalogs under `contents/locale/**/LC_MESSAGES/` were recompiled
from the `.po` sources so that what ships matches what is reviewed.

## Outcome

- English is the single clean source language; zero meaningful hardcoded UI
  strings remain.
- The catalog is regenerated deterministically and validated in CI.
- Five languages are fully translated and reviewed; the remaining 24 fall back
  to valid English rather than shipping unverified machine output
  (see [03-TRANSLATION-STRATEGY.md](03-TRANSLATION-STRATEGY.md) and
  [07-FINAL-REPORT.md](07-FINAL-REPORT.md)).
