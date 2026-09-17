# 02 — Compatibilidade Plasma 6 / KF6 / Qt 6

## Objetivo

Usar APIs declarativas atuais sem depender de Plasma 6.7+, Qt 6.11+ ou APIs removidas.

## Estado atual

`metadata.json` já usa `KPackageStructure: Plasma/Applet` e `X-Plasma-API-Minimum-Version: 6.0`. O ambiente disponível reporta Plasma 6.7.4, Qt 6.11.2, KF6 e sessão Wayland, não o alvo exato solicitado.

## Problemas encontrados

- Metadata não tinha versão nem `BugReportUrl` e apontava ao endereço histórico do projeto.
- Imports KDE versionados em páginas de configuração (`Kirigami 2.20`, componentes 3.0, labs platform 1.1) não eram necessários no port KF6.
- O alvo Qt 6.10 não pode consumir a API nova sem confirmar a versão.

## Solução escolhida

O metadata agora identifica o repositório atual, possui versão `1.0.0` e URL de bugs. Imports QML foram desversionados onde o módulo fornece a API moderna. `WebEngineProfilePrototype` foi usado porque a documentação Qt 6.10 o declara disponível desde Qt WebEngine 6.9.

Referências oficiais: [porting Plasmoids to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/), [setup de widgets Plasma](https://develop.kde.org/docs/plasma/widget/setup/), [WebEngineProfile Qt 6.10](https://doc.qt.io/qt-6.10/qml-qtwebengine-webengineprofile.html) e [WebEngineProfilePrototype Qt 6.10](https://doc.qt.io/qt-6.10/qml-qtwebengine-webengineprofileprototype.html).

## Arquivos afetados

`metadata.json`, `contents/ui/*.qml`, `contents/config/*.qml` e `contents/config/main.xml`.

## Testes

`python3 -m json.tool`, `xmllint` e `qmllint` passavam após a correção. `plasmoidviewer` inicia com o Qt instalado e não emite warning QML próprio no smoke test.

## Pendências / critério de aceite

Plasma 6.6.6, KF 6.24.0, Qt 6.10.2 e X11 não estão instalados nesta sessão: ficam como ⚠️ NÃO TESTADO, não como PASS. O código usa apenas APIs confirmadas na documentação Qt 6.10 ou mais antigas.
