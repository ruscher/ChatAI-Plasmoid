# 10 — Plano de testes

## Objetivo

Validar sintaxe, pacote, runtime e regressões sem confundir smoke test com compatibilidade completa.

## Ferramentas

- `qmllint contents/ui/*.qml contents/config/*.qml`
- `python3 -m json.tool metadata.json`
- `xmllint --noout contents/config/main.xml`
- `./tools/build-package.sh`
- `./tools/validate.sh`
- `plasmoidviewer -a .` e `plasmawindowed`
- `journalctl --user` e logs do viewer durante uso real

## Matriz funcional

Instalação nova/upgrade/remoção; widget no desktop e nos quatro painéis; Breeze claro/escuro, HiDPI; carregar, login, cookies, navegação, popup, download, PDF, MHTML, notificação e permissões; todas as configurações; adicionar/editar/remover custom provider e URL inválida.

## Estresse

Abrir, trocar repetidamente entre providers, fechar e reabrir. Registrar crashes, warnings, processos filhos WebEngine e RSS. Verificar que `docs/` pode ser removido sem afetar o pacote.

## Resultados desta etapa

JSON/XML, lint, diff-check, `./tools/validate.sh` e `kpackagetool6 --appstream-metainfo` passam. Viewer Wayland planar, topedge e leftedge permaneceu ativo até timeout; o primeiro teste após a migração do profile encontrou SIGSEGV e a causa foi identificada como `instance()` no binding durante construção. A correção lazy foi retestada com sucesso e sem warning QML próprio.

## Pendências

Login real, downloads reais, PDF/MHTML, permissões, X11, instalação em Plasma 6.6.6 e inspeção de journal ainda não têm evidência nesta sessão.

## Critério de aceite

Toda falha segue teste → causa raiz → correção → novo teste; a validação final conserva o estado NÃO TESTADO quando não houver ambiente ou evidência.
