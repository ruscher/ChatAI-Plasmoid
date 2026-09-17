#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Rafael Ruscher <rruscher@gmail.com>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
#
# Runs the QML/JS unit tests with qml6 (no Plasma session needed):
#   - Migration.js scenarios (docs/12)
#   - Downloads.js: weighted progress, indicator visibility, speed/ETA
#   - ProviderModel.qml logic, inlined into a wrapper that mocks `plasmoid` and i18n()
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$project_dir"
export QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1
export QT_LOGGING_RULES="*.warning=true;*.critical=true;qml=true;js=true;default=true"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

python3 - "$tmp/provider_test.qml" <<'PY'
import sys
src = open("contents/ui/ProviderModel.qml").read()
body = src[src.index("QtObject {"):].replace("QtObject {\n    id: providerModel", "QtObject {\n    id: pm", 1).rstrip().rstrip("}").rstrip()
checks = open("tools/tests/provider_checks.qml.in").read()
open(sys.argv[1], "w").write("""import QtQuick
Item {
    id: testRoot
    property int failures: 0
    function check(name, cond) { console.log((cond ? "PASS " : "FAIL ") + name); if (!cond) failures++; }
    function i18n(t, a, b) { return String(t).replace("%1", a === undefined ? "%1" : a).replace("%2", b === undefined ? "%2" : b); }
    function i18nc(c, t, a) { return i18n(t, a); }
    function i18np(s, p, n, a) { return i18n(n === 1 ? s : p, n, a); }
    property QtObject plasmoid: QtObject {
        property QtObject configuration: QtObject {
            property string customSitesJson: '[{"name":"My, Site|x","url":"example.org/chat"},{"name":"","url":"https://no"},{"name":"Bad","url":"ftp://no"}]'
            property string customSites: ""
            property string customUserAgent: ""
            property bool compatibilityUserAgent: false
            property bool showChatGPT: true
            property bool showClaude: false
            property bool showGitHubCopilot: true
            property bool hideCustomURL: false
        }
    }
""" + body + "\n    }\n" + checks + "}\n")
PY

status=0
for test in tools/tests/migration_test.qml tools/tests/downloads_test.qml "$tmp/provider_test.qml"; do
    printf '== %s\n' "$(basename "$test")"
    out="$(timeout 60 qml6 "$test" 2>&1 | grep -E 'PASS|FAIL|Error|error' || true)"
    printf '%s\n' "$out"
    if ! grep -q 'ALL PASS' <<<"$out"; then status=1; fi
done
exit $status
