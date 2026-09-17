# 03 — Arquitetura da nova UX de downloads e da toolbar

Status: **implementado** (validação em 05 e 07).

## Princípio: uma única fonte de verdade

```
Qt WebEngine (WebEngineProfile.downloadRequested)
        │
        ▼
WebView.qml ── downloadsModel (ListModel)  ←── única lista
   │   ├─ roles: downloadId, fileName, fullPath, sourceUrl, mimeType, progress,
   │   │         receivedBytes, totalBytes (0 = desconhecido), isPdfExport, state,
   │   │         isPaused, error, seen, speed (B/s | -1), eta (s | -1)
   │   ├─ downloadCache[id] = { download, throttled, immediate, samples, lastUpdate, pending }
   │   ├─ downloadSummary = Downloads.summarize(itens)  ← derivado, reativo (downloadsRevision)
   │   └─ ações: pause/resume/cancel/open/showInFolder/retry/remove/clearFinished/markSeen
   │
   ├── Downloads.js  (lógica pura, testada em tools/tests/downloads_test.qml)
   │      summarize · speedFromSamples · etaSeconds · pushSample · scaleBytes · iconForFileName
   │
   ├── DownloadIndicator.qml  (toolbar; consome downloadSummary; sem estado próprio)
   ├── DownloadPopup.qml      (lista + ações; consome downloadsModel; chama as ações do WebView)
   ├── ChatAIMenu.qml         ("Downloads" permanente → abre o popup; "Ocultar barra automaticamente" ✓)
   └── settings/DownloadsSettings.qml (pasta; lista do mesmo modelo quando o widget está aberto)
```

`DownloadBar.qml` (barra fixa no rodapé) foi removida: o par indicador temporário + popup cobre todas as suas funções
(nome, estado, progresso, pausar/retomar/cancelar, abrir, remover) e acrescenta mostrar na pasta, tentar de novo,
velocidade/ETA, ícone por tipo e o estado "visto".

## Toolbar

```
antes:  📌 ← → ↻ ⌂ [IA ▼] 🔍 👁 ⬇ ⋮ ✕      (👁 e ⬇ permanentes; overflow movia 4 botões)
depois: 📌 ← → ↻ ⌂ [IA ▼] 🔍 (↓)  ⋮ ✕     (↓ só enquanto há atividade/pendência; overflow só de ⌂ e 🔍)
⋮ ─ … ─ Ocultar barra automaticamente ✓ ─ Downloads (n) ─ …
```

As chaves `hideAutoHideButton`/`hideDownloadButton` ficam no schema por compatibilidade, sem efeito; a página
Aparência não as exibe mais.

## Indicador temporário

- Visível quando `summary.showIndicator` = `active > 0 || completedUnseen > 0 || failedUnseen > 0`.
- Anel de progresso (QtQuick.Shapes `PathAngleArc`): determinado = `sum(receivedBytes)/sum(totalBytes)` dos downloads
  com tamanho conhecido; indeterminado (só tamanhos desconhecidos) = arco curto girando (animação só enquanto ativo).
  Cor neutra quando todos estão pausados.
- Sem atividade: badge ✓ (positivo) ou ! (negativo) com contagem quando > 1; ícone `download-later`/`data-warning`.
- Entrada/saída com `opacity`/`scale` em `Kirigami.Units.shortDuration`; anel com `longDuration`.
- Acessível: `text` descreve estado e porcentagem (`i18np`), `Accessible.description` explica o clique.

## Estado "visto" (`seen`)

`seen` = `true` quando o usuário Abre, Mostra na pasta, Remove, Tenta de novo ou Limpa concluídos. Downloads
concluídos/falhos não vistos mantêm o indicador; o histórico continua no popup pelo ⋮ mesmo com o indicador oculto.

## Desempenho

`receivedBytesChanged`/`totalBytesChanged` passam por `scheduleDownloadUpdate` (≤ 1 atualização a cada 250 ms por
download, com flush único); `stateChanged`/`isPausedChanged` aplicam imediatamente. `setDownloadProperty` só escreve
quando o valor muda. Amostras (janela de 10 s) alimentam velocidade e ETA; ETA só aparece com total conhecido, ≥ 2 s
de janela e progresso positivo. Nada é gravado em disco por byte recebido.

## Limpeza de sinais

Ao `downloadFinished`: desconecta as 4 conexões, remove `downloadCache[id]`; `removeAt` também apaga a entrada.
Os itens finalizados permanecem apenas no `ListModel` (dados planos), sem referência ao `WebEngineDownloadRequest`.

## "Mostrar na pasta"

`org.freedesktop.FileManager1.ShowItems` via `dbus-send` no engine `executable` do `Plasma5Support.DataSource`
(Dolphin, Nautilus, etc. selecionam o arquivo); se o comando falhar, abre a pasta com `Qt.openUrlExternally`.

## Tentar de novo

`WebEngineDownloadRequest` finalizado é liberado pelo Qt (`downloadFinished`), então `resume()` não está disponível;
o retry remove o item e re‑solicita `sourceUrl` via `<a download>` na página, o que gera um novo `downloadRequested`.

## Notificações

Uma `Notification` (`plasma_workspace/notification`) por download concluído ou falho, com ações **Abrir** e
**Mostrar na pasta** (`NotificationAction`), destruída ao fechar. Sem toast/barra duplicados; o indicador é a única UI in‑widget.

## Auto‑hide da barra

`downloadAttention()` (conclusão/falha/PDF) revela a barra por 3 s (`headerVisible` + `hideTimer`), sem popup. Histórico
antigo não mantém a barra aberta.

## Lifecycle

`busy` inclui `activeDownloadCount > 0` e `authPopupOpen`; a página não é congelada nem descartada durante downloads
ou login.
