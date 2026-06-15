#!/usr/bin/env sh
set -eu

THEME_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PKG_NAME="luci-theme-argon"
NPM_CACHE="${THEME_DIR}/.npm-cache"

log() {
	printf '%s\n' "$*"
}

cleanup() {
	rm -rf "$NPM_CACHE"
}
trap cleanup EXIT INT TERM

compile_less() {
	log "==> Compiling LESS assets"
	cd "$THEME_DIR"
	mkdir -p htdocs/luci-static/argon/css
	npm_config_cache="$NPM_CACHE" npx --yes less less/cascade.less htdocs/luci-static/argon/css/cascade.css
	npm_config_cache="$NPM_CACHE" npx --yes less less/dark.less htdocs/luci-static/argon/css/dark.css
}

find_buildroot() {
	dir="$THEME_DIR"
	while [ "$dir" != "/" ]; do
		if [ -f "$dir/rules.mk" ] && [ -d "$dir/package" ]; then
			printf '%s\n' "$dir"
			return 0
		fi
		dir="$(dirname "$dir")"
	done
	return 1
}

compile_package() {
	buildroot="$(find_buildroot || true)"
	if [ -z "${buildroot:-}" ]; then
		log "==> OpenWrt buildroot not found; CSS assets compiled only."
		log "    Put this theme under an OpenWrt package directory to build an ipk/apk package."
		return 0
	fi

	log "==> Building OpenWrt package from $buildroot"
	cd "$buildroot"
	make "package/${PKG_NAME}/compile" V=s
	log "==> Package build finished. Check bin/packages/ or bin/targets/ for generated packages."
}

case "${1:-package}" in
	css)
		compile_less
		;;
	package)
		compile_less
		compile_package
		;;
	clean)
		cleanup
		;;
	*)
		echo "Usage: $0 [css|package|clean]" >&2
		exit 2
		;;
esac
