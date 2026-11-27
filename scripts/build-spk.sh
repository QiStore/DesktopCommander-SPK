#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="${OUT_DIR:-$ROOT/build}"
UPSTREAM_DIR="${UPSTREAM_DIR:-$ROOT/vendor/DesktopCommanderMCP}"
NODE_BINARY="${NODE_BINARY:-$(command -v node || true)}"
PACKAGE_VERSION="${PACKAGE_VERSION:-1.0.0-0011}"

[ -n "$NODE_BINARY" ] || { echo "缺少 NODE_BINARY。" >&2; exit 1; }
[ -f "$UPSTREAM_DIR/package.json" ] || { echo "找不到上游源码：$UPSTREAM_DIR" >&2; exit 1; }
PATCH="$ROOT/patches/desktop-commander-security.patch"
[ -f "$PATCH" ] || { echo "缺少必要的安全补丁：$PATCH" >&2; exit 1; }
if git -C "$UPSTREAM_DIR" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
    : # 已应用安全补丁
else
    git -C "$UPSTREAM_DIR" apply "$PATCH"
fi

NODE_VERSION="$("$NODE_BINARY" --version)"
case "$NODE_VERSION" in
    v22.*|v23.*|v24.*|v25.*) ;;
    *) echo "上游当前要求 Node.js >=22.12.0，检测到 $NODE_VERSION。" >&2; exit 1 ;;
esac

rm -rf "$OUT"
mkdir -p "$OUT/root/target/upstream" "$OUT/root/target/runtime" "$OUT/root/var"

# Upstream postinstall sends installation-source telemetry. Skip lifecycle hooks;
# the package is built explicitly below and its scripts are not needed at runtime.
(cd "$UPSTREAM_DIR" && npm ci --ignore-scripts && npm run build && npm prune --omit=dev --ignore-scripts)
cp -a "$UPSTREAM_DIR"/. "$OUT/root/target/upstream/"
rm -rf "$OUT/root/target/upstream/.git" "$OUT/root/target/upstream/node_modules"
cp -a "$UPSTREAM_DIR/node_modules" "$OUT/root/target/upstream/node_modules"
mkdir -p "$OUT/root/target/runtime/bin" "$OUT/root/target/runtime/lib"
cp -L "$NODE_BINARY" "$OUT/root/target/runtime/bin/node"
chmod 755 "$OUT/root/target/runtime/bin/node"

if ldd "$NODE_BINARY" 2>&1 | grep -q 'musl'; then
    LOADER="$(ldd "$NODE_BINARY" 2>/dev/null | sed -n 's/.*=> \([^ ]*ld-musl[^ ]*\).*/\1/p' | head -n 1)"
    [ -n "$LOADER" ] || LOADER="$(find /lib /usr/lib -maxdepth 2 -name 'ld-musl-*.so.1' -print -quit)"
    [ -n "$LOADER" ] || { echo "找不到 musl 动态加载器。" >&2; exit 1; }
    ldd "$NODE_BINARY" 2>/dev/null | sed -n 's/.*=> \(\/[^ ]*\) .*/\1/p; s/^\(\/[^ ]*\) .*/\1/p' | sort -u | while IFS= read -r lib; do
        [ -f "$lib" ] && cp -L "$lib" "$OUT/root/target/runtime/lib/$(basename "$lib")"
    done
    cp -L "$LOADER" "$OUT/root/target/runtime/lib/$(basename "$LOADER")"
    cat > "$OUT/root/target/runtime/node" <<'EOF'
#!/bin/sh
HERE=${0%/*}
[ "$HERE" != "$0" ] || HERE=.
HERE="$(CDPATH= cd -- "$HERE" && pwd)"
LOADER=""
for candidate in "$HERE"/lib/ld-musl-*.so.1; do
    if [ -f "$candidate" ]; then LOADER="$candidate"; break; fi
done
[ -n "$LOADER" ] || { echo "Node runtime loader is missing." >&2; exit 127; }
exec "$LOADER" --library-path "$HERE/lib" "$HERE/bin/node" "$@"
EOF
else
    # Local internal-build fallback. CI uses an Alpine/musl runtime.
    cp "$OUT/root/target/runtime/bin/node" "$OUT/root/target/runtime/node"
fi
chmod 755 "$OUT/root/target/runtime/node"

# Node reports the ELF interpreter (ld-musl) as process.execPath when launched
# through a dynamic loader. Upstream uses process.execPath to spawn its local MCP
# child, so restore the package launcher path before application modules run.
cat > "$OUT/root/target/runtime/exec-path-fix.cjs" <<'EOF'
const launcher = process.env.DC_NODE_LAUNCHER;
if (launcher) process.execPath = launcher;
EOF

cp -a "$ROOT/spk/." "$OUT/root/"
cp "$ROOT/LICENSE" "$OUT/root/target/NOTICE-QiStore-MIT.txt"
cp "$UPSTREAM_DIR/LICENSE" "$OUT/root/target/NOTICE-DesktopCommander-MIT.txt"
cp "$ROOT/vendor/upstream.lock" "$OUT/root/target/UPSTREAM-VERSION.txt"
mkdir -p "$OUT/root/target/ui"
cp "$ROOT/docs/安全设计.md" "$OUT/root/target/ui/安全说明.txt"
cp -a "$ROOT/spk/ui/." "$OUT/root/target/ui/"
chmod 755 "$OUT/root/target/ui/auth.cgi"
mkdir -p "$OUT/root/target/ui/images"
for size in 16 24 32 48 64 72 256; do
    cp "$UPSTREAM_DIR/logo.png" "$OUT/root/target/ui/images/icon_${size}.png"
done

# A test-build package is not a release. Formal release is gated by NAS evidence.
sed -i "s/^version=.*/version=\"$PACKAGE_VERSION\"/" "$OUT/root/INFO"
find "$OUT/root/scripts" -type f -exec chmod 755 {} \;

tar -czf "$OUT/root/package.tgz" -C "$OUT/root/target" .
tar -cf "$OUT/DesktopCommanderSPK-$PACKAGE_VERSION-bromolow.spk" -C "$OUT/root" INFO package.tgz scripts conf

echo "SPK 构建完成（内部候选包，不能据此宣称 NAS 兼容或正式发布）：$OUT/DesktopCommanderSPK-$PACKAGE_VERSION-bromolow.spk"

