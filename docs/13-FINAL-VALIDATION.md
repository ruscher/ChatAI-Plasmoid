# 13 — Validação final

## Objetivo

Consolidar evidências reais e separar compatibilidade demonstrada de itens pendentes.

## Ambiente

Target obrigatório: Plasma 6.6.6 / KF 6.24.0 / Qt 6.10.2 / WebEngine 6.10, Wayland e X11.

Ambiente observado: Plasma 6.7.4, Qt 6.11.2, sessão Wayland. O alvo exato e X11 não estão disponíveis nesta execução.

## Matriz

| Item | Wayland | X11 | Resultado |
| --- | --- | --- | --- |
| JSON/XML/metadata | PASS | PASS* | Validação independente de sessão |
| QML lint | PASS | PASS* | `qmllint` local |
| Abrir widget | PASS | ⚠️ NÃO TESTADO | `plasmoidviewer` planar, topedge e leftedge; escala 1,25× em dois smoke tests |
| Configuração | ⚠️ NÃO TESTADO | ⚠️ NÃO TESTADO | Sem sessão de configuração dedicada |
| ChatGPT | ⚠️ NÃO TESTADO | ⚠️ NÃO TESTADO | Não foi feito login/teste de serviço |
| Claude | ⚠️ NÃO TESTADO | ⚠️ NÃO TESTADO | Serviço pode limitar embedded browser |
| Gemini | ⚠️ NÃO TESTADO | ⚠️ NÃO TESTADO | Não foi feito teste de rede |
| Custom provider | ⚠️ NÃO TESTADO | ⚠️ NÃO TESTADO | Parser validado por código, não UI |
| Downloads | ⚠️ NÃO TESTADO | ⚠️ NÃO TESTADO | Sem download real |
| PDF/MHTML | ⚠️ NÃO TESTADO | ⚠️ NÃO TESTADO | Sem página carregada manualmente |
| Notificações/permissões | ⚠️ NÃO TESTADO | ⚠️ NÃO TESTADO | Política auditada, request não simulado |
| Packaging | PASS | PASS* | `validate.sh`, zip e `kpackagetool6 --appstream-metainfo` |

`PASS*` indica que o item não depende de compositor, não que X11 foi executado.

## Testes executados

`python3 -m json.tool metadata.json`, `xmllint --noout contents/config/main.xml`, `qmllint` em todos os QMLs, `git diff --check`, `./tools/build-package.sh`, `./tools/validate.sh`, `kpackagetool6 --appstream-metainfo` e smoke `plasmoidviewer` planar/topedge/leftedge.

## Problemas conhecidos

Não há medição quantitativa antes/depois de RAM/processos; busca/favoritos/recentes não existem; private profile e prompt por site não foram adicionados; X11 e target exato aguardam ambiente correspondente. O journal registrou warnings externos de `org.kde.desktopcontainment`, mas nenhum warning próprio do ChatAI após a correção. Nenhum item não observado é marcado como concluído.

## Critério de aceite

O código está pronto para a próxima rodada de teste manual, mas esta validação não declara “pronto para uso real” nos itens de rede/ambiente que não puderam ser observados. A matriz deve ser atualizada após executar esses testes, sem converter inferência em PASS.
