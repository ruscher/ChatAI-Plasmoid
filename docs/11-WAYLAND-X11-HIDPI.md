# 11 — Wayland, X11 e HiDPI

Status: **planejado → implementado; Wayland testado, X11 NÃO TESTADO nesta máquina**.

| Recurso | Implementação | Wayland | X11 |
| --- | --- | --- | --- |
| Fullscreen | `FullScreenWindow` (`QtQuick.Window`) com `visibility: Window.FullScreen`; a `WebEngineView` é reparentada para a janela e devolvida ao sair | `xdg_toplevel.set_fullscreen` via Qt | `_NET_WM_STATE_FULLSCREEN` via Qt |
| Popups/menus | `PlasmaComponents3.Menu` (QQC2 Popup, dentro da janela do popup) | ok | ok |
| Clipboard | `WebEngineView.triggerWebAction(Copy)` / JS com permissão | ok | ok |
| Drag and drop | Qt/Chromium | — | — |
| Compartilhamento de tela | `desktopMediaRequested` → `selectScreen` (Chromium usa PipeWire/xdg-desktop-portal no Wayland) | portal | X11 direto |
| Seletor de arquivos | Chromium → QtWebEngine → diálogo Qt/KDE | ok | ok |
| Notificações | KNotification (`plasma_workspace`) | ok | ok |
| Abrir pasta/browser | `Qt.openUrlExternally` | ok | ok |
| Foco | `focusOnNavigationEnabled`, `forceActiveFocus` no FindBar | ok | ok |
| Pin | `hideOnWindowDeactivate` | ok | ok |
| HiDPI | SVG + `Kirigami.Units`; `QT_SCALE_FACTOR` testado em 1.25 na rodada anterior | ok | — |

Nada usa `xrandr`, `xdotool`, `wmctrl`, `xprop`. Nenhuma solução exclusiva de X11.

## Riscos específicos
- Wayland: a janela de fullscreen ativa e o popup perde foco → enquanto `fullScreen` for true,
  `hideOnWindowDeactivate` é forçado a `false` e o Loader não é destruído.
- X11: não disponível nesta sessão; itens ficam NÃO TESTADO em 12/14.
