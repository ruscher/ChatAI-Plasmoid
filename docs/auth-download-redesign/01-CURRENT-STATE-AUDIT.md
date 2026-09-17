# 01 — Auditoria do estado atual (ChatAI 1.0.1, `5138b71`)

Fonte de verdade: o código executável em `contents/ui/`, conferido nesta sessão; a documentação em `docs/00…14` é
tratada como contexto, não como prova.

## Login e OAuth hoje

| Aspecto | Implementação atual | Observação |
| --- | --- | --- |
| Onde a página de login abre | Sempre na `WebEngineView` principal | Não existe view auxiliar/popup |
| `onNewWindowRequested` | `request.action = IgnoreRequest`; se `isAuthUrl(url)` → `webview.url = url`; senão → navegador externo | **Descarta o pedido de nova janela** e navega a view principal: o popup perde `window.opener`, `postMessage` e `window.close()` não têm efeito |
| `onNavigationRequested` | main frame só HTTP(S); link clicado com disposição ≠ aba atual → auth na view principal / externo | Redirects HTTP e JS passam |
| `windowCloseRequested` | não tratado | página que chama `window.close()` fica exibida |
| `isAuthUrl` (`ProviderModel`) | lista de hosts + heurística de caminho | **Inseguro**: `host.indexOf(entry) !== -1` aceita `accounts.google.com.evil.example` e a entrada `"clerk"` casa qualquer host que contenha "clerk" |
| UA | padrão do Qt (`… QtWebEngine/6.11.2 Chrome/140 …`); opção "Identificar como Chromium" desligada; `stripQtToken` disponível, sem uso | Medido em `docs/05`: Google aceita a identidade honesta e rejeita a disfarçada |
| Client Hints | padrão do Chromium (`Chromium`, `Not=A?Brand`) | idênticos a um Chromium |
| `javascriptCanOpenWindows` | true (config) | necessário para `window.open` |
| `allowWindowActivationFromJavaScript` | true | |

## Perfil e sessão

`WebEngineProfilePrototype { storageName: webEngineProfileName (default "chat-ai"); httpCacheType: DiskHttpCache;
persistentCookiesPolicy: ForcePersistentCookies; persistentPermissionsPolicy: StoreOnDisk; httpCacheMaximumSize }`,
instância obtida em `Component.onCompleted`. Cookies, localStorage, IndexedDB e permissões ficam em
`~/.local/share/plasmashell/QtWebEngine/<storageName>`, cache em `~/.cache/plasmashell/QtWebEngine/<storageName>`.
O perfil não é recriado ao trocar de provedor (só `httpUserAgent`/`downloadPath` mudam). A view é destruída no Close
(`Loader.active=false`) e recriada na próxima abertura com o mesmo `storageName` → sessão sobrevive.

## Lifecycle

`hidden` (popup colapsado ou painel de configurações) → `visible=false` → após 30 s, se `!busy` e
`recommendedState≠Active`, `Frozen`. `busy` inclui `loading`, áudio, `activeDownloadCount>0`, permissão pendente,
DevTools, limpeza de cache, tela cheia. Downloads não são congelados (Chromium os conduz no browser process; a view
pode até ser destruída sem afetar o download em curso? — **não**: `downloadCache` é da view; ver 03).

## Downloads hoje

- `onDownloadRequested` (perfil): sanitiza nome, define pasta, `addDownload`, conecta 4 sinais por item
  (`receivedBytes/totalBytes/state/isPausedChanged`) a uma closure, guarda `{download, updateConnection}` em `downloadCache`, `accept()`.
- `onDownloadFinished`: desconecta os sinais, apaga do cache, notificação KDE "Download finished".
- `downloadsModel` (`ListModel`): `downloadId, fileName, fullPath, progress, receivedBytes, totalBytes, isPdfExport, state, isPaused, error`.
- Derivados: `activeDownloadCount`, `activeDownloadProgress` (**média simples** das frações — enganosa com tamanhos diferentes).
- UI: `DownloadBar.qml` fixa no rodapé da WebView (nome, estado, barra, pausar/cancelar/abrir/remover); botão permanente
  "Downloads" na toolbar com badge; menu com abrir/escolher pasta e "limpar concluídos"; página Configurações › Downloads
  lista os itens quando o widget está aberto.
- Sem: "mostrar na pasta", estado "visto", velocidade/ETA, retry, ícone por tipo, throttling de UI (cada `receivedBytesChanged` faz `setProperty` ×6 e `downloadsRevision++`).

## Toolbar hoje

Ordem: Pin · Back · Forward · Reload/Stop · Home · Seletor · Buscar · **Olho (auto‑hide)** · **Downloads** · ⋮ · Fechar.
Overflow por largura move Olho/Downloads/Buscar/Home para o ⋮ (itens "de overflow" no `ChatAIMenu`). Auto‑hide da barra
usa `HoverHandler` + `menuOpen`.

## Componentes a alterar

`WebView.qml`, `ProviderModel.qml` (`isAuthUrl`), `Header.qml`, `ChatAIMenu.qml`, `DownloadBar.qml` (substituída),
`settings/DownloadsSettings.qml`, `main.qml` (flags de modal), novos `AuthPopup.qml`, `DownloadIndicator.qml`,
`DownloadPopup.qml`, `Downloads.js` (lógica pura testável), `tools/tests/`.

## Regressões possíveis

Popups que antes iam ao navegador externo passam a abrir no widget quando são janelas/diálogos (`window.open`) — links
`target=_blank` continuam externos; auto‑hide da barra com indicador de download; remoção da barra inferior (usuários
acostumados); notificações duplicadas; `busy` deve continuar impedindo Frozen durante download.

## Estratégia de testes

Unitários (qml6): progresso ponderado, regra de visibilidade do indicador, estados/visto, `isAuthUrl` com hosts
maliciosos. Reprodução instrumentada (host+path apenas) do clique "Continuar com o Google" em ChatGPT, Claude, Gemini,
Perplexity, Mistral para classificar popup × redirect. Mock OAuth local (popup → callback → `opener.postMessage` →
`window.close()`) para provar o mecanismo sem credenciais. Roteiro manual com credenciais do usuário (04).
