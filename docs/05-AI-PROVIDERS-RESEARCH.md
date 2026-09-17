# 05 — Pesquisa de provedores de IA (setembro/2026)

Status: **concluída**. Fontes: sites oficiais, centrais de ajuda e testes reais de carregamento com
Qt WebEngine 6.11 (Chromium 140) em perfil off‑the‑record, UA padrão do Qt e UA sem o token `QtWebEngine`
(`tools/provider-probe/`). Login, upload e microfone exigem credenciais e são marcados como
NÃO TESTADO quando não puderam ser exercitados.

## Matriz

| Serviço | Relevância | Chat Web | QtWebEngine (load) | Login | Recursos | Adicionar? | Motivo |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **GitHub Copilot** (`github.com/copilot`) | Alta (código) | Sim, modo imersivo GA | PASS com UA sem token `QtWebEngine`; FAIL (`net::ERR_NETWORK_*`) com o token | GitHub (OAuth GitHub próprio; 2FA) | upload de imagem, web search, contexto de repositório | **Sim** | Distinto do Microsoft Copilot; útil para desenvolvedores; UI conversacional |
| **Manus** (`manus.im/app`) | Alta (agente) | Sim; Chat Mode desde 1.6 (2026) | PASS (redireciona para `/login`) | e‑mail, Google, Apple | upload, agente, web app builder | **Sim** | Interface web oficial, ativa; login Google pode exigir credenciais criadas em navegador |
| **Qwen Studio / Qwen Chat** (`chat.qwen.ai`) | Alta | Sim (título "Qwen Studio") | PASS, campo de entrada presente | e‑mail, Google, GitHub | upload, imagem/vídeo, web search, artifacts | **Sim** | App oficial da Alibaba; funciona anônimo para experimentar |
| **Kimi** (`www.kimi.com`) | Alta | Sim (chat + agent) | PASS, campo de entrada presente | telefone/e‑mail, Google | upload, Swarm/deep research | **Sim** | Moonshot ativa (K3, jul/2026). `kimi.ai` redireciona para `www.kimi.ai` — usamos `kimi.com` (oficial) |
| **Mistral Vibe** (`chat.mistral.ai`) | Alta | Sim — "Le Chat is now Vibe" (28/05/2026), mesma URL | PASS (título "Vibe Chat") | e‑mail, Google, Apple, Microsoft | upload, web search, code | **Sim** | Nome oficial atual: **Vibe**; URL inalterada segundo a central de ajuda |
| ChatGPT | Alta | Sim | TIMEOUT no harness headless (Cloudflare/JS pesado sem GPU); em sessão real carrega (1.0.0 em uso) | e‑mail, Google (bloqueado em WebView), Apple, Microsoft | tudo | manter | já existente |
| Claude | Alta | Sim | PASS (`/login`) | e‑mail + código, Google (bloqueado em WebView) | upload, projetos | manter (habilitar por padrão) | já existente |
| Google Gemini | Alta | Sim | PASS | Google (login precisa de sessão criada em navegador) | upload, voz | manter | já existente |
| DeepSeek | Alta | Sim | PASS (`/sign_in`) | e‑mail, Google | upload | manter | já existente |
| Microsoft Copilot (`copilot.microsoft.com`) | Alta | Sim | PASS, entrada presente | Microsoft, opcional | voz, imagem | manter; **renomear exibição** "Bing Copilot" → "Microsoft Copilot" (`showBingCopilot` preservado) | nome público atual |
| Perplexity | Alta (pesquisa) | Sim | PASS, entrada presente | opcional | web search | manter | já existente |
| DuckDuckGo Duck.ai | Alta (privacidade) | Sim | PASS com UA desktop; `duckduckgo.com/chat` → `duck.ai/chat` | não requer | voz (2026) | manter; **URL canônica `https://duck.ai/chat`**, remover UA mobile | redirect confirmado |
| HuggingChat | Média | Sim — fechado em jul/2025, **relançado em out/2025 (Omni)** | PASS, entrada presente | HF opcional | modelos abertos | manter | ativo |
| Grok | Alta | Sim — app standalone `grok.com` | `grok.com` PASS com entrada anônima; `x.com/i/grok` redireciona para onboarding do X | X, Google, Apple, e‑mail | voz, imagem | manter; **URL → `https://grok.com`**, remover UA mobile | app oficial standalone |
| Meta AI (`meta.ai`) | Média | Sim (regiões limitadas) | PASS (página de login) | Facebook/Instagram | — | manter (desligado por padrão) | disponibilidade regional |
| You.com | Baixa (pivot enterprise em 2022–2026) | Sim, exige login | PASS (`/signin`) | e‑mail, Google | — | manter desligado; documentar | ainda funciona |
| BlackBox AI | Média (código) | Sim | PASS (landing com botão de login; `app.blackbox.ai/chat` redireciona à landing) | e‑mail, Google | — | manter desligado | ativo |
| T3 Chat | Média | Sim | PASS, entrada presente (429 em `curl`, mas carrega no WebEngine) | e‑mail, Google | multi‑modelo | manter | ativo (jul/2026) |
| LobeChat (`lobechat.com`) | Baixa | Sim → `app.lobehub.com/signin` | PASS (login) | e‑mail, Google, GitHub | — | manter desligado; **URL → `https://lobechat.com/chat`** já redireciona; ícone 129 KB otimizado | self‑host focus |
| Big‑AGI (`get.big-agi.com`) | Baixa | Sim → `app.big-agi.com` | PASS | e‑mail, Google | BYOK | manter desligado | nicho |
| Poe, Character.ai, Pi, Replika | — | Sim | não testado | — | — | **Não** | Poe agrega modelos já cobertos; Character/Replika não são assistentes de trabalho; Pi descontinuado como produto principal |

Nenhum provedor foi removido: todos carregam. Notas de compatibilidade por provedor ficam no registro
(`loginNotes`, `compatibilityNotes`) e aparecem na página Sites.

## Conjunto habilitado por padrão (novas instalações)

ChatGPT, Claude, Google Gemini, DeepSeek, Duck.ai, HuggingChat, T3 Chat (inalterado para não alterar
o comportamento de quem depende dos padrões) **+ Claude** (passa a `true`). Novos provedores (GitHub Copilot,
Manus, Qwen, Kimi, Mistral Vibe) começam desligados e aparecem na página Sites com ícone e descrição.
Racional: mudar padrões de chaves existentes altera silenciosamente listas de usuários; adicionar é seguro.

## User‑Agent

- UA padrão do Qt 6.11: `Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) QtWebEngine/6.11.2 Chrome/140.0.0.0 Safari/537.36`.
- Único caso com diferença mensurável: GitHub (`net::ERR_NETWORK_*` com o token `QtWebEngine`, PASS sem ele — 2 execuções). Relatos anteriores dos mantenedores: ChatGPT e DeepSeek rejeitavam o token.
- Decisão: UA global = UA padrão do Qt **sem o token `QtWebEngine/x.y.z`** (calculado em runtime a partir de
  `WebEngine.defaultProfile.httpUserAgent`, mantendo a versão real do Chromium). Nenhum UA mobile/Chrome 76 permanece.
  Override por provedor continua possível via `userAgent` no registro (nenhum usado). `customUserAgent` em Avançado substitui tudo.

## Ícones

| Provedor | Fonte | Licença | Variantes |
| --- | --- | --- | --- |
| GitHub Copilot, Qwen, Kimi, Mistral, Meta | Simple Icons (CC0 1.0) | CC0; marcas pertencem aos respectivos donos | colorful (cor da marca), filled dark/light |
| Manus | `manus.im/icon.svg` (ícone oficial do site) | uso nominativo da marca | colorful, filled dark/light (monocromatizado) |
| Grok | `grok.com/images/favicon.svg` contém `foreignObject`/filtros não suportados por QtSvg → **não usado**; fallback para o logo do ChatAI | — | — |
| BlackBox, You | apenas PNG oficiais → fallback logo | — | — |
Outlined não é produzido para os novos (fallback: filled). Todos otimizados com `svgo`.
