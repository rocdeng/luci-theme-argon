#!/usr/bin/env bash
# Build script for luci-theme-argon
# Compiles LESS sources → htdocs/luci-static/argon/css/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/less"
OUT_DIR="$SCRIPT_DIR/htdocs/luci-static/argon/css"

LESSC="${LESSC:-lessc}"

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

echo "==> Done."
