# 00 — Plano mestre: autenticação Google e redesign de Downloads/Toolbar

Status: **em execução** (2026‑09‑17). Base: ChatAI 1.0.1 (`5138b71`). Ambiente: Plasma 6.7.4, Qt/Qt WebEngine 6.11.2 (Chromium 140), Wayland.

## Objetivos

1. Login por conta Google concluindo de verdade (callback recebido, sessão na página principal, sem spinner infinito ou tela preta), dentro do widget, sem spoofing de identidade e sem reduzir segurança.
2. Toolbar mais limpa: "Ocultar barra automaticamente" e "Downloads" deixam de ser botões permanentes; ficam no menu ⋮.
3. Downloads dinâmicos: indicador temporário com progresso real na toolbar, popup de gerenciamento (pausar/retomar/cancelar/abrir/mostrar na pasta/tentar de novo), estado "visto", histórico no ⋮, sem barra fixa ocupando o rodapé.

## Método

```
AUDITAR (01) → REPRODUZIR com instrumentação sanitizada → ROOT CAUSE (02) → DOCUMENTAR (03) →
IMPLEMENTAR → VALIDAR (lint, unit) → TESTAR manual (04, 05) → REVISAR UX/segurança/perf → RESULTADO (07)
```

Regras: reutilizar `downloadsModel`/`downloadCache`/ações existentes; uma única fonte de verdade para downloads; mesmo `WebEngineProfile` para qualquer view auxiliar; nenhuma URL com query/tokens em logs; nenhum navegador externo como "solução" do OAuth.

## Entregas

| Doc | Conteúdo |
| --- | --- |
| 01 | Estado atual: login, OAuth, perfil, cookies, popups, redirects, UA, downloads, toolbar |
| 02 | Causa raiz técnica do Google OAuth com reprodução e prova da correção |
| 03 | Arquitetura da nova UX de downloads |
| 04 | Roteiro de teste do login Google por provedor |
| 05 | Testes de downloads (unitários e manuais) |
| 06 | Log de implementação (arquivo, problema, mudança, motivo, risco, teste, resultado) |
| 07 | Validação final e critérios de aceite |

## Componentes previstos

`WebView.qml` (popup OAuth com `openIn`, `windowCloseRequested`, estado de downloads), `AuthPopup.qml` (novo: view auxiliar
com o mesmo perfil), `DownloadIndicator.qml` (novo: botão temporário com anel de progresso), `DownloadPopup.qml` (novo:
lista e ações), `DownloadBar.qml` (removido/substituído), `Header.qml`, `ChatAIMenu.qml`, `ProviderModel.qml`
(`isAuthUrl` seguro), `settings/DownloadsSettings.qml`, `tools/tests/`.
