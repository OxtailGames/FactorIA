#!/usr/bin/env bash
# Regenerates engine/render/src/shaders/*.glsl.h from engine/render/shaders/*.glsl
# with sokol-shdc. The generated headers are committed, so normal builds never
# need this script; run it after editing a .glsl file and commit the result.
#
#   tools/shaders/compile_shaders.sh            # all shaders
#   tools/shaders/compile_shaders.sh mesh quad  # only these
#
# sokol-shdc is taken from $SOKOL_SHDC, else .cache/sokol-tools-bin (fetched with
# git on first use; override the URL with SOKOL_TOOLS_BIN_URL).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/engine/render/shaders"
OUT="$ROOT/engine/render/src/shaders"
SLANG="glsl430:glsl300es:metal_macos:metal_ios:metal_sim:hlsl5:wgsl"

host_dir() {
    local os arch
    os="$(uname -s)"; arch="$(uname -m)"
    case "$os" in
        Linux)  echo "linux" ;;
        Darwin) if [ "$arch" = "arm64" ]; then echo "osx_arm64"; else echo "osx"; fi ;;
        MINGW*|MSYS*|CYGWIN*) echo "win32" ;;
        *) echo "unsupported OS $os" >&2; exit 1 ;;
    esac
}

SHDC="${SOKOL_SHDC:-}"
if [ -z "$SHDC" ]; then
    BIN_ROOT="$ROOT/.cache/sokol-tools-bin"
    EXE="sokol-shdc"
    [ "$(host_dir)" = "win32" ] && EXE="sokol-shdc.exe"
    SHDC="$BIN_ROOT/bin/$(host_dir)/$EXE"
    if [ ! -x "$SHDC" ]; then
        echo "sokol-shdc not found at $SHDC; fetching sokol-tools-bin..." >&2
        mkdir -p "$ROOT/.cache"
        git clone --depth 1 "${SOKOL_TOOLS_BIN_URL:-https://github.com/floooh/sokol-tools-bin}" "$BIN_ROOT"
        chmod +x "$SHDC" 2>/dev/null || true
    fi
fi

mkdir -p "$OUT"
if [ "$#" -gt 0 ]; then names=("$@"); else names=($(cd "$SRC" && ls *.glsl | sed 's/\.glsl$//')); fi

for name in "${names[@]}"; do
    echo "shdc: $name.glsl -> src/shaders/$name.glsl.h"
    "$SHDC" --input "$SRC/$name.glsl" --output "$OUT/$name.glsl.h" --slang "$SLANG" \
        --format sokol --ifdef --no-log-cmdline
done
echo "done."
