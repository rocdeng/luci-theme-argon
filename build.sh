#!/usr/bin/env bash
# Build script for luci-theme-argon
# Compiles LESS sources → htdocs/luci-static/argon/css/
# Usage:
#   ./build.sh           # compile only
#   ./build.sh deploy    # compile + scp to router (set ROUTER=user@host)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/less"
OUT_DIR="$SCRIPT_DIR/htdocs/luci-static/argon/css"
UT_SRC_DIR="$SCRIPT_DIR/ucode/template/themes/argon"

LESSC="${LESSC:-lessc}"
ROUTER="${ROUTER:-root@192.168.1.1}"
ROUTER_WWW="/www/luci-static"
ROUTER_TPL="/usr/share/ucode/luci/template/themes/argon"

# ---- verify toolchain ----
if ! command -v "$LESSC" >/dev/null 2>&1; then
  echo "error: lessc not found. Install with: npm i -g less" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "==> Compiling cascade.less"
"$LESSC" "$SRC_DIR/cascade.less" "$OUT_DIR/cascade.css"
echo "    cascade.css: $(wc -l < "$OUT_DIR/cascade.css") lines"

echo "==> Compiling dark.less"
"$LESSC" "$SRC_DIR/dark.less" "$OUT_DIR/dark.css"
echo "    dark.css:    $(wc -l < "$OUT_DIR/dark.css") lines"

if [ "${1:-}" = "deploy" ]; then
  echo "==> Deploying to ${ROUTER}"
  # ucode templates
  echo "    uploading ucode templates → ${ROUTER_TPL}"
  ssh "${ROUTER}" "mkdir -p ${ROUTER_TPL}"
  scp "$UT_SRC_DIR"/*.ut "${ROUTER}:${ROUTER_TPL}/"
  # CSS (and other static assets)
  echo "    uploading static assets → ${ROUTER_WWW}/argon"
  scp -r "$SCRIPT_DIR/htdocs/luci-static/argon/"* "${ROUTER}:${ROUTER_WWW}/argon/"
  # restart uhttpd to clear template cache
  echo "    restarting uhttpd"
  ssh "${ROUTER}" "/etc/init.d/uhttpd restart"
  echo "==> Deployed ✓"
else
  echo "==> Built. Run '$0 deploy' (or ROUTER=root@IP $0 deploy) to sync to router."
fi

echo "==> Done."
