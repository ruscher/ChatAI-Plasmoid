# 13 — Release 1.0.1

## Metadata
- `KPlugin.Version`: `1.0.1` (campo oficial de KPluginMetaData; exposto em QML por `plasmoid.metaData.version`).
- Autores: Denys Madureira, Bruno Gonçalves (preservados) + Rafael Ruscher <rruscher@gmail.com>.
- Website: `https://github.com/ruscher/ChatAI-Plasmoid`; BugReportUrl idem `/issues`.
- `X-Plasma-API-Minimum-Version`: `6.0`.

## Commits temáticos (locais, sem push)
1. `docs: add 1.0.1 engineering plan and archive previous audit`
2. `fix: normalize pin state, auto-hide button key, download controls and header layout`
3. `refactor: make ProviderModel the single source of truth with reactive enabled list`
4. `feat: redesign toolbar order, AI selector and add kebab menu`
5. `feat: shared settings pages for Plasma dialog and in-widget panel`
6. `feat: zoom and real fullscreen`
7. `security: per-origin WebEngine permissions and safer defaults`
8. `perf: lifecycle freezing, native favicon, no WebEngine in config`
9. `feat: add GitHub Copilot, Manus, Qwen, Kimi and Mistral Vibe providers`
10. `chore: bump ChatAI to 1.0.1, README, translations`

## Lista de aceite
(ver enunciado em 00; marcada em 14 com evidência)

## Migração de dados (`configVersion` 0 → 1)
`keepOpen`→`pin`; `hidePrintButton`→`hideAutoHideButton`; `customSites`→`customSitesJson`;
`*Enabled`→`*Policy`; URLs legadas (`x.com/i/grok`→`grok.com`, `duckduckgo.com/chat`→`duck.ai/chat`) → URL canônica.
Idempotente: só roda quando `configVersion < 1`.

## Tradução
`xgettext` (modo JavaScript, keywords `i18n`, `i18nc`, `i18np`, `i18ncp`) gera `locale/ChatAI-Plasmoid.pot`;
`msgmerge --update` em cada `.po` preserva traduções existentes; `msgfmt` gera
`contents/locale/<lang>/LC_MESSAGES/plasma_applet_ChatAI-Plasmoid.mo`. Script: `tools/update-translations.sh`.
Os `.json` em `locale/` são cache do fluxo legado (attranslate) e não são usados em runtime.
