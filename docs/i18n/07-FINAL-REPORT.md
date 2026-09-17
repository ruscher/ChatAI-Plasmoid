# 07 — Final Report

_Last updated: 2026-09-17 · ChatAI-Plasmoid 1.0.1_

## Summary

ChatAI-Plasmoid is fully internationalized. English is the single source
language, every user-facing string is wrapped in a KDE `KLocalizedString` call,
and the catalog is generated and validated deterministically through standard
GNU gettext. Five languages ship fully translated and reviewed; the remaining 24
ship as clean English fallback rather than unverified machine output.

## Catalog

| Metric | Value |
| --- | ---: |
| Source language | English (US) |
| Unique messages | 335 |
| Plural messages | 8 |
| Context messages | 18 |
| i18n call sites | 379 (`i18n` 353 · `i18nc` 18 · `i18np` 8) |
| Languages shipped | 29 |
| gettext domain | `plasma_applet_ChatAI-Plasmoid` |
| `.po` in repo | 29 |
| `.mo` shipped | 29 |
| Legacy JSON removed | 28 |

## Coverage table

Coverage counts only genuine, non-fuzzy translations. "Fallback" catalogs are
intentionally empty and render as English.

| Language | Code | Translated | Fuzzy | Untranslated | Status | Validation |
| --- | --- | ---: | ---: | ---: | --- | --- |
| English (source) | en | 335/335 | 0 | 0 | ✅ Complete | pass |
| Portuguese | pt | 335/335 | 0 | 0 | ✅ Complete | pass |
| Portuguese (Brazil) | pt_BR | 335/335 | 0 | 0 | ✅ Complete | pass |
| Spanish | es | 335/335 | 0 | 0 | ✅ Complete | pass |
| German | de | 335/335 | 0 | 0 | ✅ Complete | pass |
| Bulgarian | bg | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Czech | cs | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Danish | da | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Greek | el | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Estonian | et | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Finnish | fi | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| French | fr | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Hebrew | he | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Croatian | hr | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Hungarian | hu | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Icelandic | is | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Italian | it | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Japanese | ja | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Korean | ko | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Dutch | nl | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Norwegian | no | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Polish | pl | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Romanian | ro | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Russian | ru | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Slovak | sk | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Swedish | sv | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Turkish | tr | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Ukrainian | uk | 0/335 | 0 | 335 | ⬜ English fallback | pass |
| Chinese | zh | 0/335 | 0 | 335 | ⬜ English fallback | pass |

**Fully translated: 5 · English fallback: 24 · Total: 29.**

## What changed in this overhaul

- Removed 28 unused, low-quality `attranslate` `locale/*.json` files.
- Rewrote `tools/update-translations.sh` into an idempotent gettext pipeline
  (`LC_ALL=C.UTF-8`, KLocalizedString keywords, `CHARSET`→`UTF-8`, dropped
  `POT-Creation-Date`, `msgfmt --check-format`, non-zero exit on failure).
- Added `tools/check-po.py` for placeholder/plural consistency, wired into
  `tools/validate.sh` alongside per-catalog `msgfmt --check --check-format`.
- Regenerated the `.pot` (335 messages) and all 29 `.po`.
- Completed en/pt/pt_BR/es/de to 335/335, 0 fuzzy, fixing the German literal-%
  format issue.
- Reset the other 24 catalogs to clean, correctly-pluralized empty catalogs
  (fixing broken `INTEGER/EXPRESSION` plural placeholders for `zh` and `is`).
- Recompiled all 29 `.mo`.
- Documented the pipeline, strategy, QA and tests under `docs/i18n/`.

## Validation status

- `tools/validate.sh` — **passed**.
- `tools/check-po.py` — 0 placeholder/plural errors across 29 catalogs.
- Pipeline idempotent (verified by double run).
- Runtime lookups verified for pt_BR and de, including plural selection; fallback
  verified for untranslated locales. See [06-TEST-MATRIX.md](06-TEST-MATRIX.md).

## How to add a language

See [02-GETTEXT-PIPELINE.md](02-GETTEXT-PIPELINE.md) → "Adding a new language"
and the quality bar in [03-TRANSLATION-STRATEGY.md](03-TRANSLATION-STRATEGY.md).
Native-speaker contributions for any of the 24 fallback languages are welcome.
