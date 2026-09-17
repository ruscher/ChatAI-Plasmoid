# 03 — QML / Qt Quick Optimization

Audited every `contents/ui/**/*.qml` for expensive bindings, eager component
creation, redundant Loaders and layout thrash.

## Bindings
- No binding builds arrays / runs `map`/`filter`/`reduce`/regex on a per-frame or
  high-frequency signal. The array-building bindings (`ProviderModel.enabledProviders`,
  `AiSelector.entries`) recompute only on config changes (rare).
- Width-driven bindings during a resize drag are trivial arithmetic/ternaries.
- Kept as bindings on purpose — converting them to imperative code would remove
  reactivity for no measurable gain (idle CPU already 0%).

## Loaders (already correct)
- `webviewLoader` (async) and `settingsLoader` in `main.qml`; `authPopupLoader`,
  `devToolsLoader`, `fullScreenLoader` in `WebView.qml` — all `active: false`
  until needed. DevTools/FullScreen/Auth therefore cost **nothing** until used.
- Not over-Loaderized: small always-present items (Header buttons) are plain
  components — correct, since a Loader has its own overhead.

## Component.onCompleted
- `main.qml`: `Migration.run()` once (needed early, cheap).
- `WebView.qml`: profile creation + `applyZoom()` + deferred `goHome()` — the
  minimum required before first navigation.
- No heavy work runs on the critical open path that could be deferred without
  breaking correctness.

## Animations
- Header show/hide uses short `NumberAnimation`s gated by `shouldBeVisible`; they
  don't run while the header is stably visible/hidden. No continuous idle
  animation exists (consistent with 0% idle CPU).

## Layout
- No relayout storms found; the auto-hide header animates `Layout.preferredHeight`
  only during the transition.

## Change made in this area
- **Navigation binding removed** (see `12`, WebView): the reactive
  `url: plasmoid.configuration.url` binding was replaced by a single explicit
  `navigateTo()` path. This removes a class of double-navigation races and is a
  correctness + reliability win (fixes intermittent blank page on provider
  switch), not just performance. qmllint clean.

Verdict: no further QML micro-optimizations are justified by evidence.
