# 07 — Permissões, privacidade e segurança

Status: **planejado → implementado**.

## Permissões (Qt WebEngine ≥ 6.8 API moderna)

### Atual
`persistentPermissionsPolicy: AskEveryTime` + `onPermissionRequested` com decisão global por tipo
(grant/deny imediato). Sem prompt ao usuário, sem persistência, sem gerenciamento por origem.
`onFeaturePermissionRequested` (obsoleto) não é usado — correto.

### Desejado
- Política **por tipo**, com três valores: `Perguntar` (0), `Permitir` (1), `Bloquear` (2).
- Prompt inline (`PermissionBar.qml`) quando a política é Perguntar: "*origem* quer usar o microfone — [Permitir] [Bloquear]". A decisão é persistida **por origem** pelo próprio WebEngine.
- `persistentPermissionsPolicy: StoreOnDisk`: origens já decididas não geram novo pedido; a lista é consultável via `listAllPermissions()`; cada item pode ser resetado (`reset()`).
- Tipos desconhecidos/`Unsupported` → `deny()` sempre. Nenhum caminho sem `grant()`/`deny()`.
- Enums do QML (`WebEnginePermission.MediaAudioCapture`, …) em vez de números.

### Mapeamento

| Tipo `WebEnginePermission` | Chave | Padrão novo | Migração (chave Bool antiga) |
| --- | --- | --- | --- |
| `Notifications` | `notificationsPolicy` | Perguntar | `notificationsEnabled`: false → Bloquear; true → Perguntar |
| `MediaAudioCapture` | `microphonePolicy` | Perguntar | `microphoneEnabled`: true → Permitir; false → Perguntar |
| `MediaVideoCapture` | `webcamPolicy` | Perguntar | `webcamEnabled`: idem |
| `MediaAudioVideoCapture` | mic **e** câmera | — | ambas devem permitir; se qualquer uma bloqueia → deny; senão pergunta |
| `DesktopVideoCapture`, `DesktopAudioVideoCapture` | `screenSharePolicy` | Perguntar | `screenShareEnabled`: idem |
| `Geolocation` | `geolocationPolicy` | Perguntar | `geolocationEnabled`: idem |
| `ClipboardReadWrite` | `clipboardPolicy` | Perguntar | — |
| `MouseLock`, `LocalFontsAccess`, `Unsupported` | — | Bloquear | — |

Racional da migração: para chaves cujo padrão antigo era `false` (mic, câmera, tela, localização), `false`
não distingue "nunca configurei" de "quero bloquear"; `Perguntar` preserva a privacidade (nada é concedido
sem clique) e melhora a UX. Para notificações, o padrão antigo era `true`: quem desligou explicitamente
queria bloquear → `Bloquear`.

### Persistência: AskEveryTime × StoreInMemory × StoreOnDisk

| Política | Conveniência | Privacidade | Revogação |
| --- | --- | --- | --- |
| AskEveryTime | Pergunta a cada carregamento (login por voz fica irritante) | máxima | n/a |
| StoreInMemory | Lembra até fechar o WebView (Close destrói o perfil em memória) | boa | perde-se ao fechar |
| **StoreOnDisk** (escolhida) | Lembra por origem entre sessões | boa, desde que haja UI de revisão | `reset()` por item, "Limpar todas" |

A UI de revisão/revogação existe em Permissões (requer o widget aberto porque a lista vem da instância do perfil).

### Compartilhamento de tela
`desktopMediaRequested`: se `screenSharePolicy` ≠ Bloquear, seleciona a primeira tela (`screensModel`);
Bloquear → `request.cancel()`. `settings.screenCaptureEnabled` segue a política.

## Cookies e sessão

`ForcePersistentCookies` grava também cookies de sessão. Para manter login entre reinícios do Plasma,
alguns provedores usam cookies de sessão (sem `Expires`), então `AllowPersistentCookies` poderia
desconectar o usuário a cada login. Decisão: **manter `ForcePersistentCookies`** e documentar que o
perfil guarda cookies, storage e cache no diretório do perfil. Não há API QML para limpar cookies;
a UI explica e oferece "Abrir pasta do perfil" e troca de nome de perfil (nova sessão limpa).

## WebEngineSettings (defaults)

| Setting | Antes | Depois | Motivo |
| --- | --- | --- | --- |
| `javascriptCanAccessClipboard` | true | true | botões "Copiar" dos chats dependem de escrita no clipboard |
| `javascriptCanPaste` | true | **false** (novos usuários) | leitura do clipboard por JS é sensível; Ctrl+V do usuário não depende disso |
| `javascriptCanOpenWindows` | true | true | popups de OAuth; todo `newWindowRequested` é interceptado |
| `unknownUrlSchemePolicy` | Disallow por padrão | igual; `AllowUnknownUrlSchemesFromUserInteraction` quando habilitado | nunca `AllowAll` |
| `screenCaptureEnabled` | = screenShareEnabled | = política ≠ Bloquear | |
| `pluginsEnabled` | true | true | visualizador de PDF interno |
| `allowWindowActivationFromJavaScript` | true | true | |
| `forceDarkMode` | por luma do tema | igual | |

## Navegação, novas janelas e autenticação

- Somente `http(s)` navega ou abre externamente. Outros esquemas: ignorados e notificados.
- `newWindowRequested`: URL de autenticação → navega na própria view; senão → navegador externo.
- Detecção de autenticação: lista de hosts conhecidos (Google, Apple, Microsoft, GitHub, Meta, X, Alibaba,
  Moonshot, Mistral) **e** heurística de caminho (`/oauth`, `/authorize`, `/login`, `/signin`, `/sso`,
  `/auth`, `openid`, `saml`), centralizada em `ProviderModel.isAuthUrl()`.
- Limitação documentada: o Google bloqueia login OAuth em WebViews embutidas (`disallowed_useragent`)
  independentemente do UA em muitos casos; a alternativa legítima é entrar com e‑mail/senha ou usar
  cookies de sessão criados em navegador (aviso já exibido para Claude e agora generalizado).

## Dados: distinção clara na UI

| Ação | O que faz | Confirmação |
| --- | --- | --- |
| Limpar cache HTTP | `profile.clearHttpCache()`; sem navegação até `clearHttpCacheCompleted` | não |
| Limpar permissões por site | `listAllPermissions().forEach(p => p.reset())` | sim |
| Trocar nome do perfil | novo diretório; sessões atuais deixam de ser usadas (não apagadas) | sim |
| Cookies/sessões | não há API QML; explicado; use "Sair" nos sites ou apague a pasta com o widget fechado | — |

## O que não é prometido

Não há anonimato: cada site vê o IP e o UA. Não há proteção contra rastreamento além do próprio Chromium.
