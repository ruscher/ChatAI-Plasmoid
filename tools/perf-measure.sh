#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Rafael Ruscher <rruscher@gmail.com>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
#
# Isolated performance measurement for ChatAI-Plasmoid.
#
# Runs the plasmoid on its own via `plasmawindowed`, so its footprint is measured
# separately from plasmashell. Reports PSS (proportional set size, the honest
# per-process memory metric) for the host and every Qt WebEngine child, the total
# footprint, the child process count and an idle CPU sample.
#
# Must be run inside a live Plasma session (it reads the session env from the
# running plasmashell). Development tool only; not shipped in the .plasmoid.
#
# Usage: tools/perf-measure.sh [settle_seconds]   (default 10)
set -uo pipefail
SETTLE="${1:-10}"
APPLET="ChatAI-Plasmoid"

pid_plasma="$(pgrep -x -u "$(id -u)" plasmashell | head -1)"
if [ -n "$pid_plasma" ]; then
    while IFS= read -r -d '' p; do
        case "${p%%=*}" in DISPLAY|WAYLAND_DISPLAY|XDG_RUNTIME_DIR|DBUS_SESSION_BUS_ADDRESS|XAUTHORITY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE) export "$p";; esac
    done < "/proc/$pid_plasma/environ"
fi

pss_kb() { grep -m1 '^Pss:' "/proc/$1/smaps_rollup" 2>/dev/null | awk '{print $2+0}'; }
rss_kb() { awk '{print $2*4}' "/proc/$1/statm" 2>/dev/null; }
descendants() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do echo "$c"; descendants "$c"; done; }
sum_pss() { local t=0 p v; for p in "$@"; do v=$(pss_kb "$p"); t=$((t+${v:-0})); done; awk -v t=$t 'BEGIN{printf "%.1f", t/1024}'; }
proctype() {
    local c; c=$(tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null)
    if echo "$c" | grep -q QtWebEngineProcess; then
        echo "$c" | grep -oE -- '--type=[a-z-]+' | head -1 | sed 's/--type=//' || echo browser
    else
        basename "$(echo "$c" | awk '{print $1}')" 2>/dev/null
    fi
}

echo "=== session: ${XDG_SESSION_TYPE:-?} / ${WAYLAND_DISPLAY:-x11} ==="
setsid plasmawindowed "$APPLET" >/tmp/chatai-perf.log 2>&1 &
sleep "$SETTLE"
PWPID="$(pgrep -x -u "$(id -u)" plasmawindowed | head -1)"
[ -z "$PWPID" ] && { echo "FAIL: plasmawindowed did not start"; cat /tmp/chatai-perf.log; exit 1; }

mapfile -t KIDS < <(descendants "$PWPID")
ALL=("$PWPID" "${KIDS[@]}")
echo "plasmawindowed PID=$PWPID  descendants=${#KIDS[@]}  total_procs=${#ALL[@]}"
echo "--- per process (PSS / RSS) ---"
for p in "${ALL[@]}"; do
    [ -r "/proc/$p/statm" ] || continue
    printf "  pid %-7s %-22s PSS=%6.1f MB  RSS=%6.1f MB\n" "$p" "$(proctype "$p")" \
        "$(awk -v k="$(pss_kb "$p")" 'BEGIN{print k/1024}')" \
        "$(awk -v k="$(rss_kb "$p")" 'BEGIN{print k/1024}')"
done
echo "=== TOTAL ChatAI (isolated): PSS=$(sum_pss "${ALL[@]}") MB  procs=${#ALL[@]} ==="
webcount=0; for p in "${KIDS[@]}"; do tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null | grep -q QtWebEngineProcess && webcount=$((webcount+1)); done
echo "=== QtWebEngineProcess children: $webcount ==="

echo "--- idle CPU over 4s (sum of tree) ---"
pidstat -p "$(IFS=,; echo "${ALL[*]}")" 4 1 2>/dev/null | awk '/Average/&&/[0-9]/{s+=$8} END{printf "  sum %%CPU = %.2f\n", s}'

kill "$PWPID" 2>/dev/null; sleep 2
# clean up any WebEngine child orphaned by the abrupt kill (host-less)
for p in $(pgrep -f QtWebEngineProcess 2>/dev/null); do
    pp=$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null)
    [ "$pp" = "1" ] && kill "$p" 2>/dev/null
done
echo "=== done ==="
