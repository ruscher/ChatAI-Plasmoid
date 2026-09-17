# 04 — Kebab menu (⋮) e configurações reorganizadas

Status: **planejado → implementado**.

## Menu

```
⋮
├── Abrir no navegador                 (internet-web-browser)
├── Copiar endereço                    (edit-copy)
├── Recarregar ignorando cache         (view-refresh)
├── ─────────────
├── Zoom  ▸  [ − ]  [ 100 % ]  [ + ]   (zoom-out / zoom-original / zoom-in) — item pai mostra o % atual
├── Tela cheia                         (view-fullscreen / view-restore)      F11
├── ─────────────
├── (overflow) Localizar na página     (edit-find)                           Ctrl+F
├── (overflow) Ocultar barra automaticamente  [checkable]
├── (overflow) Downloads ▸
├── ─────────────
├── Configurações do ChatAI ▸
│   ├── Geral · Sites · Permissões · Recursos da Web · Downloads · Cache e Dados · Aparência · Avançado
│   └── Abrir janela de configuração…  (diálogo padrão do Plasma)
├── Atalhos do teclado
├── Ferramentas do desenvolvedor       (apenas se habilitado em Avançado)
└── Sobre o ChatAI
```

Componente: `PlasmaComponents3.Menu` / `MenuItem` / `MenuSeparator` (nativos, cascata QQC2).
Itens "(overflow)" aparecem apenas quando o respectivo botão foi removido da barra (03).
Cada item tem ícone, texto, atalho quando existe e `enabled` correto (ex.: "Abrir no navegador"
desabilitado sem URL HTTP(S) carregada).

## Onde ficam as configurações — sem duplicar backend

O diálogo de configuração do Plasma não expõe API para abrir uma categoria específica
(`PlasmaQuick::ConfigView` só tem `configModel` e `appletGlobalShortcut`; o shell abre sempre a
primeira categoria). Solução nativa e leve:

- O **conteúdo** de cada página é um componente em `contents/ui/settings/*Settings.qml` que só depende de
  `plasmoid.configuration` (e opcionalmente de um objeto `runtime` = WebView, quando disponível).
- `contents/ui/Config*.qml` são wrappers finos `KCM.SimpleKCM { XSettings {} }` para o diálogo padrão.
- `SettingsPanel.qml` é um painel dentro do widget (substitui visualmente o WebView, que permanece vivo)
  com lista de categorias à esquerda e um `Loader` com o mesmo componente de conteúdo. O kebab abre a
  categoria pedida diretamente.

Resultado: um único backend (`plasmoid.configuration`), uma única implementação de UI por página,
dois hosts. O `Loader` do painel só carrega a página escolhida.

## Páginas

| Página | Conteúdo | Chaves |
| --- | --- | --- |
| Geral | Pré-carregar no início; Fixar (pin); Auto-hide da barra; Ocultar barra; Página inicial (provedor padrão); Links externos: abrir no navegador (sempre) | `loadOnStartup`, `pin`, `autoHideHeader`, `hideHeader`, `url` |
| Sites | Predefinidos (ícone, nome, switch, categoria, notas de login); Personalizados (nome + URL, editar/remover) | `show*`, `customSitesJson` |
| Permissões | Política global por tipo: Perguntar / Permitir / Bloquear (notificações, microfone, câmera, tela, localização, clipboard); Permissões salvas por site (lista com origem, tipo, estado; Resetar; Limpar todas) — requer o widget aberto | `*Policy` |
| Recursos da Web | Clipboard JS, colar via JS, abrir janelas, autoplay, navegação espacial, foco na navegação, esquemas desconhecidos — cada um com descrição da consequência | `javascriptCan*`, `playbackRequiresUserGesture`, `spatialNavigationEnabled`, `focusOnNavigationEnabled`, `allowUnknownUrlSchemes` |
| Downloads | Pasta (campo + seletor), abrir pasta, downloads em andamento (quando runtime), limpar concluídos | `downloadPath` |
| Cache e Dados | Caminhos; limite de cache (MB, 0 = automático); Limpar cache HTTP (progresso, `clearHttpCacheCompleted`); Limpar permissões por site; explicação cookies/sessões; Perfil do WebEngine (nome de armazenamento, restaurar padrão, abrir pasta, aviso de recriação) | `httpCacheMaximumSize`, `webEngineProfileName` |
| Aparência | Ícone (modos existentes), botões da barra, densidade não alterada (segue tema) | `iconMode`, `customIcon`, `hide*` |
| Avançado | User-Agent personalizado; congelar página oculta; descartar após N min; DevTools; diagnóstico | `customUserAgent`, `freezeWhenHidden`, `discardAfterMinutes`, `enableDevTools` |
| Sobre | Nome, versão (`plasmoid.metaData.version`), descrição, repositório, licença, autores, atalhos | — |

## Sites personalizados: formato

Novo formato: `customSitesJson` = JSON array `[{"name": "...", "url": "https://..."}]`.
Migração automática do formato `nome|url,nome|url` na primeira execução (`configVersion` 0 → 1); o
campo antigo é esvaziado após migração para evitar duas fontes. Nomes passam a aceitar `,` e `|`.
Leitura tolerante: JSON inválido → lista vazia + aviso no console (não derruba o widget).

## Riscos

- Painel interno dentro de popup: diálogos nativos (seletor de pasta) desativam a janela do popup →
  `main.qml` mantém `hideOnWindowDeactivate = false` enquanto `modalOpen` estiver true.
- Kirigami `FormLayout` em largura estreita: páginas usam `wrapMode` e `Layout.fillWidth`.

## Testes

Abrir cada categoria pelo kebab e pelo diálogo do Plasma; alterar um valor em um host e conferir o
outro; adicionar site personalizado com `,` no nome; migrar config antiga com `customSites`.
