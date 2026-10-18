#!/usr/bin/env bash
# Regenerates the shader headers with sokol-shdc: engine/render/shaders/<name>.glsl -> engine/render/src/shaders/
# <name>.glsl.h, and the test materials engine/render/tests/shaders/<name>.glsl -> <name>.glsl.h next to them. The
# generated headers are committed, so normal builds never need this script; run it after editing a .glsl file and
# commit the result.
#
#   tools/shaders/compile_shaders.sh            # all shaders
#   tools/shaders/compile_shaders.sh mesh quad  # only these
#
# Only top files (the ones declaring an @program) are compiled. The others are templates they @include, with paths
# relative to the including file (mesh_common.glsl: the mesh template every mesh program, built-in or a material's,
# is made from; docs/design/CUSTOM_SHADERS.md).
#
# sokol-shdc is taken from $SOKOL_SHDC, else .cache/sokol-tools-bin (fetched with
# git on first use; override the URL with SOKOL_TOOLS_BIN_URL).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/engine/render/shaders"
OUT="$ROOT/engine/render/src/shaders"
TESTS="$ROOT/engine/render/tests/shaders"
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
compiled=0
for input in "$SRC"/*.glsl "$TESTS"/*.glsl; do
    [ -f "$input" ] || continue
    name="$(basename "$input" .glsl)"
    if [ "$#" -gt 0 ] && [[ " $* " != *" $name "* ]]; then continue; fi
    grep -q '^@program' "$input" || continue  # a template, compiled through the files that include it
    if [ "$(dirname "$input")" = "$TESTS" ]; then output="$TESTS/$name.glsl.h"; else output="$OUT/$name.glsl.h"; fi
    echo "shdc: ${input#"$ROOT"/} -> ${output#"$ROOT"/}"
    "$SHDC" --input "$input" --output "$output" --slang "$SLANG" --format sokol --ifdef --no-log-cmdline
    compiled=$((compiled + 1))
done
[ "$compiled" -gt 0 ] || { echo "no shader matches: $*" >&2; exit 1; }
echo "done."
