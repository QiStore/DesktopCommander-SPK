#!/bin/sh
set -eu

json_response() {
    status="$1"
    body="$2"
    printf 'Status: %s\r\n' "$status"
    printf 'Content-Type: application/json; charset=utf-8\r\n'
    printf 'Cache-Control: no-store, no-cache, must-revalidate\r\n'
    printf 'X-Content-Type-Options: nosniff\r\n\r\n'
    printf '%s\n' "$body"
    exit 0
}

USER_NAME="$(/usr/syno/synoman/webman/modules/authenticate.cgi 2>/dev/null | tr -d '\r\n' || true)"
[ -n "$USER_NAME" ] || json_response '401 Unauthorized' '{"state":"unauthenticated"}'

printf '%s\n' "$USER_NAME" | grep -Eq '^[A-Za-z0-9_.@-]+$' || json_response '403 Forbidden' '{"state":"forbidden"}'
awk -F: -v user="$USER_NAME" '$1 == "administrators" { n = split($4, members, ","); for (i = 1; i <= n; i++) if (members[i] == user) found = 1 } END { exit !found }' /etc/group \
    || json_response '403 Forbidden' '{"state":"forbidden"}'

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PATH_FILE="$SCRIPT_DIR/auth-state.path"
[ -r "$PATH_FILE" ] || json_response '200 OK' '{"state":"waiting"}'
STATE_FILE="$(cat "$PATH_FILE" 2>/dev/null || true)"
case "$STATE_FILE" in
    /volume[0-9]*/@appdata/DesktopCommander-SPK/auth-state.json) ;;
    *) json_response '200 OK' '{"state":"waiting"}' ;;
esac
[ -r "$STATE_FILE" ] || json_response '200 OK' '{"state":"waiting"}'
BODY="$(cat "$STATE_FILE" 2>/dev/null || true)"
case "$BODY" in
    '{"state":"pending"'*|'{"state":"authorized"'*|'{"state":"failed"'*) json_response '200 OK' "$BODY" ;;
    *) json_response '200 OK' '{"state":"waiting"}' ;;
esac
