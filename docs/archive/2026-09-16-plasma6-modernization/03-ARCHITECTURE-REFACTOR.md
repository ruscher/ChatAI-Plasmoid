# 03 — Refatoração de arquitetura

## Objetivo

Reduzir responsabilidades cruzadas mantendo o projeto pequeno e fácil de empacotar.

## Estado atual e problemas

O modelo de providers estava em `main.qml`, a seleção era reconstruída em `Header.qml` e a configuração tinha uma terceira lista. Isso permitia nomes e URLs inconsistentes. `WebView.qml` continua sendo o coordenador de WebEngine, mas suas funções de perfil/download/segurança agora têm fronteiras claras e não criam QML dinamicamente.

## Solução escolhida

- `ProviderModel.qml`: catálogo built-in, parsing compatível de custom sites, validação HTTP(S), enabled state, lookup por URL e metadados de ícone/user-agent.
- `ErrorView.qml`: estado de falha reutilizável com retry e navegador externo.
- `main.qml`: composição Plasma, lazy Loader e persistência de tamanho.
- `Header.qml`: ações e seleção, sem duplicar o catálogo.
- `WebView.qml`: profile instance, navegação segura, permissões e download lifecycle.

`docs/` não é importado por nenhum QML e não entra no pacote.

## Alternativas consideradas

Um singleton QML global reduziria instanciações, mas adicionaria registro de módulo e complexidade de empacotamento. Instâncias locais de `ProviderModel` em runtime e configuração são suficientes e não duplicam a definição.

## Implementação

Custom sites continuam serializados como `name|url,name|url`, e arrays são aceitos para tolerar builds de desenvolvimento antigos. Nomes e URLs inválidos são ignorados na leitura e rejeitados na configuração.

## Testes / resultado

Lint completo passa; seleção built-in e custom é coberta por inspeção de bindings e smoke viewer. Uma UI de busca/favoritos/recentes ainda é uma melhoria futura, não uma funcionalidade alegada como pronta.

## Critério de aceite

Adicionar provider não requer editar múltiplos QMLs; custom provider mantém seleção, navegação e fallback de ícone.
