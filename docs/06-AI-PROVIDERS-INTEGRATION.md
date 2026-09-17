# 06 — Integração de provedores (registro único)

Status: **implementado** (evidências em 12 e 14).

## Problema
Listas paralelas: `builtInProviders` (dados), `availableIcons` no CompactRepresentation (ícones),
16 handlers no Header (reatividade), texto do Claude hardcoded na configuração (notas).
Adicionar um provedor exigia editar 4 lugares + `main.xml`.

## Solução: `ProviderModel.qml` como single source of truth

Cada entrada:

```js
{ id, name, url, legacyUrls: [], configKey, defaultEnabled, iconId, iconStyles: ["colorful","filled","outlined"],
  category: "general|search|code|privacy|agent", description, requiresLogin, supportsMicrophone,
  supportsCamera, supportsUpload, supportsNotifications, supportsWebSearch, userAgent (opcional),
  loginNotes, compatibilityNotes }
```

API reativa:
- `providers` (built‑in + custom) e `enabledProviders` (binding que lê `plasmoid.configuration[configKey]`
  e `customSitesJson`; recalcula automaticamente — sem `Connections` nem Timer).
- `providerForUrl(url)` (inclui `legacyUrls`), `iconSource(provider, mode, contrast)`, `isAuthUrl(url)`,
  `customProviders()` (JSON com fallback ao formato `nome|url`), `serializeCustomProviders(list)`.
- UA: `effectiveUserAgent(defaultUa, provider)` — remove `QtWebEngine/…`; `customUserAgent` tem precedência.

Consumidores: `Header/AiSelector` (lista, ícone, nome), `CompactRepresentation` (ícone/nome),
`settings/SitesSettings` (switches, notas, categorias), `WebView` (UA, home, auth).

## Adicionar um provedor novo = 2 lugares
1. Entrada em `builtInProviders`.
2. `<entry name="showX" type="Bool">` em `main.xml` (KConfig exige declaração).
(+ SVGs em `assets/`.)

## Novos provedores (1.0.1)

| id | Nome | URL | configKey | categoria |
| --- | --- | --- | --- | --- |
| `githubcopilot` | GitHub Copilot | `https://github.com/copilot` | `showGitHubCopilot` | code |
| `manus` | Manus | `https://manus.im/app` | `showManus` | agent |
| `qwen` | Qwen | `https://chat.qwen.ai` | `showQwen` | general |
| `kimi` | Kimi | `https://www.kimi.com` | `showKimi` | general |
| `mistral` | Mistral Vibe | `https://chat.mistral.ai` | `showMistral` | general |

## Alterações em existentes
- `copilot`: nome "Microsoft Copilot" (chave `showBingCopilot` mantida).
- `duckduckgo`: URL `https://duck.ai/chat` (legacy `https://duckduckgo.com/chat`), sem UA mobile.
- `grok`: URL `https://grok.com` (legacy `https://x.com/i/grok`), sem UA mobile.
- `chatgpt`, `deepseek`: sem `userAgent` específico (o UA global já não tem o token).

## Migração de URL
Se `url` configurada casa com um `legacyUrls`, é reescrita para a URL canônica (configVersion 0 → 1).

## Testes
Harness de carregamento (05) para todos; seleção no seletor; ícone no painel; Home; troca de provedor
sem recriar o perfil; notas exibidas na página Sites.
