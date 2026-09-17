# 07 — Validação final

Data: 2026‑09‑17. Ambiente: Plasma 6.7.4, Qt/Qt WebEngine 6.11.2, Wayland. Pacote reinstalado com `kpackagetool6 --upgrade`.

## Estático e unitário

| Teste | Resultado |
| --- | --- |
| `./tools/validate.sh` (JSON, XML, qmllint 30+ QML, .po, pacote) | PASS |
| `./tools/tests/run-unit-tests.sh` — Migration 20 · Downloads 24 · ProviderModel 42 | PASS (3/3 suites) |
| Instanciação fora do Plasma (`DownloadIndicator`) | PASS |
| Viewer sem TypeError/ReferenceError do projeto | PASS |

## Google OAuth (widget real, logs host+caminho)

| Cenário | Antes | Depois |
| --- | --- | --- |
| ChatGPT → "Continue with Google" | `authorize` cancelado (`ERR_ABORTED` no mesmo ms, sem rede); nada acontece / spinner | `authorize → 302 → accounts.google.com/v3/signin/identifier` ("Sign in - Google Accounts") na view principal |
| Claude → "Continue with Google" (`window.open` 500×550) | popup descartado; view principal navegava; callback sem `opener` → branco/loop | `AuthPopup` abre com `accounts.google.com/v3/signin/identifier` |
| Mock OAuth local (popup → IdP → callback → `opener.postMessage` → `window.close()`) | `CALLBACK_NO_OPENER`, app nunca autentica | `CALLBACK_POSTED` → app recebe `AUTH_OK (opener=yes)` → `windowCloseRequested` → popup fecha |
| Login completo com credenciais reais (e‑mail, senha, 2FA, consentimento, sessão persistente) | — | **NÃO TESTADO nesta sessão** (sem credenciais); roteiro em 04 |

## Toolbar

| Critério | Resultado |
| --- | --- |
| "Hide the toolbar" sem botão permanente; só no ⋮ (checkable) | PASS |
| Downloads sem botão permanente; sempre no ⋮ | PASS |
| Overflow não move mais esses dois | PASS |
| Toolbar: 📌 ← → ↻ ⌂ [IA] 🔍 (↓) ⋮ ✕ | PASS (captura) |

## Downloads (widget real, 2 Blobs 3 MB + 1 MB + PDF)

| Critério | Resultado |
| --- | --- |
| indicador surge ao iniciar (`show=true active=1`) | PASS |
| progresso real (bytes ponderados) | PASS (unit) — arquivos locais concluem em ms |
| clique abre a lista; itens com estado/tamanho; popup dentro da janela, alinhado à direita | PASS (captura 1500×950) |
| Pause/Resume/Cancel | funções ligadas ao `WebEngineDownloadRequest`; **NÃO EXERCITADO** (Blob local termina antes) |
| concluído → Abrir / Mostrar na pasta | PASS (`openDownload`, `showDownloadInFolder` via FileManager1) |
| aberto → `seen`; indicador some com `attention=0` | PASS (`show=false`) |
| histórico no ⋮ → Downloads | PASS |
| múltiplos simultâneos | PASS (2) |
| erros | Interrupted → badge !, Tentar de novo (código); **NÃO EXERCITADO** |
| notificações | `Notification` com ações Abrir/Mostrar na pasta (código; KNotification exibida pelo Plasma) |
| vazamento | `downloadCache` vazio ao final; sinais desconectados | PASS |

## Wayland / X11

Wayland: todos os testes acima. X11: NÃO TESTADO (sem sessão). Nenhuma dependência de X11 introduzida.

## Limitações reais

- Login real com conta Google exige credenciais do usuário (roteiro 04). Passkey/WebAuthn sem UI (`webAuthUxRequested`); usar alternativa oferecida pelo Google.
- ChatGPT pode reter a conexão (0 %) por anti‑bot — aviso com Tentar de novo (rodada anterior).
- Popups `window.open` comuns agora abrem dentro do widget (janela auxiliar); `target=_blank` continua no navegador.

## Avisos pendentes

Nenhum aviso QML do projeto nas execuções finais. Restam avisos de componentes KDE (`ScrollBar`, `FormLayout`) e do próprio `plasmoidviewer`.
