# 00 — Plano mestre: ChatAI 1.0.1

Status geral: **em implementação** (atualizado ao final em `14-FINAL-AUDIT.md`).

## Objetivo

Transformar o ChatAI-Plasmoid em uma experiência de primeira linha para acessar assistentes de IA
no KDE Plasma 6: rápido, leve, estável, seguro e visualmente nativo (Kirigami/Breeze). A versão
resultante é **1.0.1**.

## Ambiente de desenvolvimento e alvo

| Item | Valor observado |
| --- | --- |
| Plasma | 6.7.4 (plasmashell) |
| Qt / Qt WebEngine | 6.11.2 (Chromium 136) |
| Kirigami | 6.29.0 |
| Sessão | Wayland (`XDG_SESSION_TYPE=wayland`) |
| Ferramentas | `qmllint`, `qmlformat`, `kpackagetool6`, `plasmoidviewer`, `plasmawindowed`, `svgo` 4.1, gettext, PySide6 6.11.2 |
| Alvo mínimo declarado | Plasma 6.6 / KF 6.24 / Qt WebEngine 6.10 (metadata `X-Plasma-API-Minimum-Version: 6.0`) |

Todas as APIs Qt WebEngine usadas existem em `plugins.qmltypes` do módulo instalado e foram
conferidas na documentação oficial Qt 6 (`WebEngineView`, `WebEngineProfile`,
`WebEnginePermission`, `WebEngineProfilePrototype`).

## Princípios (ordem de prioridade)

1. Estabilidade  2. Correção  3. Performance  4. Baixo consumo  5. Segurança  6. UX
7. Acessibilidade  8. Design  9. Funcionalidades adicionais

Regras operacionais: analisar antes de alterar; corrigir erros encontrados antes da etapa que
depende deles; nenhum workaround frágil quando há API Qt/KDE; nenhuma dependência nova de runtime;
compatibilidade com configurações existentes via migração explícita.

## Fases

| # | Fase | Documento | Entregas |
| --- | --- | --- | --- |
| 0 | Auditoria | 01, 02 | Mapa da arquitetura, lista de bugs com causa raiz |
| 1 | Correções de base | 02 | Pin/keepOpen, botão auto-hide, downloads (pause/cancel), auto-hide MouseArea, guards de Loader |
| 2 | Registro de provedores | 06 | `ProviderModel.qml` como única fonte de verdade, metadados, reatividade sem handlers manuais |
| 3 | Header + kebab | 03, 04 | Nova ordem obrigatória, back/forward habilitados por estado, seletor com ícones, menu ⋮, overflow responsivo |
| 4 | Configurações | 04 | Páginas reorganizadas compartilhadas entre diálogo do Plasma e painel interno do widget |
| 5 | WebEngine | 07, 08, 09 | Permissões por origem (StoreOnDisk), UA centralizado, favicon nativo, lifecycle Frozen, zoom, fullscreen real, cache via API |
| 6 | Provedores | 05, 06 | Pesquisa 2026, matriz de testes, novos provedores selecionados, ícones otimizados |
| 7 | UX/UI/A11y/HiDPI | 10, 11 | Tooltips, `Accessible.name`, foco, Wayland/X11 |
| 8 | Release | 12, 13, 14 | Versão 1.0.1, metadata, README, i18n, testes, auditoria final |

## Arquitetura resultante (visão)

```
main.qml                 orquestração Plasma: expanded, pin, fullscreen, painel de configurações,
                         migração de configuração, lifecycle do WebView
├── CompactRepresentation.qml   ícone do painel (usa ProviderModel para ícone/nome)
├── Header.qml                  toolbar: 📌 ← → ↻ ⌂ [IA ▼] 🔍 👁 ⬇ ⋮ ✕
│   ├── AiSelector.qml          seletor de provedor (ícone + nome, teclado)
│   └── ChatAIMenu.qml          kebab (⋮)
├── WebView.qml                 WebEngineView + perfil, permissões, downloads, zoom, lifecycle
│   ├── PermissionBar.qml       prompt inline de permissão por origem
│   ├── FindBar.qml / DownloadBar.qml / ContextMenu.qml / ErrorView.qml
│   ├── FullScreenWindow.qml    janela de tela cheia real (Wayland/X11)
│   └── DevToolsWindow.qml      opcional, criado sob demanda
├── SettingsPanel.qml           painel de configurações dentro do widget (mesmo backend)
├── settings/*.qml              conteúdo das páginas (compartilhado com contents/config)
├── ProviderModel.qml           registro único de provedores
└── Migration.js / IconModes.js utilitários sem estado
```

## Critérios de pronto

A lista de aceite completa está em `13-RELEASE-1.0.1.md`; o resultado final, com evidência por item,
em `14-FINAL-AUDIT.md`. Nenhum item é marcado PASS sem teste real; itens não testados ficam como
`NÃO TESTADO` com o motivo.
