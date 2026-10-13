#!/usr/bin/env bash
#
# Configure, build and (optionally) test FactorIA with the CMake preset for this
# machine. Build trees go to build/<preset>. Presets live in CMakePresets.json.
#
#   ./scripts/build.sh [debug|release] [--test] [--preset NAME]
#
#   debug|release   configuration (default: debug)
#   --test          run the test suite (ctest) after building
#   --preset NAME   use this preset instead of <os>-<config>, e.g. macos-release
#                   or ios-simulator (see: cmake --list-presets)
#
# Windows: use scripts/build.ps1 instead.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

usage() {
    cat <<'EOF'
Usage: ./scripts/build.sh [debug|release] [--test] [--preset NAME]

  debug|release   configuration (default: debug)
  --test          run the test suite (ctest) after building
  --preset NAME   use this preset instead of <os>-<config>, e.g. macos-release
                  or ios-simulator (see: cmake --list-presets)
EOF
}

die() {
    echo "error: $*" >&2
    exit 1
}

case "$(uname -s)" in
    Linux)  OS=linux ;;
    Darwin) OS=macos ;;
    MINGW*|MSYS*|CYGWIN*)
        die "Windows detected. Use PowerShell instead: .\\scripts\\build.ps1 [debug|release] [-Test] [-Preset NAME]"
        ;;
    *) die "unsupported OS: $(uname -s)" ;;
esac

CONFIG=debug
RUN_TESTS=0
PRESET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        debug|release) CONFIG="$1" ;;
        --test) RUN_TESTS=1 ;;
        --preset)
            [[ -n "${2:-}" ]] || die "--preset needs a name (see: cmake --list-presets)"
            PRESET="$2"
            shift
            ;;
        --preset=*)
            PRESET="${1#--preset=}"
            [[ -n "$PRESET" ]] || die "--preset needs a name (see: cmake --list-presets)"
            ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown argument: $1 (try: ./scripts/build.sh --help)" ;;
    esac
    shift
done

[[ -n "$PRESET" ]] || PRESET="$OS-$CONFIG"

# Tool checks with install hints, so a fresh machine gets a clear next step.
hint_install() {
    case "$OS" in
        linux) echo "  Install the build dependencies with: ./scripts/bootstrap-linux.sh" >&2 ;;
        macos) echo "  Install the build dependencies with: ./scripts/bootstrap-macos.sh" >&2 ;;
    esac
}

require_tool() {
    local tool="$1" why="$2"
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: '$tool' not found ($why)." >&2
        hint_install
        exit 1
    fi
}

require_tool cmake "needed to configure the build"

CMAKE_VERSION="$(cmake --version | sed -n '1s/[^0-9]*\([0-9][0-9.]*\).*/\1/p')"
[[ -n "$CMAKE_VERSION" ]] || die "could not read the version from 'cmake --version'"
MIN_CMAKE="3.24"
if [[ "$(printf '%s\n' "$MIN_CMAKE" "$CMAKE_VERSION" | sort -V | head -n1)" != "$MIN_CMAKE" ]]; then
    die "CMake $CMAKE_VERSION is too old. FactorIA needs CMake $MIN_CMAKE or newer (see the hints in docs/BUILDING.md)."
fi

require_tool ninja "the desktop presets use the Ninja generator"

if [[ "$OS" == linux ]]; then
    if ! command -v c++ >/dev/null 2>&1 && ! command -v g++ >/dev/null 2>&1 && ! command -v clang++ >/dev/null 2>&1; then
        echo "error: no C++ compiler found (install g++ or clang++)." >&2
        hint_install
        exit 1
    fi
else
    if ! xcode-select -p >/dev/null 2>&1; then
        die "Xcode command line tools are missing. Run: xcode-select --install (or ./scripts/bootstrap-macos.sh)"
    fi
fi

echo "==> FactorIA preset: $PRESET (cmake $CMAKE_VERSION)"

echo "==> configure: cmake --preset $PRESET"
cmake --preset "$PRESET" \
    || die "configure failed for preset '$PRESET'. Presets usable on this machine: cmake --list-presets"

echo "==> build: cmake --build --preset $PRESET"
cmake --build --preset "$PRESET" || die "build failed for preset '$PRESET' (see the first error above)"

if [[ "$RUN_TESTS" -eq 1 ]]; then
    echo "==> test: ctest --preset $PRESET"
    ctest --preset "$PRESET" || die "tests failed for preset '$PRESET' (output above)"
fi

echo "==> done. Build tree: build/$PRESET"
