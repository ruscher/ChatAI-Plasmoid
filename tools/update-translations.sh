#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Rafael Ruscher <rruscher@gmail.com>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
#
# Regenerates locale/ChatAI-Plasmoid.pot from the QML/JS sources, merges every
# locale/*.po (existing translations are preserved, new strings stay empty) and
# compiles contents/locale/<lang>/LC_MESSAGES/plasma_applet_ChatAI-Plasmoid.mo.
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

pot="locale/ChatAI-Plasmoid.pot"
mapfile -t sources < <(find contents/ui contents/config -type f \( -name '*.qml' -o -name '*.js' \) | sort)

xgettext --from-code=UTF-8 --language=JavaScript --no-wrap \
    --package-name=ChatAI-Plasmoid --package-version="$(python3 -c 'import json;print(json.load(open("metadata.json"))["KPlugin"]["Version"])')" \
    --msgid-bugs-address=https://github.com/ruscher/ChatAI-Plasmoid/issues \
    -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
    -o "$pot" "${sources[@]}"

# gettext leaves CHARSET as a placeholder; msgmerge needs a real one.
sed -i 's/charset=CHARSET/charset=UTF-8/' "$pot"

for po in locale/*.po; do
    lang="$(basename "$po" .po)"
    msgmerge --quiet --update --backup=none --no-wrap "$po" "$pot"
    mkdir -p "contents/locale/$lang/LC_MESSAGES"
    msgfmt --check-format -o "contents/locale/$lang/LC_MESSAGES/plasma_applet_ChatAI-Plasmoid.mo" "$po"
done

printf 'Template: %s messages\n' "$(grep -c '^msgid ' "$pot")"
