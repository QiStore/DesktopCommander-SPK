#!/bin/sh
set -eu

SPK="${1:?用法: check-spk.sh 文件.spk}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

tar -tf "$SPK" > "$TMP/outer.list"
for required in INFO package.tgz scripts/start-stop-status scripts/preupgrade scripts/postupgrade scripts/postuninst conf/privilege; do
    grep -Fxq "$required" "$TMP/outer.list" || { echo "SPK 缺少 $required" >&2; exit 1; }
done
tar -xf "$SPK" -C "$TMP"
grep -q '^package="DesktopCommander-SPK"$' "$TMP/INFO"
if grep -Eq '^install_dep_packages="(yes|no)"$' "$TMP/INFO"; then
    echo 'INFO 的 install_dep_packages 必须列出真实套件名，不能填写 yes/no。' >&2
    exit 1
fi
grep -Eq '^version="[0-9]+\.[0-9]+\.[0-9]+-[0-9]{4}"$' "$TMP/INFO"
tar -tzf "$TMP/package.tgz" > "$TMP/package.list"
grep -Eq '(^|/)runtime/node$' "$TMP/package.list"
grep -Eq '(^|/)upstream/dist/index.js$' "$TMP/package.list"
grep -Eq '(^|/)upstream/node_modules/@modelcontextprotocol/sdk/' "$TMP/package.list"
grep -Eq '(^|/)runtime/exec-path-fix\.cjs$' "$TMP/package.list"
grep -Eq '(^|/)ui/config$' "$TMP/package.list"
grep -Eq '(^|/)ui/index\.html$' "$TMP/package.list"
grep -Eq '(^|/)ui/auth\.cgi$' "$TMP/package.list"
mkdir -p "$TMP/package"
tar -xzf "$TMP/package.tgz" -C "$TMP/package"
sh -n "$TMP/scripts/start-stop-status" "$TMP/scripts/preupgrade" "$TMP/scripts/postupgrade" "$TMP/scripts/postuninst"
sh -n "$TMP/package/ui/auth.cgi"
grep -q '^unset LD_PRELOAD LD_LIBRARY_PATH$' "$TMP/package/runtime/node" || { echo "Node 启动器未清除 DSM 注入的宿主加载器变量。" >&2; exit 1; }
echo "SPK 结构、元数据及生命周期脚本语法检查通过。此检查不等同于 DSM 实机安装。"
