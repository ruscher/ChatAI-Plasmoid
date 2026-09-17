# 02 — Gettext Pipeline

_Last updated: 2026-09-17_

ChatAI-Plasmoid localizes through the standard GNU **gettext** toolchain. There
is no custom translation system.

```
contents/ui/**/*.qml, *.js
        │  xgettext
        ▼
locale/ChatAI-Plasmoid.pot            (message template — 335 messages)
        │  msgmerge  (per language, keeps existing translations)
        ▼
locale/<lang>.po                      (29 catalogs — the translation sources)
        │  msgfmt --check-format
        ▼
contents/locale/<lang>/LC_MESSAGES/plasma_applet_ChatAI-Plasmoid.mo   (runtime)
```

At runtime Plasma loads the compiled `.mo` under
`contents/locale/<lang>/LC_MESSAGES/` for the gettext **domain**
`plasma_applet_ChatAI-Plasmoid`. The `.pot`/`.po` files in `locale/` are
development sources and are never read at runtime.

## Regenerating everything

```bash
./tools/update-translations.sh
```

This script:

1. Sets `LC_ALL=C.UTF-8` so gettext reads/writes UTF-8 regardless of the
   caller's shell locale (a non-interactive shell otherwise trips on
   multibyte data).
2. Extracts strings with `xgettext`:
   - `--language=JavaScript` (QML/JS), `--from-code=UTF-8`, `--no-wrap`.
   - Keywords: `-ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3`.
   - `--add-comments=i18n` to carry `// i18n:` translator notes into the catalog.
3. Normalizes the template: replaces the `CHARSET` placeholder with `UTF-8` and
   **drops the volatile `POT-Creation-Date` header** so re-runs are diff-free.
4. `msgmerge --previous --update --backup=none --no-wrap` for each `.po`,
   preserving existing translations and marking changed entries fuzzy.
5. `msgfmt --check-format` to compile each `.mo`; the script exits non-zero if
   any catalog fails format checks.

**Idempotency:** running the script twice with no source changes produces no
diff. This is verified as part of QA.

## Adding a new language

```bash
export LC_ALL=C.UTF-8
msginit --no-translator --no-wrap --locale=<lang> \
        --input=locale/ChatAI-Plasmoid.pot \
        --output-file=locale/<lang>.po
sed -i '/^"POT-Creation-Date:/d' locale/<lang>.po
```

`msginit` writes the correct `Plural-Forms` header for the locale. After
translating, run `./tools/update-translations.sh` to compile.

> Note: `msginit` occasionally leaves the placeholder
> `Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;` for a few locales
> (observed for `zh` and `is`). Always confirm the header holds a real rule
> before committing — `tools/check-po.py` and `msgfmt` will otherwise accept an
> empty catalog with a broken plural rule.

## Validation

```bash
python3 tools/check-po.py [--strict]   # placeholder + plural-form consistency
./tools/validate.sh                    # full package build + all checks
```

`check-po.py` verifies that placeholders (`%1`, `%2`, `%n`) match between
`msgid`/`msgstr`, that plural entries have the right number of forms for their
`Plural-Forms` rule, and reports untranslated + fuzzy counts. Placeholder
mismatches are errors for non-fuzzy entries and warnings for fuzzy ones.
`validate.sh` additionally runs `msgfmt --check --check-format` over every
catalog before packaging.

## Common pitfalls

- **`LC_ALL` unset** in CI/non-interactive shells → gettext "invalid multibyte
  sequence". Always export `C.UTF-8`.
- **`%1 %`** (space before a literal percent) fails `msgfmt --check-format`
  js-format. Write `%1%`.
- **`msgattrib`** on legacy `attranslate` catalogs corrupted them; do not use it
  to clear fuzzies here. Use `msginit` for a clean reset.
- **Editing the `.pot` by hand** — never; it is generated. Edit the sources.
