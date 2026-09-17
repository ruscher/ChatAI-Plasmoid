# 08 — Acessibilidade e internacionalização

## Objetivo

Manter o widget operável por teclado, legível em escalas e compatível com o fluxo de traduções existente.

## Estado atual / problemas

O projeto possui `.po`, `.json`, `.pot` e `.mo`, mas vários labels de provider são nomes literais e o header não expunha nomes acessíveis. O find bar possui Escape e Ctrl+F, mas a ordem de foco da configuração e leitores de tela ainda precisam de validação em sessão real.

## Implementação

`CompactRepresentation` agora fornece `Accessible.name` e tooltip contextual. `ErrorView` fornece nome acessível, labels e botões nomeados. Textos novos de estados usam `i18n()`. Imports de configuração foram modernizados sem remover arquivos de tradução.

## Solução / alternativas

Nomes próprios de serviços permanecem como strings estáveis para não alterar chaves de tradução existentes; mensagens e ações novas entram no catálogo de tradução. Não foi introduzido framework externo.

## Testes / pendências

`qmllint` passa e fontes existentes foram preservadas. Leitor de tela, navegação Tab/Shift+Tab, contraste Breeze light/dark, toque e escala fracionária não foram testados.

## Critério de aceite

Toda ação nova tem tooltip ou texto, foco visível no componente Plasma e nenhuma string de erro nova fica fora de `i18n()`.
