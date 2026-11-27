#!/bin/sh
set -u
NODE="$1"
APP="$2"
PKGDEST="$3"
PKGVAR="$4"
HOME_DIR="$PKGVAR/home"
CHILD=""
STOPPING=0

terminate() {
    STOPPING=1
    if [ -n "$CHILD" ]; then
        kill -TERM "$CHILD" 2>/dev/null || true
        wait "$CHILD" 2>/dev/null || true
    fi
    exit 0
}
trap terminate TERM INT HUP

delay=2
while [ "$STOPPING" -eq 0 ]; do
    started="$(date +%s 2>/dev/null || echo 0)"
    cd "$PKGDEST/upstream" || exit 1
    env HOME="$HOME_DIR" PATH="$PKGDEST/runtime:$PATH" DC_NODE_LAUNCHER="$NODE" \
        DC_AUTH_STATUS_FILE="$PKGVAR/auth-state.json" \
        NODE_OPTIONS="${NODE_OPTIONS:+$NODE_OPTIONS }--require=$PKGDEST/runtime/exec-path-fix.cjs" \
        DC_REMOTE_DEVICE=true DESKTOP_COMMANDER_DISABLE_TELEMETRY=1 \
        "$NODE" "$APP" remote --disable-no-sleep &
    CHILD=$!
    rc=0
    wait "$CHILD" || rc=$?
    CHILD=""
    [ "$STOPPING" -eq 0 ] || break
    ended="$(date +%s 2>/dev/null || echo 0)"
    uptime=$((ended - started))
    echo "Desktop Commander remote agent exited (code $rc); restart in ${delay}s."
    if [ "$uptime" -ge 300 ]; then delay=2; fi
    sleep "$delay" &
    CHILD=$!
    wait "$CHILD" 2>/dev/null || true
    CHILD=""
    [ "$STOPPING" -eq 0 ] || break
    if [ "$uptime" -lt 300 ] && [ "$delay" -lt 60 ]; then delay=$((delay * 2)); [ "$delay" -le 60 ] || delay=60; fi
done
exit 0
