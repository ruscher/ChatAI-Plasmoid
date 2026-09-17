# 01 — English Source Strings

_Last updated: 2026-09-17_

English (US) is the **single source language**. Every translatable string is
written in English directly in the QML/JS sources and wrapped in a KDE
`KLocalizedString` call. Translators never edit the source; they edit the `.po`
catalogs generated from it.

## Which function to use

| Function | Use for | Example |
| --- | --- | --- |
| `i18n(text, args…)` | A plain string, optionally with placeholders | `i18n("Back")`, `i18n("%1 MiB", value)` |
| `i18nc(context, text, args…)` | A string whose meaning is ambiguous without context | `i18nc("@action:button", "Open")` |
| `i18np(singular, plural, n, args…)` | A count-dependent string | `i18np("One download failed", "%1 downloads failed", n)` |
| `i18ncp(context, singular, plural, n, args…)` | Plural **and** context | rare; supported by the pipeline |

## Rules for authors

1. **Wrap everything the user can read.** Labels, tooltips, `Accessible.name`,
   dialog titles/subtitles, menu entries, notification text.
2. **Never concatenate translated fragments.** Build one sentence with numbered
   placeholders (`%1`, `%2`) so translators can reorder for their grammar.
   - Bad: `i18n("Downloaded ") + name + i18n(" files")`
   - Good: `i18n("Downloaded %1 files", name)`
3. **Use plurals for counts.** Any string that varies with a number must use
   `i18np`, even in English where only two forms exist — other languages need
   up to six.
4. **Add context when a word is ambiguous.** "Open" (verb vs. state), "Home"
   (page vs. building). Use `i18nc` with a short, stable context string.
5. **Keep placeholders identical** between singular and plural, and never place
   a literal `%` next to a placeholder without escaping it as `%1%`
   (a bare `%1 %` breaks `msgfmt --check-format`; see
   [02-GETTEXT-PIPELINE.md](02-GETTEXT-PIPELINE.md)).
6. **Escape embedded quotes** with `\"` inside the string literal.
7. **Do not translate technical tokens** — URLs, SPDX identifiers, profile-name
   regexes, MIME types.

## Placeholders reference

- `%1`, `%2`, … — positional arguments, substituted by KLocalizedString.
- `%n` / `%1` in plural forms — the count.
- A literal percent sign written next to a number placeholder must be `%1%`,
  not `%1 %`.

## Non-translatable literals (intentional)

These stay in English/technical form on purpose:

- `"https://…"` and `"https://example.com/chat"` — URL placeholders.
- `"GPL-2.0-or-later"` — SPDX license identifier.

## metadata.json

The plasmoid's `metadata.json` `Name` ("ChatAI") and `Description` are **not**
currently extracted into the gettext catalog — see
[03-TRANSLATION-STRATEGY.md](03-TRANSLATION-STRATEGY.md) for the decision and
rationale. The in-widget "ChatAI" title string *is* translatable because it is
also authored as an `i18n("ChatAI")` call in the QML.
