# 02 — Causa raiz: login com conta Google não concluía

Status: **diagnosticado e corrigido**; prova em 07. Nada de credenciais, tokens ou query strings foi registrado —
todos os logs usam apenas host + caminho.

## Sintomas relatados

"Continuar com o Google" → página do Google (às vezes), e‑mail, senha… e então: carregamento infinito, página em
branco/preta, ou simplesmente nada acontece ao clicar; o serviço nunca recebe a sessão.

## Reprodução

1. Widget real (`plasmoidviewer`, sessão Wayland), build instrumentada (host+caminho): ChatGPT `/auth/login` → clique
   em "Continue with Google" → `navigationRequested(type=LinkClicked, main frame, auth.openai.com/api/accounts/authorize)`
   → `loadingChanged(LoadStarted)` → **`loadingChanged(LoadFailed, net::ERR_ABORTED)` no mesmo milissegundo** → a página
   fica em `chatgpt.com/auth/login`. *Net log* do Chromium: **nenhuma requisição de rede** para `auth.openai.com`.
2. Mesmo clique num `WebEngineView` puro (sem handlers do ChatAI), com o mesmo perfil persistente e as mesmas
   `WebEngineSettings` (bisect em 4 variantes): `authorize → 302 → accounts.google.com/o/oauth2/v2/auth → …/signin/identifier`
   carrega normalmente. Logo, o cancelamento vinha dos handlers do widget.
3. Claude: o clique gera `newWindowRequested(destination=NewViewInDialog, 500×550, accounts.google.com/o/oauth2/v2/auth)`
   — fluxo por **popup** (`window.open`).
4. Mock local (`tools`/scratch: página que abre popup → IdP → callback → `opener.postMessage` → `window.close()`):
   com o handler antigo, o callback termina em `CALLBACK_NO_OPENER` e o app nunca autentica; com `openIn()` numa view
   auxiliar, `AUTH_OK` e o popup fecha via `windowCloseRequested`.

## Causa 1 (ChatGPT e todo fluxo por redirect) — `isHttpUrl` rejeitava a URL OAuth

`contents/ui/WebView.qml`, `onNavigationRequested`:

```qml
const requestedUrl = String(request.url);
if (!webViewRoot.isHttpUrl(requestedUrl)) { request.action = WebEngineNavigationRequest.IgnoreRequest; return; }
```

com `ProviderModel.isHttpUrl = /^(https?):\/\/[^\s]+$/`. Comportamento do Qt envolvido: **`QUrl` convertida para string
em QML é "pretty decoded"** — `%20` no query vira espaço literal. A URL de autorização do Google/OpenAI contém
`scope=openid profile email …`; a string tem espaços; `[^\s]+$` falha; o handler **cancela a navegação**
(`IgnoreRequest` ⇒ `ERR_ABORTED` antes da rede). O mesmo filtro em `onNewWindowRequested` derrubava o popup do Claude
(`accounts.google.com/o/oauth2/v2/auth?…scope=openid email profile`). Presente desde a 1.0.0 (`isHttpUrl` idêntico).

Correção: `isHttpUrl` valida apenas esquema e host (`/^https?:\/\/[^\s\/?#]+([\/?#]|$)/`); `normalizeUrl` (entrada do
usuário) continua rejeitando espaços. Testes unitários novos cobrem URL com `scope` decodificado, host com espaço,
`ftp:`/`mailto:`/`about:blank`.

## Causa 2 (Claude, Perplexity e qualquer login por `window.open`) — popup convertido em navegação

`onNewWindowRequested` descartava o pedido e fazia `webview.url = url` na view principal. A página de callback do IdP
roda então **sem `window.opener`**: `postMessage` não chega ao app, `window.close()` não fecha nada, e a view principal
fica na página de callback (em branco/preta) ou o app segue "aguardando" o popup — exatamente os sintomas.

Correção: `AuthPopup.qml` — view auxiliar criada sob demanda (Loader) com o **mesmo `WebEngineProfile`**; o pedido é
entregue com `request.openIn(view)` (opener, `postMessage` e `window.close()` preservados); `windowCloseRequested`
fecha e destrói o popup; cabeçalho com host, cadeado, indicador de carregamento e ✕; Esc fecha; popups aninhados vão para o
navegador; permissões e certificados seguem a mesma política da view principal. Política: destino Dialog/Window,
popups que começam em `about:blank`, ou URLs de autenticação → popup interno; `target=_blank` comum → navegador externo.
Também corrigido: a view auxiliar recebe `renderProcessTerminated` (encerramento normal) ao adotar a página do
`openIn` — só fecha em Crashed/Killed.

## Causa 3 (segurança, achada na auditoria) — `isAuthUrl` por substring

`host.indexOf("accounts.google.com") !== -1` aceitava `accounts.google.com.evil.example`; a entrada `"clerk"` casava
qualquer host contendo "clerk". Reescrito com host exato/subdomínio e prefixos de caminho; testes negativos incluídos.

## O que não era a causa (medido)

- User-Agent: o Google **aceita** a identidade honesta do Qt WebEngine e **rejeita** UA disfarçado (docs/05); mantido o padrão.
- Perfil/cookies/`WebEngineSettings`: bisect sem efeito.
- Client Hints: idênticos a um Chromium.
- Lifecycle Frozen: `busy` já incluía carregamento; agora inclui `authPopupOpen`.

## Prova da correção

Ver 07: no widget real, ChatGPT → Google chega à página de identificador na view principal; Claude → popup interno
carrega `accounts.google.com`; mock local termina em `AUTH_OK` com o popup fechado. Login com credenciais reais: roteiro em 04.
