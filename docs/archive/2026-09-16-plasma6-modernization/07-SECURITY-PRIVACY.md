# 07 — Segurança e privacidade

## Objetivo

Limitar a superfície local do widget e deixar decisões sensíveis explícitas.

## Problemas encontrados

Esquemas desconhecidos eram permitidos por default; certificado não tinha tratamento próprio; o filename sugerido podia conter caminhos; permissões de mídia tinham ramo morto seguido de concessão genérica.

## Solução escolhida

- Custom providers e URLs digitadas aceitam somente HTTP/HTTPS.
- Unknown URL schemes ficam desabilitados por default e navegações não HTTP(S) são ignoradas.
- `certificateError` rejeita certificados inválidos sem bypass silencioso.
- Downloads removem separadores, `..`, controles e caracteres reservados; não há execução automática.
- Notificações só aparecem se habilitadas; áudio, vídeo, tela e geolocalização têm decisões independentes, com mídia default false em novas configurações.
- Não são logados cookies, tokens, headers ou conteúdo privado.

## Impacto / alternativas

Bloquear esquemas pode impedir links `mailto:` ou integrações específicas, mas é preferível a abrir protocolo arbitrário no desktop. O usuário pode abrir URLs HTTP(S) no navegador; suporte a protocolos adicionais requer allowlist explícita futura.

## Testes / pendências

Lint, inspeção de regex e smoke viewer passaram. Não foi possível simular certificado ruim, path sem permissão, falta de espaço ou cada permission request. Esses itens estão como NÃO TESTADO na matriz.

## Critério de aceite

Nenhum valor arbitrário chega a shell/execução; Qt/KDE abre somente URLs aprovadas; documentação não contém credenciais.
