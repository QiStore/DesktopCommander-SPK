#!/bin/sh
set -eu
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

respond() {
    printf 'Status: %s\r\nContent-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n\r\n' "$1"
    printf '%s\n' "$2"
    exit 0
}

AUTH_USER="$(/usr/syno/synoman/webman/modules/authenticate.cgi 2>/dev/null | tr -d '\r\n' || true)"
[ -n "$AUTH_USER" ] || respond '401 Unauthorized' '{"error":"请先登录 DSM"}'
# DSM 6 emits group members on the lines following `Group Members:` as
# `0:[admin]`; they are not on the heading line itself.
MEMBERS="$(/usr/syno/sbin/synogroup --get administrators 2>/dev/null | awk 'BEGIN{members=0} /^Group Members:/ {members=1; next} members && match($0, /\[[^]]+\]/) {value=substr($0, RSTART+1, RLENGTH-2); print value}')"
case " $MEMBERS " in *" $AUTH_USER "*) ;; *) respond '403 Forbidden' '{"error":"只有 DSM 管理员可以修改设置"}' ;; esac

case "${REQUEST_METHOD:-GET}" in
  GET) ;;
  POST)
    expected="${HTTP_HOST:-}"
    origin="${HTTP_ORIGIN:-}"
    referer="${HTTP_REFERER:-}"
    case "$origin" in "http://$expected"|"https://$expected") ;; *)
      case "$referer" in "http://$expected/"*|"https://$expected/"*) ;; *) respond '403 Forbidden' '{"error":"请求来源校验失败"}' ;; esac
      ;;
    esac
    length="${CONTENT_LENGTH:-0}"
    case "$length" in ''|*[!0-9]*) respond '400 Bad Request' '{"error":"无效请求长度"}' ;; esac
    [ "$length" -le 65536 ] || respond '413 Payload Too Large' '{"error":"设置数据过大"}'
    ;;
  *) respond '405 Method Not Allowed' '{"error":"不支持的请求方法"}' ;;
esac

SCRIPT_DIR=${0%/*}
[ "$SCRIPT_DIR" != "$0" ] || SCRIPT_DIR=.
SCRIPT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR" && pwd)"
PATH_FILE="$SCRIPT_DIR/auth-state.path"
[ -r "$PATH_FILE" ] || respond '503 Service Unavailable' '{"error":"套件数据目录未初始化"}'
STATE_FILE="$(cat "$PATH_FILE" 2>/dev/null || true)"
case "$STATE_FILE" in /volume[0-9]*/@appdata/DesktopCommander-SPK/auth-state.json) ;; *) respond '503 Service Unavailable' '{"error":"套件数据目录无效"}' ;; esac
PKGVAR="${STATE_FILE%/auth-state.json}"
CONFIG="$PKGVAR/home/.claude-server-commander/config.json"
SHARES="$PKGVAR/shared-directories.json"
AUTOSTART="$PKGVAR/home/.claude-server-commander/autostart"
exec "$SCRIPT_DIR/../runtime/node" "$SCRIPT_DIR/settings.js" "$CONFIG" "$SHARES" "$AUTOSTART" "$PKGVAR/workspace"
