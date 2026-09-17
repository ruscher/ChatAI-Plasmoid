# 06 — Network, Cache, Storage

## Profile (WebEngineProfilePrototype)
- `storageName` = sanitized `webEngineProfileName` (default `chat-ai`) → persistent
  on disk; **login/cookies survive restarts and upgrades**. Correct.
- `httpCacheType: DiskHttpCache`; `httpCacheMaximumSize` from config
  (`httpCacheMaximumSize` MiB, 0 = let Qt decide). Good default (no artificial
  cap that would hurt warm loads).
- `persistentCookiesPolicy: ForcePersistentCookies`,
  `persistentPermissionsPolicy: StoreOnDisk` — needed for sessions/permissions.

## Rules confirmed (all correct, keep)
- **No cache wipe on startup.** Cache is only cleared via the explicit "Clear
  cache" action (`clearHttpCache`, guarded by `clearingCache`). Wiping on start
  would hurt performance, bandwidth and login — correctly avoided.
- **No blocking of provider scripts/resources / no ad-block injection.** The
  plasmoid does not interfere with provider network traffic (would break the
  sites). Only main-frame navigation is scheme-restricted to http(s); sub-frames
  (Turnstile, Google One Tap, blob:/data:) are allowed. Correct.
- Profile is **not recreated** on normal config changes; only a storage-name
  change triggers `recreateWebView()` (a fresh profile is genuinely required
  then). No accidental login loss on ordinary updates.

## Findings
- No plasmoid-originated redundant requests found (the widget itself makes no HTTP
  requests; all traffic is the provider page).
- Service workers / IndexedDB / localStorage are the provider's; not touched.

No changes warranted. Any cache/storage change here would risk login/perf for no
measured gain.
