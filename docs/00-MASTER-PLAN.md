# 00 — Plano mestre

## Objetivo

Modernizar o ChatAI-Plasmoid preservando o fluxo de widget Plasma, os provedores existentes e o formato de configuração compatível, com alvo primário Plasma 6.6.6 / KF 6.24 / Qt 6.10.2.

## Estado atual

O projeto é um pacote Plasma 6 pequeno, sem C++ ou sistema de build, com `contents/ui/main.qml` como orquestrador, `WebView.qml` como integração Qt WebEngine e duas páginas de configuração. As traduções compiladas ficam dentro de `contents/locale/`. A pasta `docs/` é exclusivamente de engenharia.

## Problemas encontrados

- Modelo de provedores duplicado e custom providers tratados como array em um ponto e string em outro (P1).
- Permissões WebEngine com concessão genérica e APIs de captura obsoletas (P1).
- Perfil e downloads com ciclo de vida frágil, índices instáveis e path traversal possível pelo nome sugerido (P1/P2).
- Reordenação de `children` de um `ColumnLayout`, timers de polling e animações longas (P2).
- Metadados incompletos, documentação mínima e ausência de validação automatizada (P2).

## Ordem de implementação

1. Inventário, baseline e auditoria.
2. Compatibilidade Plasma/KF/Qt e lint.
3. Modelo declarativo de provedores e correções de ciclo de vida.
4. Segurança, permissões, navegação e downloads.
5. Estados de erro e polimento visual/acessível.
6. Ferramentas de validação, empacotamento, CI e README.
7. Testes manuais Wayland/X11 e validação final sem marcar capacidades não testadas.

## Riscos e mitigação

O maior risco é o custo de Qt WebEngine no processo do plasmashell. O widget mantém o carregamento lazy existente e libera o `WebEngineView` ao fechar. O segundo risco é incompatibilidade de serviços externos; falhas são tratadas com retry e abertura no navegador, sem contornar bloqueios.

## Critério de pronto

JSON/XML válidos, `qmllint` sem erros do projeto, pacote `.plasmoid` reproduzível sem `docs/`, viewer sem warnings QML próprios em smoke test, permissões negadas por padrão quando sensíveis e matriz final distinguindo PASS de NÃO TESTADO.

## Arquivos afetados

Código em `contents/ui/`, esquema em `contents/config/main.xml`, metadata, README, ferramentas em `tools/`, CI em `.github/workflows/` e os documentos desta pasta.

## Alternativas consideradas

Uma reescrita em C++/QtQuick ou uma camada web externa foi descartada: aumentaria dependências e risco sem benefício proporcional para este plasmoid. A refatoração permanece declarativa e incremental.
