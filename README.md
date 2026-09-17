# ChatAI-Plasmoid

ChatAI is a KDE Plasma widget that puts web-based AI chat services in a compact, native-looking Plasma interface. It uses Qt WebEngine, so each provider keeps the login and web storage expected by its own website while remaining independent from the widget's documentation and build tooling.

![Screenshot_20250130_204914](https://github.com/user-attachments/assets/0e72709b-3d10-430c-a24e-8a0511c05423)

## Features

- Switch between enabled built-in AI services from the widget header.
- Add custom HTTP or HTTPS providers without changing QML.
- Persistent WebEngine profile for logins, cookies and local storage.
- Navigation controls, page search, PDF/MHTML actions and managed downloads.
- Theme-aware compact icon with favicon, adaptive, outlined, filled, colorful and custom modes.
- Optional web notifications and explicitly configurable geolocation, microphone, webcam and screen sharing permissions.
- Close the expanded view to release the WebEngine instance and its rendering resources.

The widget embeds the providers' public websites. It does not provide an AI API, bypass authentication, or bypass CAPTCHA and anti-bot protections.

## Supported providers

The built-in catalog currently contains T3 Chat, DuckDuckGo Chat, ChatGPT, HuggingChat, Bing Copilot, Google Gemini, BlackBox AI, You, Perplexity, LobeChat, Big-AGI, Claude, DeepSeek, Meta AI and Grok. Availability, login requirements and embedded-browser support are controlled by each provider and can change independently of this project.

New installations enable DuckDuckGo Chat, ChatGPT, HuggingChat, Google Gemini, DeepSeek and T3 Chat. All other built-in providers can be enabled in the widget configuration.

## Requirements and compatibility

The primary compatibility target is KDE Plasma 6.6.6, KDE Frameworks 6.24.0, Qt 6.10.2 and Qt WebEngine 6.10 on both Wayland and X11. Newer Plasma and Qt releases are supported when their APIs remain compatible.

The project is currently developed on Plasma 6.7.4, Qt 6.11.2 and Wayland; see `docs/13-FINAL-VALIDATION.md` for the distinction between tested smoke paths and the target versions that still require a matching environment.

## Installation

Build a package from a checkout:

```bash
./tools/build-package.sh
kpackagetool6 --type Plasma/Applet --install build/ChatAI-Plasmoid.plasmoid
```

You can also install a downloaded `.plasmoid` file using the same `kpackagetool6` command. Add **ChatAI** from Plasma's widget chooser afterwards.

To update an installed copy, use `--upgrade` with the new package. To remove it:

```bash
kpackagetool6 --type Plasma/Applet --remove ChatAI-Plasmoid
```

## Custom providers

Open the widget configuration and add a name plus an `http://` or `https://` URL. Names cannot contain `,` or `|` because existing releases store custom entries in a comma-separated compatibility format. Custom providers are validated before they are added and are not granted special access to the local system.

## Privacy and security

The normal profile persists site cookies, local storage and cache under Qt WebEngine's standard application data locations. The widget does not log cookies, authentication headers or page contents. Invalid TLS certificates are rejected, unknown URL schemes are blocked by default, downloaded file names are sanitized, and downloaded files are never executed automatically.

Notifications follow the widget setting. New installations deny microphone, webcam and screen-sharing permissions until explicitly enabled; geolocation is denied by default. Enabling a permission allows the configured WebEngine profile to grant that feature to a requesting site, subject to Qt WebEngine's origin rules.

## Development and tests

Run the local validation suite:

```bash
./tools/validate.sh
```

The suite validates JSON/XML, runs `qmllint`, builds a `.plasmoid` package and checks that `docs/` and `.git/` do not enter the runtime package. For manual UI smoke tests use `plasmoidviewer -a .`, `plasmawindowed` and a real Plasma session. The full test plan and known environment limits are documented in `docs/10-TEST-PLAN.md` and `docs/13-FINAL-VALIDATION.md`.

## Project structure

- `metadata.json`: Plasma package metadata.
- `contents/config/`: KConfig schema and configuration categories.
- `contents/ui/`: runtime QML, provider catalog, WebEngine handling and assets.
- `contents/locale/`: compiled translations shipped in the package.
- `tools/`: local validation and package build helpers.
- `docs/`: engineering audit and implementation records; not required at runtime.

## Troubleshooting

- If a provider refuses to load, use **Try again** or **Open in browser**; the website may reject embedded WebEngine sessions.
- If a login repeatedly disappears, check that the profile storage name has not changed and that the profile directory is writable.
- If a download fails, select an existing writable folder and review the state shown in the download bar.
- Use the widget configuration to disable providers you do not use and to keep sensitive permissions disabled.

## Contributing, translations and license

Changes should preserve Plasma 6.6/KF6/Qt 6.10 compatibility, avoid new runtime dependencies and include a validation result. Translation sources are in `locale/`; generated `.mo` files used by the package are in `contents/locale/`. Contributions must follow the existing SPDX headers.

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

Colorful ChatGPT icon by [IconScout](https://iconscout.com/)

All other chat icons by [Icons8](https://icons8.com/)
