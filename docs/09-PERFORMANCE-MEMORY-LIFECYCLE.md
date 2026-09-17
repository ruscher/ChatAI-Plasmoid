# 09 — Performance, memória e lifecycle

Status: **implementado; medições em 14**.

## Baseline medido (antes) — 2026‑09‑17, Plasma 6.7.4, Qt 6.11.2, Wayland

| Cenário | Medição |
| --- | --- |
| plasmashell idle, 3 instâncias do ChatAI, WebView fechado | RSS 689 848 kB, 109 threads, 0 processos `QtWebEngineProcess` |
| Processos WebEngine de uma WebEngineView (harness PySide6, perfil off-the-record) | zygote ×3 (61 MB, 61 MB, 17 MB) + renderer 87 MB no carregamento inicial |

## Medição depois (mesmo método, `plasmoidviewer`, Duck.ai, `tools`/`measure2.sh` por árvore de processos)

| Cenário | 1.0.0 | 1.0.1 |
| --- | --- | --- |
| Renderer RSS aos 25 s | 222 452 kB | 216 676 kB |
| Viewer RSS aos 25 s (inclui browser process in‑process) | 434 668 kB | 445 104 kB |
| Renderer CPU ticks 25→45 s (visível, ociosa) | 80→84 | 95→96 |
| Oculta 30 s | Active | **Frozen** (`recommendedState` = Discarded) |
| Após Close | — | renderer encerrado (0 processos, −216 MB); zygotes permanecem |

Interpretação: memória do renderer equivalente; o processo hospedeiro cresce ~10 MB pelo QML adicional
(menu, seletor com delegates, registro); Frozen confirmado; Close libera o renderer. Em página ociosa o
congelamento não altera CPU mensurável — o benefício aparece com timers/streams ativos na página.

## Estratégia de lifecycle

Referência: `WebEngineView.lifecycleState` / `recommendedState` (Qt 6). Restrições da documentação:
uma página **visível** deve permanecer `Active`; páginas inspecionadas por DevTools permanecem `Active`;
`Discarded` só transita para `Active` (recarrega); ir para um estado de menor consumo que o
`recommendedState` pode causar efeitos colaterais (perda de áudio/formulário).

```
popup expandido        → visible = true; lifecycleState = Active (antes de tornar visível)
popup colapsado        → webview.visible = false; após 30 s, se recommendedState !== Active
                          e não houver atividade (loading, download, áudio, prompt de permissão,
                          DevTools) → lifecycleState = Frozen
oculto por muito tempo → se `discardAfterMinutes` > 0 e recommendedState === Discarded
                          → Discarded (opcional, desligado por padrão: perde texto não enviado)
Close explícito        → Loader.active = false (destrói view e renderer)
```

`freezeWhenHidden` (padrão true) permite desligar em Avançado. Nunca congelamos quando
`recommendedState === Active` — é o WebEngine quem sabe se há áudio, upload ou trabalho em andamento.

## Lazy loading

Mantido: `Loader { asynchronous: true; active: expanded || item !== null || loadOnStartup }`.
Correções: a configuração não instancia WebEngine (B7); o painel de configurações interno não cria views.

## QML

- Removidos: `Connections` com 16 handlers, Timer 50 ms, JS de favicon a cada load, lista `availableIcons` duplicada.
- Bindings pesadas: `enabledProviders` é recalculada apenas quando uma chave `show*`/`customSitesJson` muda.
- Ícones do seletor: `Kirigami.Icon` com SVGs otimizados (svgo): `lobechat.svg` 129 KB → ver 14; `google.svg` 24 KB → ver 14.
- Animações: 150 ms no header (existente), badge de download sem animação contínua.

## Zoom

`zoomFactor` persistido globalmente (`zoomFactor`, Double, 1.0). Passos: 50, 67, 75, 80, 90, 100, 110, 125,
150, 175, 200 % (limites da API 0.25–5.0 respeitados). Atalhos Ctrl++ / Ctrl+- / Ctrl+0.

## DevTools

Janela separada criada sob demanda (`DevToolsWindow.qml`), `devToolsView` desfeito e janela destruída ao fechar.
Padrão desligado; o item do menu só aparece com `enableDevTools`.

## Método de medição (reproduzível)

```
pgrep -x plasmashell | xargs -I{} grep -E 'VmRSS|Threads' /proc/{}/status
ps -o pid,rss,args -C QtWebEngineProcess | cut -c1-100
```
Cenários: fechado; aberto com ChatGPT; troca para Claude; colapsado 60 s (Frozen); Close.
