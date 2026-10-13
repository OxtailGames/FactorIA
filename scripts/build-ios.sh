#!/usr/bin/env bash
#
# Builds the FactorIA player for iOS with Xcode. Uses the CMake preset ios
# (devices) or ios-simulator. Requires macOS and the full Xcode app.
#
#   ./scripts/build-ios.sh [debug|release] [--simulator]
#
#   debug|release  configuration (default: debug)
#   --simulator    build for the iOS Simulator instead of devices
#
# Builds are compiled without code signing (CODE_SIGNING_ALLOWED=NO). Packaging
# and signing an app happen in platforms/ios.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

die() {
    echo "error: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: ./scripts/build-ios.sh [debug|release] [--simulator]

  debug|release  configuration (default: debug)
  --simulator    build for the iOS Simulator instead of devices
EOF
}

CONFIG=debug
SIMULATOR=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        debug|release) CONFIG="$1" ;;
        --simulator) SIMULATOR=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown argument: $1 (try: ./scripts/build-ios.sh --help)" ;;
    esac
    shift
done

if [[ "$CONFIG" == release ]]; then XCODE_CONFIG=Release; else XCODE_CONFIG=Debug; fi

# ---- prerequisites ----------------------------------------------------------

[[ "$(uname -s)" == Darwin ]] || die "iOS builds need macOS with Xcode."

command -v cmake >/dev/null 2>&1 \
    || die "'cmake' not found. Install it with: ./scripts/bootstrap-macos.sh"

if ! xcodebuild -version >/dev/null 2>&1; then
    die "full Xcode is required; the command line tools are not enough. Install Xcode from the App Store, open it once, then run:
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi

if [[ "$SIMULATOR" -eq 1 ]]; then
    PRESET=ios-simulator
    SDK=iphonesimulator
else
    PRESET=ios
    SDK=iphoneos
fi

xcrun --sdk "$SDK" --show-sdk-path >/dev/null 2>&1 \
    || die "the $SDK SDK is not available in this Xcode. Install the iOS platform in Xcode (Settings > Platforms)."

echo "==> Xcode: $(xcodebuild -version | sed -n '1p')"

# ---- configure and build ----------------------------------------------------

echo "==> configure: cmake --preset $PRESET"
cmake --preset "$PRESET"

echo "==> build: factoria_player ($XCODE_CONFIG, $SDK)"
cmake --build --preset "$PRESET" --config "$XCODE_CONFIG" --target factoria_player \
    -- -sdk "$SDK" CODE_SIGNING_ALLOWED=NO

echo "==> done. Build tree: build/$PRESET"
