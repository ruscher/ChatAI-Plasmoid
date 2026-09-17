# 04 — Roteiro de testes: login com conta Google

Regras: nunca registrar senha, código, token, cookie ou query string; logs de teste usam apenas host + caminho.
Aprovado somente quando o usuário termina **autenticado dentro do serviço** e a sessão sobrevive a fechar/reabrir.

## Pré‑requisitos

- ChatAI ≥ 1.0.1 com o redesign instalado; plasmashell reiniciado (`kquitapp6 plasmashell && kstart plasmashell`).
- Avançado › "Identificar como Chromium" **desligado** (padrão). O Google rejeita identidade disfarçada (docs/05 raiz).
- Popup com largura ≥ 780 px (mínimo imposto) para evitar o layout mobile do ChatGPT.
- Para reproduzir do zero: Cache e Dados › Nome de armazenamento → novo nome (ex.: `chat-ai-teste`) cria um perfil limpo
  sem apagar o atual.

## Registro por provedor

```
provider · login abriu? · popup ou redirect? · e‑mail ok? · senha ok? · 2FA ok? · consentimento ok? ·
callback ocorreu? · popup fechou? · sessão principal autenticada? · permaneceu ao reabrir? · resultado
```

## A. ChatGPT (fluxo por redirect, frame principal)

1. Seletor → ChatGPT. Aguardar a página (se ficar em 0 % por 12 s aparece o aviso "demorando a responder": usar Tentar novamente).
2. "Fazer login" → "Continuar com o Google". Esperado: a view principal navega `auth.openai.com/api/accounts/authorize`
   → `accounts.google.com`; nenhum popup.
3. Escolher conta / e‑mail → Avançar → senha → 2FA se solicitado (prompt no celular, TOTP ou chave: seguir as instruções).
4. Consentimento (se houver) → redirect de volta a `auth.openai.com/…/callback` → `chatgpt.com`.
5. Confirmar: avatar/nome no ChatGPT; enviar uma mensagem de teste.
6. Fechar o popup do plasmoid (clicar fora) e reabrir → ainda autenticado. Fechar com ✕ (libera memória) e reabrir → ainda autenticado.
7. Reiniciar o plasmashell → ainda autenticado (cookies persistentes no perfil `chat-ai`).

## B. Claude (fluxo por popup `window.open`, 500×550)

1. Seletor → Claude → "Continue with Google".
2. Esperado: abre a **janela de login interna** ("Sign in — accounts.google.com") sobre a página, com ícone de cadeado,
   indicador de carregamento e botão ✕.
3. Conta → senha → 2FA/consentimento.
4. Esperado: o callback (`claude.ai/…/callback` ou `accounts.google.com/gsi/…`) roda no popup, o popup **fecha sozinho**
   (`window.close()` → `windowCloseRequested`) e a página principal do Claude aparece autenticada, sem recarregar manualmente.
5. Repetir os passos 6–7 de A.
6. Negativo: fechar o popup pelo ✕ no meio do login → página principal intacta, sem tela preta; refazer o login funciona.

## C. Google Gemini (mesma conta Google, redirect)

1. Seletor → Gemini → "Fazer login" → `accounts.google.com` na view principal → conta/senha/2FA → volta a `gemini.google.com/app`.
2. Passos 6–7 de A.

## D. Perplexity, Mistral Vibe, Qwen, Kimi, Manus, Grok, T3 (quando oferecem Google)

Anotar se o botão abre popup (`window.open`) ou redirect; seguir A ou B conforme o caso.

## E. 2FA / passkey / prompts

- Verificação em duas etapas por celular: manter o popup/widget aberto até confirmar; o widget não congela a página
  durante o login (`busy` inclui `authPopupOpen`).
- Passkey/WebAuthn: o Qt WebEngine 6.11 emite `webAuthUxRequested`; não há UI implementada no ChatAI → o Google oferece
  "Tentar de outra forma" (senha/celular). Documentar como limitação, não travar.
- Escolha de conta, recuperação e consentimento: fluxos de página normal, devem passar.

## F. Tela preta

Reproduzir o cenário antigo: com a 1.0.1 anterior, Claude → Google → callback na view principal sem `opener` ficava em
branco/preto. Com o redesign: não pode ocorrer. Se ocorrer, capturar `⋮ › Avançado › Diagnóstico` e host+caminho da URL.

## G. Wayland e X11

Repetir A e B nas duas sessões; observar foco ao abrir/fechar o popup interno, clipboard (colar código 2FA), Esc fecha o popup.
