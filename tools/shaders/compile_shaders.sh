#!/usr/bin/env bash
# Regenerates the shader headers with sokol-shdc: engine/render/shaders/<name>.glsl -> engine/render/src/shaders/
# <name>.glsl.h. The generated headers are committed, so normal builds never need this script; run it after editing a
# .glsl file and commit the result. (Custom material test fixtures are compiled by the tooling: FA_UPDATE_FIXTURES=1.)
#
#   tools/shaders/compile_shaders.sh            # all shaders
#   tools/shaders/compile_shaders.sh mesh quad  # only these
#
# Only top files (the ones declaring an @program) are compiled. The others are templates they @include, with paths
# relative to the including file (mesh_common.glsl: the mesh template every mesh program, built-in or a material's,
# is made from; docs/design/CUSTOM_SHADERS.md).
#
# sokol-shdc is taken from $SOKOL_SHDC, else from the pinned commit of github.com/floooh/sokol-tools-bin kept in
# ${FACTORIA_HOME:-$HOME/.factoria}/tools/sokol-shdc/<commit>/ (the folder `factoria setup shaders` installs into: fetched
# on first use, the one file for this computer, and refused unless its SHA-256 matches). The commit and the hashes are the
# ones of tools/common/include/fa/tooling/setup.h (a test keeps them equal); the generated code must match
# external/sokol/sokol_gfx.h, so a sokol update moves the pin, the committed headers and that header together.
set -euo pipefail

SHDC_COMMIT=b975d5642093d62e76a1e088bdae945d6d8b8ff2
SHDC_SHA256_win32=43d42c2e477bcc5012420f8d9ff641fedc41d552d165397fff4f2e60ba0d2ebb
SHDC_SHA256_linux=f227db5b282dcaa8085796ba83cda217d3114cf34913ca6ba4b0103f25ccc779
SHDC_SHA256_linux_arm64=c31155b7d340cd561b6fac8d8580c2377abd9140b25d7403c085cb1e700cea14
SHDC_SHA256_osx=67e5c841a4ca58488e6592560dd8795c7b232a8805d2350ca346028541716252
SHDC_SHA256_osx_arm64=2a807d62dffcc67a50a6ab51df57cde2fc8b23a3daf6207177d79e00fbd4086b

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/engine/render/shaders"
OUT="$ROOT/engine/render/src/shaders"
SLANG="glsl430:glsl300es:metal_macos:metal_ios:metal_sim:hlsl5:wgsl"

host_dir() {
    local os arch
    os="$(uname -s)"; arch="$(uname -m)"
    case "$os" in
        Linux)  if [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ]; then echo "linux_arm64"; else echo "linux"; fi ;;
        Darwin) if [ "$arch" = "arm64" ]; then echo "osx_arm64"; else echo "osx"; fi ;;
        MINGW*|MSYS*|CYGWIN*) echo "win32" ;;
        *) echo "unsupported OS $os" >&2; exit 1 ;;
    esac
}

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

SHDC="${SOKOL_SHDC:-}"
if [ -z "$SHDC" ]; then
    DIR="$(host_dir)"
    EXE="sokol-shdc"
    [ "$DIR" = "win32" ] && EXE="sokol-shdc.exe"
    SHDC="${FACTORIA_HOME:-$HOME/.factoria}/tools/sokol-shdc/$SHDC_COMMIT/$EXE"
    if [ ! -x "$SHDC" ]; then
        URL="https://raw.githubusercontent.com/floooh/sokol-tools-bin/$SHDC_COMMIT/bin/$DIR/$EXE"
        echo "sokol-shdc not found at $SHDC; fetching $URL ..." >&2
        mkdir -p "$(dirname "$SHDC")"
        curl -fL --retry 3 -o "$SHDC.part" "$URL"
        want="SHDC_SHA256_$DIR"
        if [ "$(sha256_of "$SHDC.part")" != "${!want}" ]; then
            rm -f "$SHDC.part"
            echo "the downloaded sokol-shdc is not the pinned file (SHA-256 mismatch); nothing was installed." >&2
            echo "Download it again, or set SOKOL_SHDC to a sokol-shdc you trust." >&2
            exit 1
        fi
        chmod +x "$SHDC.part"
        mv "$SHDC.part" "$SHDC"
    fi
fi

mkdir -p "$OUT"
compiled=0
for input in "$SRC"/*.glsl; do
    [ -f "$input" ] || continue
    name="$(basename "$input" .glsl)"
    if [ "$#" -gt 0 ] && [[ " $* " != *" $name "* ]]; then continue; fi
    grep -q '^@program' "$input" || continue  # a template, compiled through the files that include it
    output="$OUT/$name.glsl.h"
    echo "shdc: ${input#"$ROOT"/} -> ${output#"$ROOT"/}"
    "$SHDC" --input "$input" --output "$output" --slang "$SLANG" --format sokol --ifdef --no-log-cmdline
    compiled=$((compiled + 1))
done
[ "$compiled" -gt 0 ] || { echo "no shader matches: $*" >&2; exit 1; }
echo "done."
