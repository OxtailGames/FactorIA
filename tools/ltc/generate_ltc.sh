#!/usr/bin/env bash
# Regenerates engine/render/src/ltc_tables.h: fits the LTC tables with tools/ltc (fa_ltc_gen, Release build) and writes the header.
# The header is committed, so normal builds never need this script; run it after changing the fit (tools/ltc/src) or the BRDF of
# engine/render/shaders/mesh_common.glsl, and commit the result. About 10 s to a minute on a multi-core machine.
#
#   tools/ltc/generate_ltc.sh            # builds into build/ltc-gen
#   tools/ltc/generate_ltc.sh <builddir> # uses (and configures, if new) this build dir
#
# docs/design/ARCHITECTURE_AREA_LIGHTS.md, "Regenerating the tables".
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="${1:-$ROOT/build/ltc-gen}"

if [ ! -f "$BUILD/CMakeCache.txt" ]; then
    cmake -S "$ROOT" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release -DFA_BUILD_TESTS=OFF
fi
cmake --build "$BUILD" --target fa_ltc_gen
exe="$(find "$BUILD" -name fa_ltc_gen -o -name fa_ltc_gen.exe | head -n 1)"
"$exe" --out "$ROOT/engine/render/src/ltc_tables.h"
echo "wrote $ROOT/engine/render/src/ltc_tables.h"
