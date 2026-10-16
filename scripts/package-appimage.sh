#!/usr/bin/env bash
#
# Builds the Linux AppImage from the unpacked Linux package (the FactorIA/ folder that becomes
# FactorIA-linux-x64.tar.gz). Used by .github/workflows/release.yml; usage and launch behaviour in
# docs/GETTING_STARTED.md ("Download").
#
#   scripts/package-appimage.sh dist/FactorIA dist/FactorIA-linux-x64.AppImage
#
# Inside: usr/bin/factoria and usr/bin/factoria_player (so `factoria export` finds the player next to the binary),
# platforms/linux/AppRun (no arguments: the editor; otherwise the factoria CLI), the .desktop file and the icon.
# Like the tar.gz it links the system's X11, OpenGL and ALSA and the glibc of the machine that built it; it bundles no
# libraries.
#
# appimagetool is itself an AppImage: it runs with APPIMAGE_EXTRACT_AND_RUN, so this works without FUSE. Both downloads
# are pinned and checked against their SHA-256 (GitHub shows it on each release asset). To upgrade, change the
# versions and hashes together.
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <unpacked FactorIA folder> <output .AppImage>" >&2
    exit 2
fi
package="$(cd "$1" && pwd)"
out="$(realpath -m "$2")"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

appimagetool_url=https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage
appimagetool_sha256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
runtime_url=https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64
runtime_sha256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fetch() {  # url sha256 file
    curl -fsSL --retry 3 -o "$3" "$1"
    echo "$2  $3" | sha256sum -c --quiet - || { echo "error: $1 does not match the pinned SHA-256" >&2; exit 1; }
}
fetch "$appimagetool_url" "$appimagetool_sha256" "$work/appimagetool"
fetch "$runtime_url" "$runtime_sha256" "$work/runtime"
chmod +x "$work/appimagetool"

appdir="$work/FactorIA.AppDir"
mkdir -p "$appdir/usr/bin"
cp "$package/factoria" "$package/factoria_player" "$appdir/usr/bin/"
cp "$repo/platforms/linux/AppRun" "$appdir/AppRun"
cp "$repo/platforms/linux/FactorIA.desktop" "$repo/platforms/linux/factoria.svg" "$appdir/"
mkdir -p "$appdir/usr/share/doc/factoria"  # licenses (also printed by `factoria docs licenses`)
cp "$package/LICENSE" "$package/THIRD_PARTY_NOTICES.txt" "$appdir/usr/share/doc/factoria/"
chmod +x "$appdir/AppRun" "$appdir/usr/bin/"*

mkdir -p "$(dirname "$out")"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$work/appimagetool" --no-appstream --runtime-file "$work/runtime" "$appdir" "$out"
chmod +x "$out"
ls -l "$out"
