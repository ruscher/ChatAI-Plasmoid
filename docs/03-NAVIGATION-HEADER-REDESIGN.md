# 03 — Redesenho da barra de navegação

Status: **planejado → implementado**.

## Ordem obrigatória

```
📌  ←  →  ↻  ⌂  [ IA ▼ ]  🔍  👁  ⬇  ⋮  ✕
```

| Controle | Ícone Breeze | Ação | Habilitado quando | Ocultável por |
| --- | --- | --- | --- | --- |
| Pin | `window-pin` | `pin = !pin` | sempre | `hideKeepOpen` |
| Back | `go-previous` | `goBack()` | `canGoBack` | `hideNavigationButtons` |
| Forward | `go-next` | `goForward()` | `canGoForward` | `hideNavigationButtons` |
| Reload | `view-refresh` (`process-stop` enquanto carrega) | `reload()` / `stop()` | WebView existe | `hideRefreshButton` |
| Home | `go-home` | `url = provider.url` | WebView existe | `hideHomeButton` |
| Select AI | `AiSelector` | troca `plasmoid.configuration.url` | sempre | — |
| Search | `edit-find` | alterna FindBar (Ctrl+F) | WebView existe | overflow |
| Eyes | `view-visible`/`view-hidden` | `autoHideHeader = !autoHideHeader` | sempre | `hideAutoHideButton` / overflow |
| Download | `folder-download` (+ badge de progresso) | menu de downloads | sempre | `hideDownloadButton` / overflow |
| Kebab | `overflow-menu` | `ChatAIMenu` | sempre | — |
| Close | `window-close` | destrói WebView e colapsa | sempre | `hideCloseButton` |

## Arquivos

`Header.qml` (reescrito), `AiSelector.qml` (novo), `ChatAIMenu.qml` (novo), `main.qml` (sinais).

## Comportamento

- **Pin**: `checked` reflete `pin`; tooltip "Manter aberto ao clicar fora" / "Fechar ao clicar fora". `hideOnWindowDeactivate` decidido em `main.qml`.
- **Back/Forward**: desabilitados sem histórico. `Accessible.name` = texto.
- **Reload**: enquanto `loading`, o botão vira **Parar**. Reload ignorando cache fica no kebab.
- **Home**: usa a URL do provedor atual (não a URL da página atual).
- **Select AI**: `PlasmaComponents3.ComboBox` com delegate `ícone + nome`, `Layout.fillWidth`,
  `Layout.minimumWidth: gridUnit * 6`. Entrada final "Endereço personalizado…" (removível via
  `hideCustomURL`, chave que existia sem uso). Teclado: setas, Enter, Esc. Filtro por digitação:
  `ComboBox` já suporta busca incremental por tecla (`QQC2` key search) — suficiente para ≤ 25 itens;
  não foi adicionado campo de busca para não aumentar código/consumo.
- **Search**: mantém `StandardKey.Find`.
- **Eyes**: mostra estado com ícone e tooltip: "Ocultar barra automaticamente" (ativa) / "Manter barra sempre visível".
- **Download**: menu com "Abrir pasta", "Escolher pasta…", lista de downloads ativos (nome + %) e "Limpar concluídos". Badge circular discreto (progresso médio) sobreposto ao ícone quando há downloads em andamento.
- **Close**: `webviewLoader.active = false; expanded = false` — libera o processo renderer.

## Responsividade (overflow progressivo)

Largura disponível do Header (`width`) decide o nível:

| Nível | Condição | Ocultos na barra (passam para o kebab) |
| --- | --- | --- |
| 0 | ≥ 34 gridUnit | nenhum |
| 1 | < 34 gridUnit | Eyes |
| 2 | < 30 gridUnit | Eyes, Download |
| 3 | < 26 gridUnit | Eyes, Download, Search, Home |

Os controles obrigatórios que permanecem sempre visíveis: Pin, Back, Forward, Reload, Select AI, Kebab, Close.
O seletor tem `Layout.minimumWidth` para não colapsar em texto ilegível.

## Acessibilidade

Cada botão define `text` (usado como `Accessible.name` e tooltip) e `display: IconOnly`.
Botões checkable expõem `checked`. Foco visível por `PlasmaComponents3.Button`.

## Alternativas consideradas

- Popup customizado com campo de busca para o seletor: rejeitado por ora (código extra, foco em popup dentro de popup no Wayland; ComboBox já resolve com ≤ 25 provedores).
- Emojis: rejeitados; apenas ícones Breeze.

## Riscos

- `ComboBox` com delegate customizado dentro de `PlasmaComponents3`: testado no viewer.
- Overflow: transições ocultam itens; sem animação para evitar "dança" de layout.

## Testes

Reduzir a largura do popup até o mínimo (20 gridUnit) e verificar os níveis; teclado Tab/Shift+Tab pela barra; leitor de tela (Orca) lê os nomes; HiDPI 125/150/200 % ícones nítidos (SVG).
