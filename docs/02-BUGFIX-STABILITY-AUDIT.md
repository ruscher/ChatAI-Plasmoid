# 02 — Correções e estabilidade

Status: **planejado → implementado nesta versão** (evidências em 14).

Cada item segue: problema → arquivos → comportamento atual → desejado → abordagem → alternativas →
riscos → impacto → testes → aceite.

## B1 — Pin / Keep Open (fonte única de verdade)

- **Arquivos**: `main.xml`, `Header.qml`, `main.qml`, `Migration.js`.
- **Atual**: `pin` controla o botão e `hideOnWindowDeactivate` (via `Binding` dentro do Header);
  `keepOpen` existe na configuração, não é lido, mas pode estar `true` em instalações antigas
  (versões anteriores usavam `keepOpen`). `hideKeepOpen` esconde o botão de pin.
- **Desejado**: `pin` é a única propriedade de estado. `hideOnWindowDeactivate` é definido no
  `PlasmoidItem` (main.qml) como `!pin && !modalOpen && !fullScreen`.
- **Abordagem**: migração de configuração (`configVersion` 0 → 1): `keepOpen && !pin` ⇒ `pin = true`;
  `keepOpen` deixa de ser lido. `hideKeepOpen` mantém o nome (compatibilidade) e o rótulo passa a
  "Ocultar botão Fixar".
- **Alternativas**: renomear `hideKeepOpen` → `hidePinButton` (rejeitado: quebra configurações sem ganho).
- **Riscos**: nenhum funcional; `keepOpen` fica como chave morta no rc do usuário.
- **Testes**: instalar sobre config com `keepOpen=true` → botão aparece fixado e o popup não fecha ao perder foco.

## B2 — Botão Auto-hide ("Eyes") ligado a `hidePrintButton`

- **Arquivos**: `Header.qml`, `ConfigAppearance.qml`/`settings/AppearanceSettings.qml`, `main.xml`.
- **Atual**: `visible: !plasmoid.configuration.hidePrintButton`; o checkbox "Hide Auto-Hide button" grava `hidePrintButton`.
- **Desejado**: chave `hideAutoHideButton` semanticamente correta.
- **Abordagem**: nova entrada Bool; migração copia `hidePrintButton` → `hideAutoHideButton`; `hidePrintButton` removido da UI.
- **Ícone**: `view-visible` quando a barra fica sempre visível (estado normal) e `view-hidden` quando o auto-hide está ativo; tooltip descreve a ação, não o estado.

## B3 — Pause/Cancel de download quebrados (TypeError)

- **Arquivo**: `WebView.qml`.
- **Atual**: `addDownload()` grava `downloadCache[id] = downloadItem`; em seguida `onDownloadRequested`
  sobrescreve com `{download, updateConnection}`; `cancelDownload()` executa `downloadCache[id].cancel()` → `cancel is not a function`.
- **Desejado**: um único formato `{download, updateConnection}` e funções que acessam `.download`.
- **Abordagem**: `addDownload` não grava mais no cache; as três funções usam `entry.download`. `DownloadBar` já verifica `downloadCache[model.downloadId]`.
- **Teste**: iniciar download grande, pausar, retomar, cancelar; verificar estados na barra.

## B4 — MouseArea dentro do RowLayout do Header

- **Arquivos**: `main.qml`.
- **Atual**: `Header { MouseArea { Layout.fillWidth; Layout.fillHeight } }` — o MouseArea é filho
  direto do `RowLayout`, portanto ocupa uma célula e disputa espaço com o ComboBox.
- **Desejado**: detectar hover/interação sem participar do layout.
- **Abordagem**: `HoverHandler` + `TapHandler` (`gesturePolicy: ReleaseWithinBounds`, `acceptedButtons: AllButtons`) diretamente no Header; a faixa de 2 px de detecção continua no `ColumnLayout`.
- **Risco**: nenhum; handlers não bloqueiam eventos.

## B5 — Chamadas ao WebView sem guard

- **Atual**: `onGoBackToHomePage: webviewRoot.goBackToHomePage()` etc. quebram com TypeError quando o Loader está inativo (após Close, com header visível por milissegundos).
- **Desejado**: todas as ações passam por uma função `withWebView(fn)` que ativa o Loader se necessário e ignora a ação enquanto o item não existe.

## B6 — `loadOnStartup` expande o popup no login

- **Atual**: `Component.onCompleted` faz `root.expanded = true`.
- **Desejado**: pré-carregar o WebEngine (já coberto pelo `active` do Loader) sem abrir o popup. O rótulo passa a "Pré-carregar o site ao iniciar o Plasma (usa memória desde o login)".

## B7 — WebEngine instanciado na tela de configurações

- **Atual**: `ConfigGeneral.qml` cria `WebEngineProfilePrototype` para ler `cachePath`/`persistentStoragePath`.
- **Desejado**: caminhos calculados sem WebEngine: `StandardPaths.CacheLocation + "/QtWebEngine/" + storageName` e
  `StandardPaths.AppLocalDataLocation + "/QtWebEngine/" + storageName` (mesma regra da documentação do
  `WebEngineProfile`; confirmado em disco: `~/.cache/plasmashell/QtWebEngine/chat-ai` e
  `~/.local/share/plasmashell/QtWebEngine/chat-ai`).
- **Impacto**: abrir a configuração deixa de carregar o Chromium.

## B8 — Favicon por varredura DOM

- **Desejado**: usar `WebEngineView.icon` (Chromium escolhe o melhor ícone declarado pela página) via
  `onIconChanged`, removendo o prefixo `image://favicon/`. Sem `og:image`. Sem JS injetado.
- **Cache**: `lastFavIcon` já persiste o último ícone válido; atualiza apenas quando o valor muda.

## B9 — Reload

- Botão ↻ → `reload()`. `reloadAndBypassCache()` fica no kebab e no menu de contexto.

## B10 — Back/Forward habilitados por estado

- `enabled: webview.canGoBack` / `canGoForward`; ao não haver WebView, ambos desabilitados.

## B11 — Notificações sem `.notifyrc`

- **Atual**: `componentName: "chatai_plasmoid"` exige arquivo que o pacote não pode instalar (KPackage de applet não instala `knotifications6/`).
- **Desejado**: `componentName: "plasma_workspace"`, `eventId: "notification"` — evento padrão presente em
  `/usr/share/knotifications6/plasma_workspace.notifyrc`, usado por outros plasmoids. A mensagem sobre criar o arquivo manualmente é removida.

## B12 — Downloads: PDF via `addDownload(null, …)`

- Mantido; agora sem escrita no `downloadCache`, ver B3.

## B13 — `Plasmoid` vs `plasmoid`

- Padronizado em `plasmoid` (funciona no applet e no diálogo de configuração).

## B14 — Timer de 50 ms e 16 handlers no Header

- Substituídos por `ProviderModel.enabledProviders`, binding reativo que lê as chaves `show*` dinamicamente (o motor QML captura as dependências mesmo com acesso por colchetes). Ver 06.

## B15 — `desktopMediaRequested` sem handler

- Handler seleciona a primeira tela (`request.selectScreen(request.screensModel.index(0, 0))`) apenas quando a política de compartilhamento de tela permite; caso contrário `request.cancel()`.

## Critérios de aceite da fase

- `qmllint` sem novos avisos; nenhum TypeError no `journalctl --user` ao usar downloads, Close e navegação.
- Todos os itens acima com teste manual registrado em 12/14.
