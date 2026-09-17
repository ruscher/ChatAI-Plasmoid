# 11 — Empacotamento e CI

## Objetivo

Gerar um `.plasmoid` limpo e validar mudanças automaticamente sem depender de arquivos ou versões inexistentes.

## Problemas encontrados

O workflow de tradução existente referencia `pkgbuild/PKGBUILD`, diretório ausente neste checkout, usa dependências externas e não valida QML/pacote. Ele agora fica condicionado à existência desse arquivo; portanto, não falha nem executa serviços de tradução para o plasmoid standalone. Um workflow independente foi adicionado.

## Implementação

`tools/build-package.sh` inclui somente `metadata.json`, `contents/` e `LICENSE`. `tools/validate.sh` valida JSON/XML, roda `qmllint`, testa o zip e impede `docs/`/`.git/` no pacote. `.github/workflows/validate.yml` usa checkout v4, permissões somente leitura e ferramentas disponíveis nos repositórios Ubuntu (`qt6-declarative-dev-tools`, libxml2, zip/unzip).

## Testes / resultado

Scripts executáveis, `git diff --check`, zip e `kpackagetool6 --appstream-metainfo` passam. Instalação efetiva em uma conta Plasma separada e upgrade/remoção ainda são testes manuais pendentes.

## Critério de aceite

Pacote reproduzível, sem logs, dados de sessão ou documentação runtime; CI não recebe tokens de serviços para a validação estática.
