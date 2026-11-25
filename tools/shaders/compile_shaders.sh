#!/usr/bin/env bash
# Regenerates the shader headers with sokol-shdc: engine/render/shaders/<name>.glsl -> engine/render/src/shaders/
# <name>.glsl.h. The generated headers are committed, so normal builds never need this script; run it after editing a
# .glsl file and commit the result. (Custom material test fixtures are compiled by the tooling: FA_UPDATE_FIXTURES=1.)
#
#   tools/shaders/compile_shaders.sh            # all shaders
#   tools/shaders/compile_shaders.sh mesh quad  # only these
#
# A top file that needs defines names them in a `// shdc-defines: A:B` comment (sokol-shdc --defines), and one that only some
# backends run names its dialects in `// shdc-slang: glsl430:metal_macos:...` (the default is the SLANG list below).
# Only top files (the ones declaring an @program) are compiled. The others are templates they @include, with paths
# relative to the including file (mesh_common.glsl: the mesh template every mesh program, built-in or a material's,
# is made from; docs/design/CUSTOM_SHADERS.md).
#
# The generated headers are then rewritten by tools/shaders/shader_pack (built here, with the engine's own zstd encoder: a
# C++20 compiler and cmake, nothing else): the GLSL ES 3.00 and GLSL 4.30 texts of a header become one zstd frame per dialect, which
# the renderer decodes on first use (engine/render/src/shader_text.h; the web, Android and Linux players carry about 0.8 MB less each). The same
# step writes engine/render/tests/shader_text_index.h, the list of the packed headers the render tests walk.
#
# sokol-shdc is taken from $SOKOL_SHDC, else from the pinned commit of github.com/floooh/sokol-tools-bin kept in
# ${FACTORIA_HOME:-$HOME/.factoria}/tools/sokol-shdc/<commit>/ (the folder `factoria setup shaders` installs into: fetched
# on first use, the one file for this computer, and refused unless its SHA-256 matches). The commit and the hashes are the
# ones of tools/common/include/fa/tooling/setup.h (a test keeps them equal); the generated code must match
# external/sokol/sokol_gfx.h, so a sokol update moves the pin, the committed headers and that header together.
set -euo pipefail
# Glob order (and so the order of the generated index) must not depend on the locale.
export LC_ALL=C

SHDC_COMMIT=b975d5642093d62e76a1e088bdae945d6d8b8ff2
SHDC_SHA256_win32=43d42c2e477bcc5012420f8d9ff641fedc41d552d165397fff4f2e60ba0d2ebb
SHDC_SHA256_linux=f227db5b282dcaa8085796ba83cda217d3114cf34913ca6ba4b0103f25ccc779
SHDC_SHA256_linux_arm64=c31155b7d340cd561b6fac8d8580c2377abd9140b25d7403c085cb1e700cea14
SHDC_SHA256_osx=67e5c841a4ca58488e6592560dd8795c7b232a8805d2350ca346028541716252
SHDC_SHA256_osx_arm64=2a807d62dffcc67a50a6ab51df57cde2fc8b23a3daf6207177d79e00fbd4086b

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/engine/render/shaders"
OUT="$ROOT/engine/render/src/shaders"
SLANG="glsl430:glsl300es:metal_macos:metal_ios:metal_sim:hlsl5:wgsl:spirv_vk"

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

# The packer: its own small cmake project (it compiles the codec files of engine/core and nothing else), built under .cache.
PACK_DIR="$ROOT/.cache/shader-pack"
build_packer() {
    local gen=()
    command -v ninja >/dev/null 2>&1 && gen=(-G Ninja)
    local log="$PACK_DIR.log"
    mkdir -p "$(dirname "$PACK_DIR")"
    if ! { cmake -S "$ROOT/tools/shaders/shader_pack" -B "$PACK_DIR" ${gen[@]+"${gen[@]}"} -DCMAKE_BUILD_TYPE=Release &&
           cmake --build "$PACK_DIR" --config Release; } >"$log" 2>&1; then
        cat "$log" >&2
        echo "error: building the shader packer failed (log above, also in $log)" >&2
        exit 1
    fi
    for exe in "$PACK_DIR/fa_shader_pack" "$PACK_DIR/Release/fa_shader_pack.exe" "$PACK_DIR/fa_shader_pack.exe"; do
        if [ -x "$exe" ]; then PACK="$exe"; return; fi
    done
    echo "error: the shader packer was not built under $PACK_DIR" >&2
    exit 1
}
build_packer

mkdir -p "$OUT"
compiled=0
# The engine's shaders, then the test shaders of engine/render/tests/shaders (each next to its header; the Vulkan
# backend's tests draw with them, so they are made for spirv_vk only).
for input in "$SRC"/*.glsl "$ROOT"/engine/render/tests/shaders/*.glsl; do
    [ -f "$input" ] || continue
    name="$(basename "$input" .glsl)"
    if [ "$#" -gt 0 ] && [[ " $* " != *" $name "* ]]; then continue; fi
    grep -q '^@program' "$input" || continue  # a template, compiled through the files that include it
    output="$OUT/$name.glsl.h"
    case "$input" in "$ROOT"/engine/render/tests/*) output="${input}.h" ;; esac
    echo "shdc: ${input#"$ROOT"/} -> ${output#"$ROOT"/}"
    # A file that needs preprocessor flags from the command line (terrain.glsl: FA_HAS_VERTEX, FA_INST_2, as a custom material's top
    # file gets them) names them in a comment: `// shdc-defines: A:B`.
    defines="$(sed -n 's|^// shdc-defines: *||p' "$input" | head -n 1 | tr -d '\r')"
    extra=()
    [ -z "$defines" ] || extra=(--defines "$defines")
    # A file that only some backends can run (hiz.glsl: a compute shader, which GLES3 and WebGL2 cannot) names the dialects it is made for:
    # `// shdc-slang: glsl430:metal_macos`. The others have no code in its header, so the web and Android players do not grow.
    slang="$(sed -n 's|^// shdc-slang: *||p' "$input" | head -n 1 | tr -d '\r')"
    "$SHDC" --input "$input" --output "$output" --slang "${slang:-$SLANG}" --format sokol --ifdef --no-log-cmdline ${extra[@]+"${extra[@]}"}
    # sokol-shdc keeps each dialect behind its sokol backend's macro. The SPIR-V is also what the engine's own Vulkan
    # backend (engine/render/src/gpu/vulkan_*) reads while sokol runs another backend, so its guard opens to
    # FA_SHADERS_SPIRV too: a translation unit that needs the SPIR-V defines it before including the header, and every
    # other one (every GL, Metal or D3D11 player) carries none of it (docs/design/ARCHITECTURE_RENDERING_VULKAN.md).
    # Line ends are dropped to LF first (BSD sed has no \r in a regex), so a CRLF output from a Windows shdc is rewritten too.
    tr -d '\r' <"$output" |
        sed -e 's|^\( *\)#if defined(SOKOL_VULKAN)$|\1#if defined(SOKOL_VULKAN) \|\| defined(FA_SHADERS_SPIRV)|' \
            -e 's|^\( *\)#endif /\* SOKOL_VULKAN \*/$|\1#endif /* SOKOL_VULKAN \|\| FA_SHADERS_SPIRV */|' >"$output.tmp"
    # Every opening and closing guard must have been rewritten: one left over (another spelling from a newer sokol-shdc) would
    # leave the SPIR-V behind SOKOL_VULKAN only, so the engine's own Vulkan backend would find no twin.
    if grep -q -e '#if defined(SOKOL_VULKAN)[[:space:]]*$' -e '#endif /\* SOKOL_VULKAN \*/' "$output.tmp"; then
        rm -f "$output.tmp"
        echo "error: $output has a SOKOL_VULKAN guard the rewrite did not match (sokol-shdc changed its output?): fix the sed in $0" >&2
        exit 1
    fi
    mv "$output.tmp" "$output"
    case "$input" in "$ROOT"/engine/render/tests/*) ;; *) "$PACK" "$output" ;; esac
    compiled=$((compiled + 1))
done
# The packed headers, for the render tests (every header of $OUT, also the ones this run did not compile).
INDEX="$ROOT/engine/render/tests/shader_text_index.h"
{
    echo "// Generated by tools/shaders/compile_shaders.sh: do not edit. The generated shader headers whose GLSL texts are packed (see"
    echo "// engine/render/src/shader_text.h) with their tables and shader_desc functions, so engine/render/tests/shader_text_tests.cpp"
    echo "// checks every text and what every desc function hands to the driver. The two backend macros only make the headers declare"
    echo "// the GLES3 and GLCORE descs (sokol_gfx.h's declarations need no backend code): nothing here draws."
    echo "#pragma once"
    echo "#define FA_SHADER_TEXT_CHECK"
    # Not redefined where the build already gives them (fa_ext_sokol: -DSOKOL_GLES3 or -DSOKOL_GLCORE, value 1).
    for macro in SOKOL_GLES3 SOKOL_GLCORE; do
        echo "#ifndef $macro"
        echo "#define $macro 1"
        echo "#endif"
    done
    echo '#include "sokol_gfx.h"'
    echo
    for h in "$OUT"/*.glsl.h; do
        if grep -q 'fa::shader_text::Texts' "$h"; then echo "#include \"shaders/$(basename "$h")\""; fi
    done
    echo
    echo "static const fa::shader_text::Texts* const kShaderTexts[] = {"
    for h in "$OUT"/*.glsl.h; do
        base="$(basename "$h" .glsl.h)"
        for dialect in glsl300es glsl430; do
            if grep -q "fa::shader_text::Texts ${base}_${dialect}_pack_texts" "$h"; then echo "    &${base}_${dialect}_pack_texts,"; fi
        done
    done
    echo "};"
    echo
    echo "static const sg_shader_desc* (*const kShaderDescs[])(sg_backend) = {"
    for h in "$OUT"/*.glsl.h; do
        grep -q 'fa::shader_text::Texts' "$h" || continue
        sed -n 's|^static inline const sg_shader_desc\* \([A-Za-z0-9_]*_shader_desc\)(sg_backend backend) {$|    \&\1,|p' "$h"
    done
    echo "};"
} >"$INDEX.tmp"
mv "$INDEX.tmp" "$INDEX"
[ "$compiled" -gt 0 ] || { echo "no shader matches: $*" >&2; exit 1; }
echo "done."
