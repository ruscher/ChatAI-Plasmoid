#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_path="${1:-${project_dir}/build/ChatAI-Plasmoid.plasmoid}"
output_dir="$(dirname "$output_path")"

required_files=(metadata.json contents/ui/main.qml contents/config/config.qml contents/config/main.xml)
for required_file in "${required_files[@]}"; do
    if [[ ! -f "${project_dir}/${required_file}" ]]; then
        printf 'Missing required package file: %s\n' "$required_file" >&2
        exit 1
    fi
done

mkdir -p "$output_dir"
rm -f "$output_path"
(cd "$project_dir" && zip -q -r "$output_path" metadata.json contents LICENSE)

printf '%s\n' "$output_path"
