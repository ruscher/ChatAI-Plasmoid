# ChatAI-Plasmoid

**ChatAI 1.0.1** is a KDE Plasma 6 widget that puts the web apps of AI assistants — ChatGPT, Claude, Gemini, DeepSeek, Copilot, Mistral Vibe, Grok, Qwen, Kimi, Manus and others — in a compact, native Plasma popup. It embeds each service's official website with Qt WebEngine, keeps a persistent profile for logins, and frees the web engine when you close it.

![Screenshot_20250130_204914](https://github.com/user-attachments/assets/0e72709b-3d10-430c-a24e-8a0511c05423)

The widget does not provide an AI API, does not bypass authentication and does not bypass CAPTCHA or anti-bot protections.

## Features

- **Toolbar**: Pin · Back · Forward · Reload/Stop · Home · **assistant selector** (icon + name) · Find · ⋮ menu · Close. Back/Forward follow the page history; narrow popups move Home and Find into the ⋮ menu. A **download indicator** with a progress ring appears only while a download is running or finished but not yet opened.
- **⋮ menu**: open in browser, copy address, reload ignoring cache, zoom (50–200 %), real full screen (F11, also honours page requests), **hide toolbar automatically**, **Downloads** (list with pause/resume/cancel, open, show in folder, retry), ChatAI settings by category, keyboard shortcuts, about, optional developer tools.
- **Settings inside the widget** and in the Plasma configuration dialog, sharing one backend: General, Sites, Permissions, Web Features, Downloads, Cache and Data, Appearance, Advanced, About.
- **Per-site permissions**: notifications, microphone, camera, screen sharing, location and clipboard are *Ask / Allow / Block* per type; "Ask" shows an inline prompt and the answer is remembered per site (Qt WebEngine `StoreOnDisk`), reviewable and resettable.
- **Resource-conscious**: the web engine is created on first use and destroyed by Close; a hidden page is frozen after 30 s when the engine says it is safe; optional discard after N minutes.
- **Providers registry**: one file (`contents/ui/ProviderModel.qml`) defines every assistant; custom sites are stored as JSON.
- Persistent WebEngine profile per widget instance (storage name), HTTP cache limit and one-click cache clearing.
- Theme-aware panel icon: favicon, ChatAI logo (adaptive/dark/light), assistant icon (outlined/filled/colorful) or any system icon.
- **Sign-in popups** ("Continue with Google" and similar `window.open` flows) open in an in-widget window that shares the profile, so callbacks, `window.opener` and `window.close()` work; redirect-based logins run in the main view.
- Managed downloads (progress, speed, pause, resume, cancel, open, show in folder, retry, KDE notification with actions), PDF and MHTML export, find in page, dark-mode hint for pages.

## Providers

Enabled by default on new installations: ChatGPT, Claude, Google Gemini, DeepSeek, Duck.ai, HuggingChat and T3 Chat.
Also available: Perplexity, Microsoft Copilot, **GitHub Copilot**, **Mistral Vibe**, Grok, **Qwen**, **Kimi**, **Manus**, Meta AI, You.com, BlackBox AI, LobeChat, Big-AGI, plus any custom site.

Availability, login methods and features are decided by each service. "Continue with Google" works with the default browser identity (popups open in an in-widget sign-in window; redirect flows stay in the main view). The research behind the list, with load tests, is in [`docs/05-AI-PROVIDERS-RESEARCH.md`](docs/05-AI-PROVIDERS-RESEARCH.md).

## Requirements

KDE Plasma 6.6 or newer, KDE Frameworks 6, Qt 6.10 or newer with **Qt WebEngine** (`qt6-webengine`). Developed and tested on Plasma 6.7.4 / Qt 6.11.2 on Wayland; X11 is supported by the same code paths (see [`docs/11-WAYLAND-X11-HIDPI.md`](docs/11-WAYLAND-X11-HIDPI.md)).

## Install, update, remove

```bash
./tools/build-package.sh                                   # → build/ChatAI-Plasmoid.plasmoid
kpackagetool6 --type Plasma/Applet --install build/ChatAI-Plasmoid.plasmoid
kpackagetool6 --type Plasma/Applet --upgrade build/ChatAI-Plasmoid.plasmoid   # update
kpackagetool6 --type Plasma/Applet --remove ChatAI-Plasmoid                   # uninstall
```

Then add **ChatAI** from Plasma's widget chooser. Upgrading from 1.0.0 keeps your settings: the first start migrates them (pin, custom sites, permissions, provider URLs) automatically.

## Using ChatAI

| Action | How |
| --- | --- |
| Switch assistant | Selector in the toolbar (keyboard: Tab to it, arrows, Enter) |
| Custom address | "Custom address…" in the selector, or add a site in Settings › Sites |
| Find in page | Ctrl+F |
| Zoom | ⋮ › Zoom, or Ctrl++ / Ctrl+- / Ctrl+0 |
| Full screen | ⋮ › Full Screen or F11; Esc exits |
| Keep open when clicking outside | Pin button |
| Hide the toolbar | ⋮ › Hide Toolbar Automatically, or Settings › General |
| Downloads | Click the ↓ indicator while it is shown, or ⋮ › Downloads |
| Free memory | Close button (destroys the web engine; logins are kept on disk) |

## Settings

- **General** – home assistant, pin, preload at login, toolbar visibility.
- **Sites** – enable built-in assistants (with login notes), add/edit/remove custom sites.
- **Permissions** – Ask/Allow/Block per type; list and reset decisions saved per site.
- **Web Features** – clipboard, new windows, autoplay, spatial navigation, focus, unknown link types (each explained).
- **Downloads** – folder, open folder, current downloads (the list itself is in ⋮ › Downloads or behind the toolbar indicator).
- **Cache and Data** – cache location and limit, clear cache, profile storage name (switching recreates the view; confirmation required).
- **Appearance** – panel icon, toolbar buttons.
- **Advanced** – browser identity (Chromium-compatible user agent), custom user agent, freeze/discard hidden page, developer tools, diagnostics.

## Privacy and security

- Site data (cookies, logins, storage, cache, permissions) lives in the WebEngine profile folder: `~/.local/share/plasmashell/QtWebEngine/<storage name>` and `~/.cache/plasmashell/QtWebEngine/<storage name>`.
- Microphone, camera, screen and location are used only after you allow them, and only by the site that asked. Unknown permission types are denied.
- Only `http(s)` links navigate or open externally; unknown URL schemes are blocked unless you enable them, and then only after a click. Invalid TLS certificates are rejected. Downloaded file names are sanitized and files are never executed.
- ChatAI does not read page contents, credentials or clipboard. Clearing the cache does not sign you out; to end a session use the site's "Sign out" or switch the profile storage name.

## Troubleshooting

- A site refuses to load or to sign in: try **Advanced › Identify as Chromium**, then **Open in Browser** from the ⋮ menu.
- Google sign-in says "This browser or app may not be secure": make sure Advanced › *Identify as Chromium* is **off** (Google accepts Qt WebEngine's real identity and rejects disguised ones).
- Notifications do not appear: set Permissions › Notifications to *Ask* or *Allow* and check Plasma's notification settings.
- Downloads fail: choose an existing, writable folder in Settings › Downloads.
- Something looks wrong after an update: Advanced › Diagnostics has a **Copy** button; paste it in an issue.

## Development

```bash
./tools/validate.sh              # JSON, XML, qmllint, .po check, package contents
./tools/update-translations.sh   # regenerate .pot, merge .po, compile .mo
plasmoidviewer -a .              # run the widget in a window
python3 tools/provider-probe/probe.py default   # headless load test of every provider (PySide6)
```

Engineering documentation lives in [`docs/`](docs/) (plan, audits, decisions, test matrix, final audit). Translation sources are in `locale/`; compiled catalogs shipped in the package are in `contents/locale/`. Keep SPDX headers and avoid new runtime dependencies.

## Contributors
<!-- readme: contributors -start -->
<table>
	<tbody>
		<tr>
            <td align="center">
                <a href="https://github.com/DenysMb">
                    <img src="https://avatars.githubusercontent.com/u/33737137?v=4" width="100;" alt="DenysMb"/>
                    <br />
                    <sub><b>Denys Madureira</b></sub>
                </a>
            </td>
            <td align="center">
                <a href="https://github.com/bigbruno">
                    <img src="https://avatars.githubusercontent.com/u/6098501?v=4" width="100;" alt="bigbruno"/>
                    <br />
                    <sub><b>Bruno Gonçalves</b></sub>
                </a>
            </td>
            <td align="center">
                <a href="https://github.com/JulWas797">
                    <img src="https://avatars.githubusercontent.com/u/51297298?v=4" width="100;" alt="JulWas797"/>
                    <br />
                    <sub><b>J797</b></sub>
                </a>
            </td>
            <td align="center">
                <a href="https://github.com/meowarex">
                    <img src="https://avatars.githubusercontent.com/u/90243579?v=4" width="100;" alt="meowarex"/>
                    <br />
                    <sub><b>Meow Meow</b></sub>
                </a>
            </td>
            <td align="center">
                <a href="https://github.com/vitor-dantas">
                    <img src="https://avatars.githubusercontent.com/u/45504386?v=4" width="100;" alt="vitor-dantas"/>
                    <br />
                    <sub><b>Vitor Dantas</b></sub>
                </a>
            </td>
            <td align="center">
                <a href="https://github.com/postadelmaga">
                    <img src="https://avatars.githubusercontent.com/u/2010800?v=4" width="100;" alt="postadelmaga"/>
                    <br />
                    <sub><b>postadelmaga</b></sub>
                </a>
            </td>
		</tr>
	<tbody>
</table>
<!-- readme: contributors -end -->

Maintainer of this fork: Rafael Ruscher <rruscher@gmail.com>.

## License and assets

Code: GPL-2.0-or-later (see `LICENSE`). Colorful ChatGPT icon by [IconScout](https://iconscout.com/); other original chat icons by [Icons8](https://icons8.com/). GitHub Copilot, Qwen, Kimi, Mistral and Meta icons from [Simple Icons](https://simpleicons.org/) (CC0 1.0); the Manus icon is the service's own SVG icon. All trademarks belong to their respective owners and are used only to identify the services.
