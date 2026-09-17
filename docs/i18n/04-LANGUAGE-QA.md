# 04 — Per-Language QA

_Last updated: 2026-09-17_

QA notes for the fully translated languages. Each was checked for 335/335
coverage, 0 fuzzy, correct placeholders, correct plural forms, and clean
`msgfmt`/`check-po.py` runs. Runtime lookups were verified by loading the
compiled `.mo` through the gettext domain `plasma_applet_ChatAI-Plasmoid`
(see [06-TEST-MATRIX.md](06-TEST-MATRIX.md)).

## Plural forms in use

| Language | `Plural-Forms` | Forms |
| --- | --- | ---: |
| en, es, pt, pt_BR, de | `nplurals=2; plural=(n != 1);` | 2 |

The 24 fallback catalogs carry the correct rule for their locale even though
they are empty, so a future translator inherits the right plural structure. A
few noteworthy ones:

| Language | `Plural-Forms` | Forms |
| --- | --- | ---: |
| fr | `nplurals=2; plural=(n > 1);` (0 is singular) | 2 |
| ja, zh | `nplurals=1; plural=0;` | 1 |
| pl | `…n%10>=2 && n%10<=4 …` | 3 |
| ru | `…n%10==1 && n%100!=11 …` | 3 |
| cs | `(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2` | 3 |
| is | `(n%10!=1 \|\| n%100==11)` | 2 |

## Language-specific checks

### German (`de`)
- The literal-percent trap was fixed: progress strings use `%1%`, not `%1 %`
  (a space before `%` fails `msgfmt --check-format` js-format).
- Runtime spot-check: "Back" → "Zurück", "More actions" → "Weitere Aktionen",
  "Close and release memory" → "Schließen und Speicher freigeben".
- Plural spot-check: `n=1` → "Ein Download läuft"; `n=2` → "%1 Downloads laufen".
- German compounds are long; see
  [05-RTL-AND-LAYOUT-QA.md](05-RTL-AND-LAYOUT-QA.md) for layout notes.

### Spanish (`es`)
- Runtime spot-check: "Back" → "Atrás", "Downloads" → "Descargas",
  "Camera" → "Cámara".
- Inverted punctuation (¿ ¡) used where appropriate.

### Portuguese (`pt`) and Brazilian Portuguese (`pt_BR`)
- Kept as two catalogs because vocabulary differs (e.g. "screen sharing",
  "clipboard"). Both at 335/335.
- Runtime spot-check (pt_BR): "More actions" → "Mais ações",
  "Notifications" → "Notificações", plural `n=1` → "Um download em andamento".
- Technical borrowings like "download" are kept where they are the common usage.

### English (`en`)
- Identity catalog: `msgstr` equals `msgid`. Serves as the coverage reference
  and guarantees the fallback text is exactly the reviewed source.

## Known-acceptable warnings

`msgfmt --check` emits header warnings for the empty fallback catalogs
("`PO-Revision-Date` still has the initial default value",
"`Language-Team` still has the initial default value"). These are cosmetic
header defaults on untranslated catalogs, not format errors, and do not affect
the compiled output.
