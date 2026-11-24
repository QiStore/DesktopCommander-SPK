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

# No DSM session/account revalidation here. The status page is a read-only
# DSM package UI endpoint; it returns authorization URL/code and no tokens.
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
