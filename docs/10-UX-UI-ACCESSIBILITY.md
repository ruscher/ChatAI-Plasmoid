# 10 — UX/UI e acessibilidade

Status: **implementado** (evidências em 12 e 14).

## Princípios
Kirigami/Breeze/Plasma Components; `Kirigami.Units` para todas as medidas; `Kirigami.Theme` para cores;
microinterações apenas onde ajudam (hover/pressed nativos, progresso de carregamento, badge de download,
transição de 150 ms da barra). Sem blur, sombras grandes ou animações contínuas.

## Elementos

| Elemento | Decisão |
| --- | --- |
| Barra | ordem obrigatória (03), `PlasmaComponents3.Button` IconOnly com `text` (tooltip + a11y) |
| Seletor | ícone do provedor (mesma família de assets do painel) + nome; item atual destacado pelo ComboBox |
| Progresso | `ProgressBar` de 3 px no topo do WebView (existente) |
| Erro | `ErrorView` (existente) |
| Permissão | `PermissionBar` inline, cores de `Kirigami.Theme` (View), botões Permitir/Bloquear, ícone do tipo |
| Configurações internas | `SettingsPanel` com `Kirigami.FormLayout`; lista de categorias com ícones Breeze |
| Sobre | logo do projeto, nome, versão, links (`Kirigami.UrlButton`), autores |

## Acessibilidade

- Todo controle: `text`/`Accessible.name`; checkables expõem `checked`; `enabled` real (sem botões inertes).
- Teclado: Tab/Shift+Tab pela barra, Enter ativa, Esc fecha FindBar/painel/fullscreen; Ctrl+F, Ctrl+±/0, F11.
- Foco visível: fornecido por Plasma Components.
- Não depender apenas de cor: ícones de estado diferentes para Pin/Eyes; textos de estado nos downloads.
- Áreas clicáveis ≥ `Kirigami.Units.iconSizes.medium` por botão.

## HiDPI
Apenas SVG e ícones de tema; tamanhos via `Units`. Testes conceituais 100–200 % (11).

## Textos
Toda string de UI usa `i18n()`; nomes próprios de provedores não são traduzidos.
