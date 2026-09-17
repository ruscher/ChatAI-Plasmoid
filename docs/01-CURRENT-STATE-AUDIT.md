# 01 — Auditoria do estado atual

## Objetivo

Registrar o comportamento e os riscos antes da modernização.

## Estado atual

`main.qml` definia quinze provedores e também tentava anexar custom sites. `Header.qml` recriava parte da lista. `WebView.qml` concentrava perfil, permissões, favicon, navegação, downloads, impressão e status. A configuração tinha 611 linhas e muitos flags de visibilidade.

## Problemas encontrados / causa / impacto

| Prioridade | Problema | Causa e impacto |
| --- | --- | --- |
| P1 | Custom providers não chegavam ao modelo principal | `main.qml` só aceitava `customSites` se fosse array, embora `main.xml` declare `String`; o ícone e a seleção podiam divergir. |
| P1 | Captura podia ser concedida indevidamente | Após um ramo que apenas retornava, havia `request.grant()` genérico. |
| P1 | Perfil e downloads | `WebEngineProfile` era filho do view e closures guardavam índices; remover uma linha podia atualizar outra. |
| P2 | Layout | `main.qml` removia e reanexava manualmente `children` de um `ColumnLayout`, combinando ordem dinâmica com Layout attached properties. |
| P2 | JavaScript repetitivo | Cada carregamento adicionava listener `keydown` e intervalos sem limite efetivo, podendo duplicar handlers. |
| P2 | Segurança de URL | Esquemas desconhecidos eram permitidos por padrão e nomes de download não eram sanitizados. |
| P2 | Lint | Optional chaining em dois pontos fazia o `qmllint` instalado terminar com código 255 sem diagnóstico útil. |
| P3 | UX | Header tinha muitos controles sem estado de erro útil; a seleção não era centralizada nem tinha fallback visual para custom provider. |

## Implementação

Foi criado `ProviderModel.qml`; `main.qml`, `Header.qml`, `CompactRepresentation.qml` e `ConfigGeneral.qml` agora usam a mesma definição. Foi criado `ErrorView.qml`. O layout deixou de manipular `children`, e o WebEngine passou a ter perfil prototype, download model estável e permissões explícitas.

## Testes e resultados

Baseline: JSON e XML válidos; o `qmllint` agregado terminava com 255 e o arquivo de Header reproduzia o problema sem saída. Após remover optional chaining, `qmllint` individual e agregado terminam com 0. `git diff --check` termina com 0.

## Pendências

Busca, favoritos e recentes ainda não foram adicionados; não há teste automatizado de UI ou medição de memória em ambiente alvo exato.

## Critério de aceite

Nenhuma decisão de runtime depende de `docs/`; os riscos P1 acima têm correção implementada e o que não foi validado permanece explícito na validação final.
