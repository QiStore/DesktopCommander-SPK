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
grep -q '^package="DesktopCommander-SPK"grep -Eq '^version="[0-9]+\.[0-9]+\.[0-9]+-[0-9]{4}"$' "$TMP/INFO"
tar -tzf "$TMP/package.tgz" > "$TMP/package.list"
grep -Eq '(^|/)runtime/node$' "$TMP/package.list"
grep -Eq '(^|/)upstream/dist/index.js$' "$TMP/package.list"
grep -Eq '(^|/)upstream/node_modules/@modelcontextprotocol/sdk/' "$TMP/package.list"
sh -n "$TMP/scripts/start-stop-status" "$TMP/scripts/preupgrade" "$TMP/scripts/postupgrade" "$TMP/scripts/postuninst"
echo "SPK 结构、元数据及生命周期脚本语法检查通过。此检查不等同于 DSM 实机安装。"

 "$TMP/INFO"
if grep -Eq '^install_dep_packages="(yes|no)"grep -Eq '^version="[0-9]+\.[0-9]+\.[0-9]+-[0-9]{4}"$' "$TMP/INFO"
tar -tzf "$TMP/package.tgz" > "$TMP/package.list"
grep -Eq '(^|/)runtime/node$' "$TMP/package.list"
grep -Eq '(^|/)upstream/dist/index.js$' "$TMP/package.list"
grep -Eq '(^|/)upstream/node_modules/@modelcontextprotocol/sdk/' "$TMP/package.list"
sh -n "$TMP/scripts/start-stop-status" "$TMP/scripts/preupgrade" "$TMP/scripts/postupgrade" "$TMP/scripts/postuninst"
echo "SPK 结构、元数据及生命周期脚本语法检查通过。此检查不等同于 DSM 实机安装。"

 "$TMP/INFO"; then
    echo 'INFO 的 install_dep_packages 必须列出真实套件名，不能填写 yes/no。' >&2
    exit 1
fi
grep -Eq '^version="[0-9]+\.[0-9]+\.[0-9]+-[0-9]{4}"$' "$TMP/INFO"
tar -tzf "$TMP/package.tgz" > "$TMP/package.list"
grep -Eq '(^|/)runtime/node$' "$TMP/package.list"
grep -Eq '(^|/)upstream/dist/index.js$' "$TMP/package.list"
grep -Eq '(^|/)upstream/node_modules/@modelcontextprotocol/sdk/' "$TMP/package.list"
sh -n "$TMP/scripts/start-stop-status" "$TMP/scripts/preupgrade" "$TMP/scripts/postupgrade" "$TMP/scripts/postuninst"
echo "SPK 结构、元数据及生命周期脚本语法检查通过。此检查不等同于 DSM 实机安装。"

