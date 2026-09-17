# 12 — Plano de testes

Status: **em execução; resultados em 14**.

## Estáticos
`./tools/validate.sh` (JSON, XML, `qmllint`, pacote sem `docs/`), `qmlformat --check` apenas nos arquivos novos
(não reformatar o projeto inteiro), `msgfmt --check` em cada `.po`.

## Harness automatizado de carregamento (PySide6 + QtWebEngine 6.11, perfil off-the-record)
Script `tools/provider-probe/` (copiado do scratchpad): carrega cada URL, registra
`LoadSucceeded/Failed`, URL final, título, presença de campo de entrada (`textarea`/`contenteditable`) e
pistas de bloqueio ("unsupported browser", "verify you are human", "disallowed_useragent", …), com UA
padrão do Qt e com UA sem o token `QtWebEngine`.

## Matriz de compatibilidade (preenchida em 14)

Legenda: PASS / FAIL / PARTIAL / N/A / NÃO TESTADO.

| Provider | Load | Login | Chat | Upload | Mic | Download | OAuth | Wayland | X11 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| (uma linha por provedor) | | | | | | | | | |

Login/Chat/Upload/Mic/OAuth exigem credenciais reais: sem credenciais nesta sessão, ficam NÃO TESTADO,
exceto onde a página anônima já permite conversar (Duck.ai).

## Funcional (manual, `plasmoidviewer -a .` e sessão real)
Pin; Back/Forward habilitados por histórico; Reload/Stop; Home; seletor (mouse e teclado); Ctrl+F; Eyes;
Downloads (pausar/retomar/cancelar/abrir); kebab (todos os itens); zoom (menu e atalhos, persistência);
fullscreen (menu, F11, pedido da página, Esc); painel interno de configurações (todas as categorias);
diálogo do Plasma (todas as categorias); permissões (prompt, lembrar, resetar); cache (limpar, progresso);
perfil (renomear com confirmação); Close libera processos; overflow do header em largura mínima.

## Migração
Arquivo rc com `keepOpen=true`, `hidePrintButton=true`, `customSites=A|https://a.example,B|https://b.example`,
`microphoneEnabled=true`, `url=https://x.com/i/grok` → após abrir: `pin=true`, `hideAutoHideButton=true`,
`customSitesJson` com 2 itens, `microphonePolicy=1`, `url=https://grok.com`, `configVersion=1`.

## Instalação
`kpackagetool6 --type Plasma/Applet --upgrade build/ChatAI-Plasmoid.plasmoid` sobre a 1.0.0 instalada;
`--remove` e `--install` limpo; verificar `journalctl --user` sem erros QML do ChatAI.

## Performance
Método de 09, cenários: fechado / aberto ChatGPT / troca Claude / colapsado 60 s / Close.
