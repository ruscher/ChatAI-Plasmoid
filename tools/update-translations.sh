#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Rafael Ruscher <rruscher@gmail.com>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
#
# Translation pipeline for ChatAI-Plasmoid.
#
#   contents/ui/**/*.qml, *.js  --xgettext-->  locale/ChatAI-Plasmoid.pot
#                               --msgmerge-->  locale/<lang>.po   (keeps existing translations)
#                               --msgfmt---->  contents/locale/<lang>/LC_MESSAGES/plasma_applet_ChatAI-Plasmoid.mo
#
# The runtime only needs the compiled .mo files under contents/locale/. The
# .pot and .po files are development sources kept in locale/.
#
# The pipeline is idempotent: running it twice without source changes produces
# no diff (the volatile POT-Creation-Date header is dropped on purpose).
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

# gettext tools must read/write UTF-8 regardless of the caller's locale.
export LC_ALL=C.UTF-8

domain="plasma_applet_ChatAI-Plasmoid"
pot="locale/ChatAI-Plasmoid.pot"
version="$(python3 -c 'import json;print(json.load(open("metadata.json"))["KPlugin"]["Version"])')"

mapfile -t sources < <(find contents/ui contents/config -type f \( -name '*.qml' -o -name '*.js' \) | sort)
if (( ${#sources[@]} == 0 )); then
    printf 'No QML/JS sources found\n' >&2
    exit 1
fi

# Extract. --add-comments picks up "// i18n:" translator notes placed above a
# call; KLocalizedString keywords cover i18n / i18nc / i18np / i18ncp.
xgettext --from-code=UTF-8 --language=JavaScript --no-wrap \
    --add-comments=i18n \
    --package-name=ChatAI-Plasmoid --package-version="$version" \
    --msgid-bugs-address=https://github.com/ruscher/ChatAI-Plasmoid/issues \
    -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
    -o "$pot" "${sources[@]}"

# gettext leaves CHARSET as a placeholder; drop the volatile creation date so
# re-runs stay diff-free.
sed -i 's/charset=CHARSET/charset=UTF-8/' "$pot"
sed -i '/^"POT-Creation-Date:/d' "$pot"

fmt_errors=0
for po in locale/*.po; do
    lang="$(basename "$po" .po)"
    msgmerge --quiet --previous --update --backup=none --no-wrap "$po" "$pot"
    mkdir -p "contents/locale/$lang/LC_MESSAGES"
    if ! msgfmt --check-format -o "contents/locale/$lang/LC_MESSAGES/$domain.mo" "$po"; then
        printf 'msgfmt failed for %s\n' "$lang" >&2
        fmt_errors=1
    fi
done

printf 'Template: %s messages, %s languages\n' \
    "$(grep -c '^msgid ' "$pot")" "$(ls locale/*.po | wc -l)"
exit "$fmt_errors"
