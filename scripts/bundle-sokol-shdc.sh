#!/usr/bin/env bash
#
# Puts the pinned sokol-shdc (the shader compiler of custom materials, docs/design/CUSTOM_SHADERS.md D3) for the package
# of this host into <dir>, for .github/workflows/release.yml. Run it on the runner that builds the package:
#
#   scripts/bundle-sokol-shdc.sh build/sokol-shdc     # -> build/sokol-shdc/sokol-shdc[.exe]
#
# The commit and the SHA-256 of each file are read from tools/common/include/fa/tooling/setup.h, the pin that
# `factoria setup shaders` checks against (one source of truth; a tooling doctest keeps the lines read here in shape). A
# file that does not match fails the script, and so the release.
#
#   Windows   bin/win32/sokol-shdc.exe, the pinned file itself
#   Linux     bin/linux/sokol-shdc (x86_64), the pinned file itself
#   macOS     bin/osx (x86_64) and bin/osx_arm64 joined with lipo into one universal file, like factoria; each slice is
#             checked to be its pinned file. release.yml then signs it with factoria, which changes the bytes.
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <output folder>" >&2
    exit 2
fi
out="$1"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
header="$repo/tools/common/include/fa/tooling/setup.h"
pin="$(tr -d '\r' < "$header")"  # a Windows checkout may have CRLF

fail() { echo "::error::$*" >&2; exit 1; }
sha256_of() {
    if command -v sha256sum > /dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

commit="$(sed -n 's/^inline constexpr const char\* kSetupSokolShdcCommit = "\([0-9a-f]\{40\}\)";$/\1/p' <<< "$pin")"
[[ -n "$commit" ]] || fail "kSetupSokolShdcCommit not found in $header"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fetch() {  # <dir in sokol-tools-bin> <file name>: downloads bin/<dir>/<file> to $work/<dir>/<file> and checks it
    local sha got file="$work/$1/$2"
    # The row of kSetupSokolShdcBinaries for <dir>: {"<host>", "<arch>", "<dir>", "<sha256>"},
    sha="$(sed -n '/kSetupSokolShdcBinaries\[\] = {/,/^};/p' <<< "$pin" |
        sed -n "s/^ *{\"[a-z]*\", \"[a-z0-9]*\", \"$1\", \"\([0-9a-f]\{64\}\)\"},\$/\1/p")"
    [[ -n "$sha" && "$sha" != *$'\n'* ]] || fail "no single kSetupSokolShdcBinaries row for bin/$1 in $header"
    mkdir -p "$work/$1"
    curl -fsSL --retry 3 -o "$file" "https://raw.githubusercontent.com/floooh/sokol-tools-bin/$commit/bin/$1/$2"
    got="$(sha256_of "$file")"
    [[ "$got" == "$sha" ]] || fail "bin/$1/$2 of sokol-tools-bin $commit is not the pinned file (SHA-256 $got, setup.h pins $sha)"
}

mkdir -p "$out"
case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*)
        fetch win32 sokol-shdc.exe
        cp "$work/win32/sokol-shdc.exe" "$out/"
        ;;
    Linux)
        [[ "$(uname -m)" == x86_64 ]] || fail "the Linux package is x86_64; this runner is $(uname -m)"
        fetch linux sokol-shdc
        cp "$work/linux/sokol-shdc" "$out/"
        ;;
    Darwin)
        fetch osx sokol-shdc
        fetch osx_arm64 sokol-shdc
        lipo -create "$work/osx/sokol-shdc" "$work/osx_arm64/sokol-shdc" -output "$out/sokol-shdc"
        lipo "$out/sokol-shdc" -thin x86_64 -output "$work/x86_64"
        lipo "$out/sokol-shdc" -thin arm64 -output "$work/arm64"
        cmp -s "$work/x86_64" "$work/osx/sokol-shdc" || fail "the x86_64 slice of the universal sokol-shdc is not the pinned file"
        cmp -s "$work/arm64" "$work/osx_arm64/sokol-shdc" || fail "the arm64 slice of the universal sokol-shdc is not the pinned file"
        ;;
    *) fail "no sokol-shdc for a $(uname -s) package" ;;
esac
chmod +x "$out"/sokol-shdc*
ls -l "$out"
echo "sokol-shdc of sokol-tools-bin $commit, SHA-256 checked against setup.h"
