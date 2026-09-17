# 05 — UX/UI

## Objetivo

Fazer o widget parecer nativo do Plasma, priorizando conteúdo, tema, responsividade e feedback.

## Estado atual / problemas

O layout usava valores de grid razoáveis, mas a barra tinha muitos botões sem hierarquia, o erro de load não tinha recuperação visual e o ícone custom podia apontar para asset inexistente. O header auto-hide usava timer de polling e animações de 400 ms.

## Implementação

- `CompactRepresentation.qml` usa métricas Kirigami, hover/tooltip, nome do provider e fallback para logo quando não há asset específico.
- `main.qml` mantém header, faixa de download e WebEngine em Layout declarativo, sem manipulação manual de `children` e com animação de 150 ms.
- `ErrorView.qml` apresenta motivo, retry e abertura segura no navegador.
- `DownloadBar.qml` mostra nome, estado, progresso, pausa/retomada, cancelamento, abertura e remoção.
- Cores e tipografia seguem `Kirigami.Theme`, `Kirigami.Units` e Plasma Components.

## Alternativas consideradas

Uma tela de seleção totalmente customizada com busca/favoritos aumentaria o risco de popup e foco no Plasma; a seleção atual foi primeiro estabilizada com catálogo centralizado. Busca, favoritos e recentes ficam autorizados como próxima iteração.

## Testes / pendências

Smoke em viewer planar Wayland passou. Breeze claro/escuro, quatro bordas, HiDPI e teclado completo não foram exercitados nesta sessão. O critério de aceite final exige PASS somente após esses testes reais.
