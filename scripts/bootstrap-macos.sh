#!/usr/bin/env bash
#
# Prepares a Mac to build FactorIA: Xcode command line tools and the Homebrew
# packages CMake, Ninja and ccache. Safe to run again.
#
#   ./scripts/bootstrap-macos.sh
#
# iOS builds also need the full Xcode app (App Store). This script only checks
# for it and tells you what to do.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
    echo "error: this script is for macOS. On Linux use ./scripts/bootstrap-linux.sh." >&2
    exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
    echo "Xcode command line tools are missing. Starting the installer..."
    xcode-select --install || true
    echo "error: finish the installation in the dialog, then run this script again." >&2
    exit 1
fi
echo "==> Xcode command line tools: $(xcode-select -p)"

if ! command -v brew >/dev/null 2>&1; then
    echo "error: Homebrew is not installed. Get it from https://brew.sh, then run this script again." >&2
    exit 1
fi

echo "==> Homebrew: cmake, ninja, ccache"
brew install cmake ninja ccache

if xcodebuild -version >/dev/null 2>&1; then
    echo "==> full Xcode: $(xcodebuild -version | sed -n '1p')"
else
    echo "note: full Xcode is not active. Only iOS builds need it (macOS desktop builds do not)."
    echo "      Install Xcode from the App Store, open it once, then run:"
    echo "      sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi

echo "==> done. Next: ./scripts/build.sh debug --test"
