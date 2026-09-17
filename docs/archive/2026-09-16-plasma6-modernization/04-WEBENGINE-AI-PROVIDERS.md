# 04 — WebEngine e provedores de IA

## Objetivo

Tornar perfil, navegação, permissões, downloads e falhas previsíveis no Qt WebEngine 6.10.

## Estado atual / causa

O perfil antigo era criado dentro de `WebEngineView` com propriedades mutáveis. O código usava `featurePermissionRequested` (deprecated desde 6.8), concedia permissões genericamente, e conectava downloads a índices capturados. Serviços externos podem bloquear WebEngine por decisão própria.

## Implementação

- `WebEngineProfilePrototype` cria o perfil nomeado persistente; a instância só é obtida em `Component.onCompleted`, mantendo um perfil padrão válido durante a construção do view.
- Cookies persistentes, cache em disco e permissões `AskEveryTime` permanecem explícitos.
- `permissionRequested` mapeia Notifications, Geolocation, áudio, vídeo e DesktopAudioVideoCapture para suas configurações; qualquer tipo não conhecido é negado. Não há `request.grant()` genérico.
- TLS inválido é rejeitado; fullscreen controlado pela página é rejeitado no widget embutido.
- Somente HTTP/HTTPS navega ou é aberto externamente; autenticação em domínios conhecidos continua no view.
- Favicon é consultado somente após load bem-sucedido. O listener JavaScript de Enter foi removido para não acumular handlers/intervalos.

## Downloads

O pedido é aceito explicitamente, recebe diretório configurado e nome sanitizado sem separadores, `..`, caracteres de controle ou caracteres reservados. Cada item usa o ID nativo do Qt; progresso, pausa, retomada, cancelamento, conclusão e interrupção são refletidos em `DownloadBar.qml`. Arquivos não são executados automaticamente.

O Qt documenta `DownloadRequested`, `DownloadInProgress`, `DownloadCompleted`, `DownloadCancelled` e `DownloadInterrupted`; `totalBytes <= 0` é tratado como tamanho desconhecido. Veja [WebEngineDownloadRequest Qt 6.10](https://doc.qt.io/qt-6.10/qml-qtwebengine-webenginedownloadrequest.html).

## Impacto / pendências

O perfil privado não foi adicionado porque trocar `storageName` depois que o view existe exigiria recriar o WebEngine e uma UX de confirmação. Prompt por site também é uma evolução futura; atualmente as configurações são uma decisão explícita do usuário e os defaults sensíveis são deny.

## Testes / critério de aceite

Viewer com WebEngine ficou estável após a correção de criação lazy. Downloads, PDF, MHTML, login e os provedores individuais ainda precisam de teste manual com rede e credenciais; ficam marcados na matriz final como parcial/não testado.
