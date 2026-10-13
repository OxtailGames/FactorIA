#!/usr/bin/env bash
#
# Builds the FactorIA player library for Android with the NDK. Uses the CMake
# preset android-arm64 (devices) or android-x86_64 (emulator).
#
#   ./scripts/build-android.sh [debug|release] [--emulator]
#
#   debug|release  configuration (default: debug)
#   --emulator     build x86_64 for the Android emulator instead of arm64 devices
#
# Needs: CMake 3.24+, Ninja, and the Android NDK (r27 or newer recommended).
# The NDK is found through ANDROID_NDK_HOME, then ANDROID_NDK_ROOT,
# ANDROID_NDK_LATEST_HOME, or the newest NDK under $ANDROID_HOME/ndk.
#
# Output: build/<preset>/player/libfactoria_player.so
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

die() {
    echo "error: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: ./scripts/build-android.sh [debug|release] [--emulator]

  debug|release  configuration (default: debug)
  --emulator     build x86_64 for the Android emulator instead of arm64 devices
EOF
}

CONFIG=debug
PRESET=android-arm64

while [[ $# -gt 0 ]]; do
    case "$1" in
        debug|release) CONFIG="$1" ;;
        --emulator) PRESET=android-x86_64 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown argument: $1 (try: ./scripts/build-android.sh --help)" ;;
    esac
    shift
done

if [[ "$CONFIG" == release ]]; then BUILD_TYPE=Release; else BUILD_TYPE=Debug; fi

# ---- prerequisites ----------------------------------------------------------

for tool in cmake ninja; do
    command -v "$tool" >/dev/null 2>&1 \
        || die "'$tool' not found. Install CMake 3.24+ and Ninja (Linux: ./scripts/bootstrap-linux.sh, macOS: ./scripts/bootstrap-macos.sh)."
done

NDK="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-${ANDROID_NDK_LATEST_HOME:-}}}"
if [[ -z "$NDK" ]]; then
    SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
    if [[ -n "$SDK" && -d "$SDK/ndk" ]]; then
        shopt -s nullglob
        NDK_DIRS=("$SDK"/ndk/*/)
        shopt -u nullglob
        if [[ ${#NDK_DIRS[@]} -gt 0 ]]; then
            # Newest installed NDK (sort -V orders version numbers correctly).
            NDK="$(printf '%s\n' "${NDK_DIRS[@]}" | sort -V | tail -n1)"
            NDK="${NDK%/}"
        fi
    fi
fi
[[ -n "$NDK" ]] || die "Android NDK not found. Install it in Android Studio (SDK Manager > SDK Tools > NDK (Side by side)), then run:
  export ANDROID_NDK_HOME=/path/to/Android/sdk/ndk/<version>"

export ANDROID_NDK_HOME="$NDK"
TOOLCHAIN="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
[[ -f "$TOOLCHAIN" ]] \
    || die "no CMake toolchain at $TOOLCHAIN. ANDROID_NDK_HOME must point to the NDK folder itself."

NDK_MAJOR="$(sed -n 's/^Pkg\.Revision *= *\([0-9][0-9]*\).*/\1/p' "$ANDROID_NDK_HOME/source.properties" 2>/dev/null | sed -n '1p')" || true
if [[ -n "$NDK_MAJOR" && "$NDK_MAJOR" -lt 27 ]]; then
    echo "warning: NDK r$NDK_MAJOR found. r27 or newer is recommended." >&2
fi

# ---- configure and build ----------------------------------------------------

echo "==> NDK: $ANDROID_NDK_HOME${NDK_MAJOR:+ (r$NDK_MAJOR)}"

# CMake keeps the NDK toolchain of a build tree's first configure, so after an NDK
# change the tree would silently keep the old NDK. Remember the toolchain this
# tree was configured with (a stamp file, written after a successful configure)
# and start the tree over when it differs.
BUILD_DIR="build/$PRESET"
STAMP="$BUILD_DIR/factoria-ndk-toolchain.txt"
if [[ -d "$BUILD_DIR" ]] && [[ "$(cat "$STAMP" 2>/dev/null || true)" != "$TOOLCHAIN" ]]; then
    echo "==> $BUILD_DIR was configured with another NDK (or outside this script); configuring from scratch"
    rm -rf "$BUILD_DIR"
fi

echo "==> configure: cmake --preset $PRESET -DCMAKE_BUILD_TYPE=$BUILD_TYPE"
cmake --preset "$PRESET" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
printf '%s\n' "$TOOLCHAIN" > "$STAMP"

echo "==> build: factoria_player"
cmake --build --preset "$PRESET" --target factoria_player

echo "==> done: build/$PRESET/player/libfactoria_player.so"
