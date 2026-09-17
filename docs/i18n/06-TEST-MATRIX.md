# 06 — Test Matrix

_Last updated: 2026-09-17_

How the i18n work is verified. All checks run on 2026-09-17 against
ChatAI-Plasmoid 1.0.1.

## Automated checks

| Check | Tool | Result |
| --- | --- | --- |
| Template extraction is complete | `xgettext` via `update-translations.sh` | 335 messages, 27 source files |
| No hardcoded UI strings | grep scan of `contents/ui/` | only 3 intentional literals (URLs, SPDX) |
| Placeholder/plural consistency | `tools/check-po.py` | 0 errors across 29 catalogs |
| Format check per catalog | `msgfmt --check --check-format` | all 29 compile; only benign header warnings |
| Full package build | `tools/validate.sh` | **passed** |
| Pipeline idempotency | run `update-translations.sh` twice, compare | identical (no diff) |
| Runtime lookup | Python `gettext` against compiled `.mo` | translations resolve; fallback = English |

## Runtime lookup verification

Because a headless session cannot reliably screenshot `plasmoidviewer`, runtime
correctness was verified by loading the shipped `.mo` files through the exact
gettext domain Plasma uses (`plasma_applet_ChatAI-Plasmoid`) and resolving real
message ids:

```
pt_BR  "ChatAI Settings"          -> "Configurações do ChatAI"
pt_BR  "More actions"             -> "Mais ações"
pt_BR  ngettext(download, 1)      -> "Um download em andamento"
pt_BR  ngettext(download, 2)      -> "%1 downloads em andamento"
de     "ChatAI Settings"          -> "ChatAI-Einstellungen"
de     "Close and release memory" -> "Schließen und Speicher freigeben"
de     ngettext(download, 1)      -> "Ein Download läuft"
de     ngettext(download, 2)      -> "%1 Downloads laufen"
fr/ja/zh (untranslated)           -> English source (clean fallback)
```

This confirms: singular/plural selection works, placeholders survive, primary
languages translate, and untranslated languages fall back to valid English.

## Manual plasmoid test (recommended before a release)

A non-headless environment should additionally run the widget under a couple of
locales. On the maintainer's Plasma 6 desktop:

```bash
# Install/refresh the widget
kpackagetool6 --type Plasma/Applet --upgrade . || \
kpackagetool6 --type Plasma/Applet --install .

# Run in German, then Brazilian Portuguese
LANGUAGE=de   plasmoidviewer -a org.kde.plasma.chatai
LANGUAGE=pt_BR plasmoidviewer -a org.kde.plasma.chatai
```

Verify: toolbar tooltips, kebab menu, all Settings pages, permission prompts,
and download strings appear in the selected language, and that switching to an
untranslated locale (e.g. `LANGUAGE=fr`) shows clean English.

> Environment note: `QT_LOGGING_RULES` is disabled globally on this machine;
> override it if QML warnings need to be visible during the manual test. An
> offscreen `plasmoidviewer` does not render reliably here — use a real session.

## Re-running everything

```bash
export LC_ALL=C.UTF-8
./tools/update-translations.sh   # regenerate .pot/.po/.mo
python3 tools/check-po.py        # consistency
./tools/validate.sh              # full build + checks + package
```
