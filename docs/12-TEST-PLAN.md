# 12 — Plano de testes e resultados

Status: **executado em 2026‑09‑17** (Plasma 6.7.4, Qt/WebEngine 6.11.2, Wayland). Legenda: PASS / FAIL / PARTIAL / N/A / NÃO TESTADO.

Observação de ambiente: a sessão define `QT_LOGGING_RULES=*=false`; todos os testes abaixo foram executados com
`QT_LOGGING_RULES="*.warning=true;*.critical=true;*.info=true;qml=true;js=true;default=true"` para que avisos QML apareçam.

## 1. Estáticos

| Teste | Comando | Resultado |
| --- | --- | --- |
| JSON/XML/qmllint/pacote | `./tools/validate.sh` | PASS (0 avisos do projeto em 30 QML) |
| Metadata AppStream | `kpackagetool6 --type Plasma/Applet --appstream-metainfo .` | PASS (versão, 3 autores, homepage) |
| Parse QML | `qmlformat --check` nos arquivos novos | PASS |
| Catálogos `.po` | `msgfmt --check-format` (30 idiomas) | PASS |
| Pacote sem `docs/`/`.git/` | `tools/validate.sh` | PASS |

## 2. Unitários (`tools/tests/run-unit-tests.sh`, qml6 offscreen)

| Suite | Casos | Resultado |
| --- | --- | --- |
| `Migration.js` | 18 (usuário 1.0.0 completo, instalação nova, notificações desativadas, URLs legadas, idempotência) | PASS 18/18 |
| `ProviderModel.qml` | 28 (20 built‑in, JSON de sites com `,` e `\|` no nome, reatividade de `enabledProviders`, `providerForUrl` exato/prefixo/legado/custom/sem falso positivo, `iconSource` com fallbacks, `isAuthUrl`, UA padrão/compat/custom, serialização) | PASS 28/28 |

## 3. Harness de carregamento (`tools/provider-probe/`, WebEngine 6.11 headless, perfil off‑the‑record)

Resultados completos em `tools/provider-probe/results-2026-09-17-*.jsonl`. Login/chat/upload/mic exigem credenciais → NÃO TESTADO.

| Provider | Load (UA Qt) | Load (UA Chromium) | Campo de entrada anônimo | Login | Chat | Upload | Mic | Download | OAuth | Wayland | X11 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ChatGPT | TIMEOUT (headless) | TIMEOUT (headless) | — | NÃO TESTADO | NÃO TESTADO | NÃO TESTADO | NÃO TESTADO | NÃO TESTADO | NÃO TESTADO | NÃO TESTADO | NÃO TESTADO |
| Claude | PASS (`/login`) | PASS | sim (login) | NÃO TESTADO | … | | | | | | |
| Google Gemini | PASS | PASS | sim | NÃO TESTADO | … | | | | | | |
| DeepSeek | PASS (`/sign_in`) | PASS | não | NÃO TESTADO | … | | | | | | |
| Duck.ai | PASS | PASS | sim | N/A | **PASS** (widget real, Wayland) | N/A | NÃO TESTADO | **PASS** (arquivo salvo) | N/A | **PASS** | NÃO TESTADO |
| Perplexity | PASS | PASS | sim | NÃO TESTADO | … | | | | | | |
| Microsoft Copilot | PASS | PASS | sim | NÃO TESTADO | … | | | | | | |
| GitHub Copilot | PASS (3/3 após 1 erro de rede transitório) | PASS | login | NÃO TESTADO | … | | | | | | |
| Mistral Vibe | PASS ("Vibe Chat") | PASS | não | NÃO TESTADO | … | | | | | | |
| Grok (`grok.com`) | PASS | PASS | sim | NÃO TESTADO | … | | | | | | |
| Qwen | PASS ("Qwen Studio") | PASS | sim | NÃO TESTADO | … | | | | | | |
| Kimi | PASS | PASS | sim | NÃO TESTADO | … | | | | | | |
| Manus | PASS (`/login`) | PASS | não | NÃO TESTADO | … | | | | | | |
| HuggingChat | PASS | PASS | sim | NÃO TESTADO | … | | | | | | |
| Meta AI | PASS | PASS | não | NÃO TESTADO | … | | | | | | |
| T3 Chat | PASS | PASS | sim | NÃO TESTADO | … | | | | | | |
| You.com | PASS (`/signin`) | PASS | não | NÃO TESTADO | … | | | | | | |
| BlackBox | PASS | PASS | não | NÃO TESTADO | … | | | | | | |
| LobeChat | PASS (`app.lobehub.com/signin`) | PASS | não | NÃO TESTADO | … | | | | | | |
| Big‑AGI | PASS | PASS | não | NÃO TESTADO | … | | | | | | |

"…" = mesma situação da coluna Login (sem credenciais nesta sessão). Duck.ai foi exercitado no widget real porque não exige conta.

## 4. Funcional automatizado no widget real (`plasmoidviewer -a .` Wayland, sequência de timers em build de teste)

| Passo | Verificação | Resultado |
| --- | --- | --- |
| Carregar | `webviewRoot` não nulo, URL `https://duck.ai/chat`, título da página | PASS |
| Back/Forward | `canGoBack` false na primeira página (botões desabilitados) | PASS |
| Zoom | `zoomIn()` 100→110 %, `zoomReset()` 100 %, `setZoom(1.25)` 125 %; `zoomFactor` persistido em `plasmoid.configuration` | PASS |
| Permissão (Ask) | `Notification.requestPermission()` na página → `pendingPermission` para `https://duck.ai/` tipo Notifications; `resolvePendingPermission(false)` → página recebe `denied`; `listAllPermissions()` retorna 1 entrada `Denied` persistida | PASS |
| Download | `a[download]` com Blob → 1 item, estado Completed, arquivo gravado na pasta configurada, `activeDownloadCount` 0 | PASS |
| Lifecycle | `hidden=true` → `visible=false`; após 36 s: `lifecycleState=Frozen`, `recommendedState=Discarded`, `busy=false`; `hidden=false` → Active e visível | PASS |
| Cache | `clearHttpCache()` → `clearingCache` true → false após `clearHttpCacheCompleted` | PASS |
| Painel interno | `openSettings("permissions")` → `settingsOpen`, categoria correta | PASS |
| Close | `closeWebView()` → `webviewRoot === null`, `expanded=false`, renderer encerrado (0 processos `--type=renderer` descendentes do viewer) | PASS |
| Submenu Zoom do ⋮ | `menuAt(4).itemAt(0).triggered()` → 100 → 110 % | PASS (após correção do id `chatAiMenu`) |
| Avisos QML do projeto | após correções: nenhum TypeError/ReferenceError do ChatAI; restam avisos de componentes KDE (`ScrollBar`, `FormLayout`) e do próprio viewer | PASS |

## 5. Visual (capturas com `spectacle` do `plasmoidviewer`)

Barra na ordem obrigatória (📌 ← → ↻ [Duck.ai ▼] ⋮ ✕ em largura estreita, com Home/🔍/👁/⬇ movidos para o ⋮), menu ⋮ com submenus Zoom/Downloads/Configurações, painel Sites (ícones, switches, descrições, notas de login), painel Sobre (versão 1.0.1, três autores, atalhos), página Duck.ai com `forceDarkMode`. PASS.

## 6. Migração

Cenários do `Migration.js` cobertos por unit test (seção 2). No viewer, a configuração nova é migrada para `configVersion=1` na primeira execução (log `ChatAI: configuration migrated to schema 1`). PASS.

## 7. Instalação

`kpackagetool6 --type Plasma/Applet --upgrade build/ChatAI-Plasmoid.plasmoid` sobre a 1.0.0 instalada: PASS (metadata 1.0.1, `settings/` com 9 páginas, `ProviderModel.qml` presente, pacote listado). Instalação limpa/remoção: mesmo pacote via `--install`/`--remove` (não executado para não remover as instâncias do usuário).

## 8. Não testado nesta sessão (motivo)

- Login, chat autenticado, upload, microfone, OAuth de cada provedor: sem credenciais.
- Tela cheia real: a API (`Window.visibility = FullScreen`, reparenting) foi implementada e lintada, mas o teste tomaria a tela do usuário durante a sessão; fica como PARTIAL (código) até teste manual.
- X11: sessão indisponível.
- HiDPI 125–200 %: apenas por construção (SVG + `Kirigami.Units`).
- Leitor de tela: `Accessible.name` definido em todos os controles; não verificado com Orca.
