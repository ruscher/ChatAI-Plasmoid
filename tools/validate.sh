#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

python3 -m json.tool metadata.json >/dev/null
xmllint --noout contents/config/main.xml

mapfile -t qml_files < <(find contents/ui contents/config -type f -name '*.qml' -print | sort)
mapfile -t po_files < <(find locale -type f -name '*.po' -print | sort)
for po_file in "${po_files[@]}"; do
    msgfmt --check-format -o /dev/null "$po_file"
done
if (( ${#qml_files[@]} == 0 )); then
    printf '%s\n' 'No QML files found' >&2
    exit 1
fi
qmllint "${qml_files[@]}"

package_path="$(mktemp --suffix=.plasmoid)"
trap 'rm -f "$package_path"' EXIT
tools/build-package.sh "$package_path" >/dev/null
unzip -tq "$package_path"
if unzip -l "$package_path" | grep -E '(^|/)docs/|(^|/)\.git/' >/dev/null; then
    printf '%s\n' 'Runtime package contains development-only files' >&2
    exit 1
fi

printf '%s\n' 'ChatAI-Plasmoid validation passed.'
