# 14 — Auditoria final: ChatAI 1.0.1

Data: 2026‑09‑17. Ambiente: Plasma 6.7.4, KF6 (Kirigami 6.29), Qt/Qt WebEngine 6.11.2 (Chromium 140), Wayland.
Evidências detalhadas: `12-TEST-PLAN.md`; medições: `09-PERFORMANCE-MEMORY-LIFECYCLE.md`.

## Resumo

A 1.0.1 reorganiza a barra na ordem obrigatória, adiciona o menu ⋮ (zoom, tela cheia, configurações por
categoria, atalhos, sobre, DevTools opcional), substitui a tela única de configurações por nove páginas
compartilhadas entre o diálogo do Plasma e um painel interno do widget, moderniza permissões (por origem,
`StoreOnDisk`, prompt inline, revisão/reset), adota UA padrão do Qt com opção de compatibilidade, usa o favicon
nativo do WebEngine, congela a página oculta via `lifecycleState`, corrige bugs de estado (pin/keepOpen, botão
auto‑hide, pause/cancel de downloads, MouseArea no layout, guards), adiciona 5 provedores (GitHub Copilot,
Manus, Qwen, Kimi, Mistral Vibe), migra configurações antigas e atualiza metadata, README, docs e traduções.

## Bugs encontrados e corrigidos

| Bug | Causa | Correção | Teste |
| --- | --- | --- | --- |
| Pausar/cancelar download não funcionava | `downloadCache[id]` gravado com dois formatos; `.cancel()` chamado em `{download, updateConnection}` | formato único; funções usam `entry.download` | download real no viewer (estado, arquivo), controles habilitados |
| Botão auto‑hide controlado por `hidePrintButton` | reutilização de chave de Print | `hideAutoHideButton` + migração | unit test Migration; Aparência |
| `keepOpen` órfão × `pin` | duas chaves para o mesmo estado | `pin` única; migração `keepOpen→pin`; `hideOnWindowDeactivate` na raiz | unit test; viewer |
| MouseArea do auto‑hide ocupava célula do `RowLayout` | filho de layout com `Layout.fill*` | `HoverHandler` (não participa do layout) | visual |
| Ações da barra sem WebView → TypeError | `webviewRoot.goBack()` sem guard | `enabled: hasWebView && …`, guards | Close + barra |
| `loadOnStartup` abria o popup no login | `root.expanded = true` no `onCompleted` | pré‑carga só via `Loader.active` (depende do preload do Plasma) | código |
| Configuração instanciava WebEngine | `WebEngineProfilePrototype` só para caminhos | caminhos por `StandardPaths` | processos |
| Favicon: varredura DOM + `og:image` | JS a cada load | `WebEngineView.icon` | ícone Duck.ai no seletor/painel |
| Reload sempre ignorando cache | `reloadAndBypassCache()` | `reload()`; bypass no ⋮ e no contexto | código |
| Back/Forward sempre ativos | sem binding | `enabled: canGoBack/Forward` | teste automatizado (`canGoBack=false`) |
| Notificações exigiam `.notifyrc` inexistente | `componentName` próprio | `plasma_workspace`/`notification` | código |
| `desktopMediaRequested` sem handler | — | seleciona a primeira tela ou cancela | código |
| Permissões: sem prompt, sem persistência, sem por‑origem | `AskEveryTime` + decisão global | políticas por tipo, prompt inline, `StoreOnDisk`, listagem/reset | teste automatizado (prompt → deny → persistido `Denied`) |
| UA mobile Chrome 76 (DDG/Grok) e Chromium 134 hardcoded | overrides antigos | UA padrão do Qt (+ opção compat), URLs `duck.ai`/`grok.com` | harness 22 URLs × 2 UAs |
| 16 handlers manuais + Timer 50 ms | lista não reativa | `enabledProviders` reativo | unit test de reatividade |
| Binding loop `providerModel: providerModel` (introduzido nesta versão) | nome de propriedade = id | id `providerRegistry` | viewer (erro sumiu) |
| Alias para id dentro de `fullRepresentation` (introduzido) | representações são componentes no Plasma 6 | estado na raiz, itens internos empurram valores | viewer |
| Itens de submenu com `menu.` (introduzido) | `menu` dentro de `MenuItem` é `MenuItem.menu` | id `chatAiMenu` | teste de submenu (100 → 110 %) |
| Avisos: `Unable to assign [undefined] to bool`, i18n sem argumento, binding overwrite | expressões não booleanas; `.arg()` pós‑i18n; assignment sobre binding | `Boolean()`, argumento no `i18n`, `setSource` com props | log limpo |

## Arquivos alterados/criados

| Arquivo | Mudança |
| --- | --- |
| `metadata.json` | versão 1.0.1, autor Rafael Ruscher adicionado (anteriores preservados), descrição |
| `contents/config/main.xml` | schema v1: novas chaves (`configVersion`, `customSitesJson`, `hideAutoHideButton`, `*Policy`, `zoomFactor`, `httpCacheMaximumSize`, `freezeWhenHidden`, `discardAfterMinutes`, `enableDevTools`, `compatibilityUserAgent`, `customUserAgent`, 5 `showX`), 17 chaves sem uso removidas, legadas mantidas para migração |
| `contents/config/config.qml` | 9 categorias |
| `contents/ui/main.qml` | orquestração, migração, pin, painel, lifecycle hidden, Close |
| `contents/ui/ProviderModel.qml` | registro único com metadados, reatividade, ícones, auth, UA, JSON |
| `contents/ui/Migration.js`, `IconModes.js` | novos |
| `contents/ui/Header.qml`, `AiSelector.qml`, `ChatAIMenu.qml` | barra reordenada, seletor com ícones, ⋮ |
| `contents/ui/WebView.qml` | permissões, lifecycle, zoom, fullscreen, downloads, favicon, cache, DevTools |
| `contents/ui/PermissionBar.qml`, `FullScreenWindow.qml`, `DevToolsWindow.qml` | novos |
| `contents/ui/SettingsPanel.qml`, `settings/*.qml` (9), `Config*.qml` (9) | configurações compartilhadas |
| `contents/ui/FindBar.qml`, `DownloadBar.qml`, `CompactRepresentation.qml` | layout/bools/registro |
| `contents/ui/assets/` | +12 SVGs (Manus, Qwen, Mistral, Meta, GitHub Copilot, Kimi); `google.svg` 24 KB→8 KB; `lobechat.svg` 129 KB→52 KB |
| `README.md`, `docs/`, `locale/`, `contents/locale/`, `tools/` | documentação, template `.pot` (300 msgids), catálogos, scripts de validação/tradução/testes/probe |

## Novos provedores

| Provider | URL | Load (WebEngine) | Login/chat |
| --- | --- | --- | --- |
| GitHub Copilot | `https://github.com/copilot` | PASS | NÃO TESTADO (requer conta GitHub) |
| Manus | `https://manus.im/app` | PASS (→ `/login`) | NÃO TESTADO |
| Qwen | `https://chat.qwen.ai` | PASS, campo de entrada anônimo | NÃO TESTADO |
| Kimi | `https://www.kimi.com` | PASS, campo de entrada anônimo | NÃO TESTADO |
| Mistral Vibe | `https://chat.mistral.ai` | PASS ("Vibe Chat") | NÃO TESTADO |

Nenhum provedor existente foi removido; Microsoft Copilot renomeado (chave preservada); Duck.ai e Grok com URLs canônicas e migração.

## Performance (medido, `plasmoidviewer`, Duck.ai, mesma máquina)

| Cenário | 1.0.0 | 1.0.1 |
| --- | --- | --- |
| Renderer RSS aos 25 s (página carregada) | 222,5 MB | 216,7 MB |
| Processo do viewer (inclui browser process in‑process) aos 25 s | 434,7 MB | 445,1 MB (+10 MB: mais QML carregado — menu, seletor com delegates, registro) |
| Renderer CPU (ticks) 25→45 s, visível | +4 | +1 |
| Página oculta 30 s → `lifecycleState` | n/a (sempre Active) | **Frozen** (recomendação do engine: Discarded) |
| Após Close | renderer permanece até destruir a view (igual) | renderer **encerrado** (0 processos), −217 MB; zygotes/browser process permanecem (vivem no processo hospedeiro) |
| plasmashell real, 3 instâncias, WebView fechado (baseline) | 690 MB RSS, 0 processos WebEngine | igual (WebEngine só nasce ao expandir) |

Sem alegações percentuais: em página ociosa o congelamento não muda CPU mensurável; o ganho do Frozen aparece em páginas com timers/streams.

## Segurança

Permissões deny‑by‑default para tipos desconhecidos; nenhum caminho sem `grant()/deny()`; persistência por origem revisável; `javascriptCanPaste` desligado para novos usuários; esquemas desconhecidos só após interação; TLS inválido rejeitado; nomes de download sanitizados; UA padrão; diagnóstico sem dados privados.

## Compatibilidade

Wayland: PASS (viewer, capturas, teste automatizado). X11: NÃO TESTADO (sem sessão). HiDPI: por construção (SVG/`Units`), NÃO TESTADO em escala fracionária nesta rodada. Qt 6.10 mínimo: APIs usadas existem desde 6.8/6.9 (`WebEnginePermission`, `WebEngineProfilePrototype`, `clearHttpCacheCompleted` 6.7).

## Instalação

`kpackagetool6 --type Plasma/Applet --upgrade build/ChatAI-Plasmoid.plasmoid` sobre a 1.0.0 instalada em
`~/.local/share/plasma/plasmoids/ChatAI-Plasmoid`: PASS (metadata 1.0.1, `settings/` presente, páginas antigas removidas).
As três instâncias em execução continuam com o código antigo até o próximo reinício do plasmashell (não reiniciado
durante a sessão do usuário); a migração `configVersion 0→1` roda na primeira carga.

## Pendências

- Testes com credenciais reais (login, chat autenticado, upload, microfone, OAuth) por provedor.
- Teste manual de tela cheia (implementado, não exercitado para não tomar a tela do usuário) e X11.
- Traduções: 300 msgids; textos novos ficam em inglês até tradução humana (52 entradas antigas viraram *fuzzy* e não são usadas — comportamento seguro).
- `renderProcessPid` retornou 0 no viewer durante o teste; diagnóstico exibe o valor da API sem inferência.

## Correções pós‑release (2026‑09‑17, mesma sessão)

- Ícones da barra lateral do painel de configurações agora em tamanho médio (`Kirigami.Units.iconSizes.medium`).
- **Login Google ("Esse navegador ou app pode não ser seguro")**: causa raiz medida — o Google rejeita UA Chrome/Firefox sem a impressão digital correspondente e **aceita a identidade honesta do Qt WebEngine** (página de senha alcançada no perfil real). Correção: `compatibilityUserAgent` volta a desligado por padrão, migração v2 desliga onde havia sido ligado, `stripQtToken` removido do ChatGPT/DeepSeek. Tabela completa em 05.
- Home e troca de provedor agora chamam `webview.stop()` antes de navegar: escapam de páginas em laço de redirecionamento (ex.: ChatGPT bouncing para login Google). Verificado: partindo de ChatGPT preso, selecionar/Home leva ao Duck.ai (100%, título correto).
- ChatGPT: em teste real na sessão, o comportamento é instável — ora carrega 100% e se redireciona sozinho para `chatgpt.com/auth/login_with?connection=google-oauth2` (login Google, **bloqueado pelo Google em WebView**), ora fica em 0% (retenção anti‑bot). Não é bug do widget (Duck.ai carrega na mesma sessão); o uso pleno exige sessão/login por e‑mail e depende do ChatGPT aceitar o ambiente. ChatGPT: login via Google não é contornável.

## Riscos conhecidos

- Google bloqueia OAuth em WebViews (política do Google); documentado na UI.
- Preload no login depende do `preloadWeight` adaptativo do Plasma.
- `PlasmaComponents3.Menu` aninhado emite um aviso interno do Plasma para submenus (mitigado com delegate null‑safe).
