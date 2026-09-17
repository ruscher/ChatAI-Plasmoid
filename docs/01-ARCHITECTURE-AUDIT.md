# 01 — Auditoria da arquitetura atual (1.0.0)

Status: **concluída** (base para as fases seguintes).

## Inventário

| Arquivo | Linhas | Responsabilidade atual | Observações |
| --- | --- | --- | --- |
| `metadata.json` | 25 | KPlugin | Versão 1.0.0, autores Denys/Bruno, Website já aponta para `ruscher/ChatAI-Plasmoid` |
| `contents/config/config.qml` | 24 | 2 categorias (General, Appearance) | General tem ~550 linhas de UI em uma só página |
| `contents/config/main.xml` | 237 | 77 entradas KConfig | 14 entradas sem uso; 1 usada incorretamente (`hidePrintButton`) |
| `contents/ui/main.qml` | 241 | PlasmoidItem, Loader do WebView, header auto-hide, tamanho | `Component.onCompleted` expande o popup no login quando `loadOnStartup` |
| `contents/ui/Header.qml` | 347 | Toolbar, ComboBox de URL, pin, downloads | 16 handlers `onShow*Changed` + Timer de 50 ms; `Binding` para `hideOnWindowDeactivate` |
| `contents/ui/WebView.qml` | 687 | Perfil, permissões, downloads, favicon, navegação, PDF | Bug em cancel/pause; favicon por varredura DOM; sem lifecycle |
| `contents/ui/ProviderModel.qml` | 99 | Catálogo de 15 provedores + custom sites | Já é a fonte única de dados, mas a UI ainda tem listas paralelas (`availableIcons`, handlers no Header) |
| `contents/ui/CompactRepresentation.qml` | 133 | Ícone do painel | Lista `availableIcons` duplicada; `webview` recebe `root.webviewRoot` (inexistente → sempre null) |
| `contents/ui/ConfigGeneral.qml` | 553 | Sites, permissões, web features, downloads, cache, perfil | Instancia `WebEngineProfilePrototype` só para exibir caminhos |
| `contents/ui/ConfigAppearance.qml` | 194 | Ícone e botões ocultos | Rótulo "Hide Auto-Hide button" grava `hidePrintButton` |
| `ContextMenu.qml`, `DownloadBar.qml`, `FindBar.qml`, `ErrorView.qml` | 84/144/125/67 | Componentes extraídos | OK; DownloadBar depende de `downloadCache[id]` com formato inconsistente |
| `contents/ui/assets/` | 508 KB | 49 SVGs | `lobechat.svg` 129 KB, `google.svg` 24 KB (metadados Inkscape); sem ícones para grok, meta, blackbox |
| `locale/` | 30 idiomas | `.pot` (82 msgids) + `.po` + `.json` (cache attranslate) | 114 strings `i18n()` no código → 32 sem template |
| `.github/workflows/` | 3 | validate, contribute-list, tradução legada (dormente) | validate roda `tools/validate.sh` |

## Mapa de estado e fluxo

- **Fonte da URL atual**: `plasmoid.configuration.url` (String). Home, seletor, favicon e UA derivam dela.
- **Provedores**: `ProviderModel.providers` = built-in + custom (`customSites` em `nome|url,nome|url`).
- **Habilitação**: uma chave Bool por provedor (`showChatGPT`, …). `Header` precisa de um handler por chave.
- **Perfil WebEngine**: `WebEngineProfilePrototype` + `instance()` em `Component.onCompleted`; `storageName` = `webEngineProfileName` sanitizado. Cache em disco, cookies `ForcePersistentCookies`, permissões `AskEveryTime`.
- **Permissões**: `onPermissionRequested` → switch por tipo → grant/deny global. Sem prompt, sem persistência, sem por-origem. `desktopMediaRequested` não tratado (compartilhamento de tela não seleciona fonte).
- **Downloads**: `ListModel` em `webview.downloads`; `downloadCache` guarda o item **duas vezes com formatos diferentes** (ver 02).
- **Favicon**: JS injetado a cada `LoadSucceeded` varre `meta[og:image]`, `link[rel*=icon]` e grava em `favIcon`/`lastFavIcon`.
- **Notificações**: `org.kde.notification` com `componentName: "chatai_plasmoid"` — nenhum `.notifyrc` instalado (`~/.local/share/knotifications6/` vazio); a UI pede ao usuário para criar o arquivo manualmente.
- **Pin**: `pin` (Bool) controla `hideOnWindowDeactivate` via `Binding` no Header; `keepOpen` (Bool) não é lido em lugar nenhum.
- **Timers**: `saveSizeTimer` 500 ms (tamanho), `hideTimer` 2 s (auto-hide), `modelUpdateTimer` 50 ms (debounce do combo), `hideStatusText` 750 ms.
- **Connections**: `plasmoid.configuration` (url, downloadPath) no WebView; 16 chaves no Header; `webProfile` (downloads/notificações); `root.expanded` no main.
- **Lazy loading**: `Loader { active: root.expanded || item !== null || loadOnStartup; asynchronous: true }`. Close → `active = false` destrói o WebEngineView.

## Configurações KConfig

| Estado | Chaves |
| --- | --- |
| Usadas corretamente | `url`, `iconMode`, `customIcon`, `favIcon`, `lastFavIcon`, `show*` (15), `hideHeader`, `hideKeepOpen`, `hideCloseButton`, `hideHomeButton`, `hideNavigationButtons`, `hideRefreshButton`, `hideDownloadButton`, `microphoneEnabled`, `webcamEnabled`, `screenShareEnabled`, `downloadPath`, `customSites`, `pin`, `loadOnStartup`, `spatialNavigationEnabled`, `javascriptCanPaste`, `javascriptCanOpenWindows`, `javascriptCanAccessClipboard`, `allowUnknownUrlSchemes`, `playbackRequiresUserGesture`, `focusOnNavigationEnabled`, `dialogWidth`, `dialogHeight`, `notificationsEnabled`, `geolocationEnabled`, `autoHideHeader`, `webEngineProfileName` |
| Usada incorretamente | `hidePrintButton` (controla o botão de auto-hide) |
| Sem uso | `icon`, `useFilledChatIcon`, `useOutlinedChatIcon`, `useColorfulChatIcon`, `useDefaultIcon`, `useDefaultLightIcon`, `useDefaultDarkIcon`, `useFavicon`, `keepOpen`, `hideGoToButton`, `hideCustomURL`, `notificationFlags`, `notificationUrgency`, `notificationTimeout`, `centerOnScreen`, `cachePath`, `clearCacheOnExit` |

## Problemas encontrados (resumo; detalhes e correções em 02)

| # | Severidade | Problema |
| --- | --- | --- |
| A1 | Alta | `cancelDownload/pauseDownload/resumeDownload` chamam `.cancel()` num objeto `{download, updateConnection}` → TypeError; pausar/cancelar downloads não funciona |
| A2 | Alta | Botão auto-hide visível por `hidePrintButton` |
| A3 | Alta | `keepOpen` e `pin` coexistem; `keepOpen` é órfão |
| A4 | Média | `MouseArea` com `Layout.fillWidth/fillHeight` **dentro do RowLayout** do Header ocupa uma célula do layout e disputa largura com o ComboBox |
| A5 | Média | `main.qml` chama `webviewRoot.goBack()` etc. sem verificar se o Loader tem item |
| A6 | Média | `loadOnStartup` expande o popup no login (`root.expanded = true`) |
| A7 | Média | `ConfigGeneral` cria `WebEngineProfilePrototype` (inicializa WebEngine) só para mostrar caminhos |
| A8 | Média | Favicon: varredura DOM a cada navegação; `og:image` tratado como ícone (imagens grandes) |
| A9 | Média | Reload padrão usa `reloadAndBypassCache()` |
| A10 | Média | Back/Forward sempre habilitados |
| A11 | Média | Notificações dependem de `.notifyrc` inexistente |
| A12 | Média | UA: Chrome 76 Android hardcoded para DuckDuckGo e Grok; Chromium 134 hardcoded para o resto |
| A13 | Baixa | 16 handlers manuais + timer 50 ms para atualizar o combo |
| A14 | Baixa | `Plasmoid.configuration` (maiúsculo) e `plasmoid.configuration` misturados |
| A15 | Baixa | `CompactRepresentation.webview` sempre null |
| A16 | Baixa | `javascriptCanPaste` (leitura de clipboard por JS) habilitado por padrão |
| A17 | Baixa | Sem tratamento de `desktopMediaRequested`; `screenCaptureEnabled` sem efeito prático |
| A18 | Baixa | Sem `lifecycleState`: WebView oculto continua 100% ativo |
| A19 | Baixa | 32 strings `i18n()` fora do `.pot` |

## Comparação Wayland × X11 no código atual

Não há chamadas a ferramentas X11 nem dependência de geometria de tela. Fullscreen é rejeitado
(`request.reject()`), o que é neutro entre os dois. Menus e diálogos são Qt/Plasma. A abertura de
pastas/URLs usa `Qt.openUrlExternally`. Nenhuma diferença de comportamento identificada; a
implementação de fullscreen (09) precisa usar `Window.visibility = FullScreen`, que funciona em ambos.
