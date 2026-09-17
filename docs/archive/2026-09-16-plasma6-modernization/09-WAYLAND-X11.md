# 09 — Wayland e X11

## Objetivo

Não depender de ferramentas X11 e manter o mesmo comportamento básico nos dois sistemas.

## Estado atual

O código não chama `xrandr`, `xdotool`, `wmctrl`, `xprop` ou `xwininfo`. Menus, clipboard e file chooser são fornecidos por Qt/KDE/WebEngine. O ambiente desta execução é Wayland (`XDG_SESSION_TYPE=wayland`).

## Solução escolhida

Abrir URLs e arquivos usa `Qt.openUrlExternally`; posicionamento e escala ficam sob Plasma/Qt. Fullscreen web é rejeitado no widget embutido para não depender de hacks de window manager. O layout usa unidades Kirigami e form factor vertical para o ícone.

## Testes / resultado

Wayland: smoke `plasmoidviewer` planar executado sem crash ou warning QML do projeto. X11, painéis superior/inferior/esquerdo/direito, múltiplos monitores, drag-and-drop e escala fracionária: ⚠️ NÃO TESTADO nesta máquina.

## Critério de aceite

Repetir a matriz em uma sessão X11 e conferir popup, foco, clipboard, file chooser e download; não marcar PASS baseado somente no código.
