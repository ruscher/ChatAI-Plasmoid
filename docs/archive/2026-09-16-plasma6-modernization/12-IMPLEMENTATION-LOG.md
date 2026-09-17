# 12 — Registro de implementação

## 2026-09-16 — Inventário e baseline

- **Problema:** catálogo e ciclo de vida estavam espalhados.
- **Arquivos:** `main.qml`, `Header.qml`, `WebView.qml`, configuração e metadata.
- **Mudança:** inventário integral, versões locais detectadas (Plasma 6.7.4 / Qt 6.11.2 / Wayland), lint e XML/JSON baseline executados.
- **Teste:** lint reproduziu exit 255 no Header por optional chaining; não houve alteração local pré-existente.
- **Resultado:** riscos P1/P2 catalogados.

## 2026-09-16 — Modelo e layout

- **Problema:** custom provider como array/string inconsistente e reordenação manual de `children`.
- **Arquivos:** `ProviderModel.qml`, `main.qml`, `Header.qml`, `CompactRepresentation.qml`, `ConfigGeneral.qml`.
- **Mudança:** catálogo central, parsing compatível, lookup de ícone/nome, Layout declarativo e tooltip/Accessible name.
- **Teste:** `qmllint` completo e `git diff --check`.
- **Resultado:** PASS local.

## 2026-09-16 — WebEngine e segurança

- **Problema:** concessão genérica de permissões, API deprecated, profile e download instáveis.
- **Arquivos:** `WebView.qml`, `DownloadBar.qml`, `ErrorView.qml`, `contents/config/main.xml`.
- **Mudança:** profile prototype lazy, permissions deny-by-default para tipos desconhecidos, TLS reject, URL HTTP(S), filename seguro, estados de download por ID, retry/browser fallback.
- **Teste:** primeira tentativa acusou SIGSEGV em `QQuickWebEngineView::setProfile`; causa foi profile prototype no binding de construção. Instância foi movida para `Component.onCompleted` com `WebEngine.defaultProfile` fallback. Viewer retestado por 15 s.
- **Resultado:** PASS de estabilidade smoke; funcionalidades de rede ainda parciais.

## 2026-09-16 — Documentação e automação

- **Problema:** README/CI não descreviam requisitos nem validavam o pacote.
- **Arquivos:** `README.md`, `tools/*`, `.github/workflows/validate.yml`, `docs/*`.
- **Mudança:** documentação de engenharia, build/validate scripts e CI estático sem segredos.
- **Teste:** JSON/XML/lint/package zip local, `kpackagetool6 --appstream-metainfo` e smoke viewer.
- **Resultado:** PASS local de validação estática, pacote e smoke Wayland; warnings restantes pertencem a `org.kde.desktopcontainment`, não ao projeto.

## 2026-09-16 — Isolamento do workflow legado

- **Problema:** o workflow de tradução era acionado em todo push apesar de depender de `pkgbuild/PKGBUILD`, ausente no repositório standalone.
- **Arquivo:** `.github/workflows/translate-and-build-package.yml`, `docs/11-PACKAGING-CI.md`.
- **Mudança:** job condicionado por `hashFiles('pkgbuild/PKGBUILD')`; a validação própria continua no workflow dedicado.
- **Teste:** validação local, inspeção de status e `git diff --check`.
- **Resultado:** PASS; o fluxo legado fica inativo sem apagar sua integração futura.

## 2026-09-16 — Regressão final

- **Problema:** confirmar que as mudanças finais não introduziram avisos QML ou artefatos no pacote.
- **Teste:** `./tools/validate.sh`, `plasmawindowed` por 12 s, `kpackagetool6 --appstream-metainfo`, `qmllint`, `git diff --check` e filtro do `journalctl --user`.
- **Resultado:** PASS estático, de empacotamento e smoke local; nenhum warning próprio do ChatAI-Plasmoid observado.
