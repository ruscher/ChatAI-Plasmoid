# 08 — Perfil WebEngine e cache

Status: **implementado** (evidências em 12 e 14).

## Perfil

- `WebEngineProfilePrototype { storageName; httpCacheType: DiskHttpCache; persistentCookiesPolicy: ForcePersistentCookies; persistentPermissionsPolicy: StoreOnDisk; httpCacheMaximumSize }`, instância criada em `Component.onCompleted` (padrão já validado na rodada anterior; evita o SIGSEGV de criar durante o binding).
- `storageName` deriva de `webEngineProfileName` sanitizado (`[A-Za-z0-9._-]`, ≤ 64) — inalterado.
- `httpUserAgent` e `downloadPath` são aplicados na instância; UA descrito em 06/09.
- Nenhum outro `WebEngineProfile` é criado (a tela de configurações deixa de criar um).

## Caminhos exibidos sem WebEngine

`cachePath = CacheLocation/QtWebEngine/<storageName>` e
`persistentStoragePath = AppLocalDataLocation/QtWebEngine/<storageName>`, conforme a documentação do
`WebEngineProfile`. Calculados com `StandardPaths` em QML.

## Cache

- Limite: `httpCacheMaximumSize` em MB (0 = automático), configurável em Cache e Dados.
- Limpeza: `profile.clearHttpCache()` → estado "Limpando…" até `clearHttpCacheCompleted`; durante a operação
  os botões de navegação/reload do runtime ficam desabilitados (recomendação da documentação de não navegar).
- Nunca remover diretórios manualmente com o Chromium em execução.
- Tamanho aproximado: não há API QML barata; não exibido (documentado).

## Perfil do WebEngine (UI)

Título "Perfil do WebEngine", com "Nome de armazenamento" como campo secundário e explicação:
"Cada nome cria um diretório separado com cookies, logins, cache e permissões. Use nomes diferentes
para manter contas separadas entre instâncias do widget." Ações: alterar (aplica ao reabrir o WebView),
restaurar padrão (`chat-ai`), abrir pasta. Aviso explícito: "Alterar o nome recria o WebView; as sessões
do nome anterior permanecem no disco." A alteração só é aplicada após confirmação.

## Riscos

Mudar `storageName` com WebView vivo não é suportado; o runtime recria o Loader (Close + Open) após confirmação.
