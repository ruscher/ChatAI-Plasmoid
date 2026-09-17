# 06 — Desempenho e memória

## Objetivo

Controlar o custo do Qt WebEngine sem prometer números não medidos.

## Estado atual

O WebEngine é carregado por `Loader` assíncrono quando o widget expande ou `loadOnStartup` está ativo. Fechar pelo botão desativa o Loader e libera o view. O cache persistente evita recarregar tudo, mas o processo Chromium é o maior consumidor esperado.

## Problemas e solução

- Removida a criação dinâmica repetida de `ListModel`.
- Removido polling de interação do header; resta apenas timer one-shot de debounce/hide.
- Removido JavaScript repetido de Enter, incluindo intervalos sem limite.
- Atualização de downloads por ID evita trabalho e erros de índice após remoção.
- O perfil é nomeado e criado uma vez por WebView, e não recriado ao trocar URL.

## Baseline e resultado

Não há medição confiável de RAM/processos antes e depois disponível no ambiente. Foi observado qualitativamente que a primeira tentativa de profile prototype durante construção causou SIGSEGV; após criação lazy com fallback, o viewer ficou vivo por 15 segundos até `timeout` (código 124), sem warning QML do projeto. Isso é estabilidade de smoke test, não benchmark.

## Procedimento reproduzível futuro

Executar viewer em sessão dedicada, registrar tempo até janela, `ps --forest` dos filhos, RSS do processo e logs; repetir abertura, troca por 10 providers, fechamento e reabertura. Comparar o mesmo Qt/Plasma, escala e tema. Não usar esses números até guardar comando, ambiente e amostra.

## Critério de aceite

Nenhum Timer periódico sem necessidade, nenhum processo WebEngine órfão observado no cenário de estresse e memória documentada apenas com medição real.
