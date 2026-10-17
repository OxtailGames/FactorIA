#!/usr/bin/env bash
#
# Builds the Linux release the way the release packages are built: inside the Steam Runtime "sniper" SDK container
# (glibc 2.31, GCC 14, CMake 3.25), with libstdc++ and libgcc linked statically, so the programs run on the Steam Linux
# Runtime "sniper" (what Steam runs Linux games in, also on the Steam Deck), Ubuntu 20.04 and newer, Debian 11 and newer.
# It needs Docker or Podman, found in that order (the image is about 1.2 GB); on Linux only. CI runs the same script (.github/workflows/ci.yml
# job `Linux (Steam Runtime sniper)`, and the `linux-x64` package of release.yml).
#
#   ./scripts/build-sniper.sh [build|check|smoke|all] [-- <cmake configure arguments>]
#
#   build   Configures and builds the preset `linux-sniper` (Release, no tests) in the SDK container into
#           build/linux-sniper: factoria (CLI + editor) and factoria_player. Arguments after `--` go to `cmake --preset`,
#           e.g. `-- -DFA_UPDATE_REPO=OxtailGames/FactorIA` (the release does that).
#   check   In the SDK container: fails when factoria or factoria_player imports a glibc, GLIBCXX, CXXABI or GCC symbol
#           version newer than the sniper runtime provides (objdump -T; the limits are read from the container's own
#           libc.so.6, libstdc++.so.6 and libgcc_s.so.1, which are the runtime's).
#   smoke   In the sniper RUNTIME container (the `platform` image, the one games run in): ldd finds every library,
#           `factoria_player --version`, `factoria version`, `factoria new --template 2d-empty` and one headless frame
#           (`factoria run --headless --frames 1`, on Mesa's software renderer). Nothing else is installed there.
#   all     build, check and smoke (the default).
#
# Environment:
#   FA_SNIPER_TAG        image tag of both images (default: the pinned one below; `latest` follows Valve's releases)
#   FA_CCACHE_DIR        ccache directory on this machine, mounted into the build (default: ~/.cache/ccache)
#
# Inside a sniper container already (a CI job with `container:`, a distrobox made from the SDK image) the steps run in
# place, without Docker.
set -euo pipefail

SNIPER_REGISTRY=registry.gitlab.steamos.cloud/steamrt/sniper
# Both images, same tag. Pinned so a build is reproducible; Valve publishes a new tag about every month
# (https://gitlab.steamos.cloud/steamrt/sniper/sdk): to upgrade, change the tag and see that `all` still passes.
SNIPER_TAG="${FA_SNIPER_TAG:-3.0.20261007.263965}"
SDK_IMAGE="$SNIPER_REGISTRY/sdk:$SNIPER_TAG"
PLATFORM_IMAGE="$SNIPER_REGISTRY/platform:$SNIPER_TAG"
PRESET=linux-sniper
OUT="build/$PRESET"
PROGRAMS=("$OUT/tools/cli/factoria" "$OUT/player/factoria_player")
# The SDK image has GCC 10 by default, which has no std::format; GCC 14 is installed next to it.
CC_NAME=gcc-14
CXX_NAME=g++-14

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() { echo "error: $*" >&2; exit 1; }

# A GitHub Actions annotation in CI, a plain message elsewhere.
fail_msg() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then echo "::error::$*"; else echo "error: $*" >&2; fi
}

usage() { sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "${BASH_SOURCE[0]}"; }

in_steamrt() { [[ "$(. /etc/os-release 2>/dev/null && echo "${ID:-}")" == steamrt ]]; }

# ---- steps that run inside a sniper container --------------------------------------------------------------------------

inside_build() {
    for tool in "$CC_NAME" "$CXX_NAME" cmake ninja; do
        command -v "$tool" > /dev/null ||
            die "$tool is not in this container ($SNIPER_TAG). Is it the sniper SDK image ($SNIPER_REGISTRY/sdk)? The platform image has no compilers."
    done
    export CC="$CC_NAME" CXX="$CXX_NAME"
    cd "$ROOT"
    echo "==> $(. /etc/os-release && echo "$PRETTY_NAME $BUILD_ID"), $("$CXX_NAME" --version | head -n 1), $(cmake --version | head -n 1), glibc $(ldd --version | head -n 1 | sed 's/.* //')"
    cmake --preset "$PRESET" "$@"
    cmake --build --preset "$PRESET" --parallel
    if command -v ccache > /dev/null; then ccache --show-stats | head -n 12 || true; fi
    ls -l "${PROGRAMS[@]}"
}

# The newest version tagged PREFIX_x.y.z in the text on stdin ("GLIBC_2.31" -> 2.31).
newest_version() { { grep -oE "${1}_[0-9]+(\.[0-9]+)*" || true; } | sed "s/^${1}_//" | sort -uV | tail -n 1; }

# True when version $1 is not newer than $2.
version_le() { [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" == "$2" ]]; }

system_lib() {
    local d
    for d in /lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu; do
        if [[ -e "$d/$1" ]]; then echo "$d/$1"; return; fi
    done
    die "$1 is not in this container: check needs the sniper SDK image, whose libraries are the runtime's."
}

inside_check() {
    cd "$ROOT"
    command -v objdump > /dev/null || die "objdump is not in this container: run check in the sniper SDK image."
    local failed=0 file spec prefix lib limit used imports bad line
    for file in "${PROGRAMS[@]}"; do
        if [[ ! -f "$file" ]]; then
            fail_msg "$file does not exist: run ./scripts/build-sniper.sh build first"
            failed=1
            continue
        fi
        echo "==> $file"
        objdump -p "$file" | sed -n 's/^ *NEEDED */    needs /p'
        imports="$(objdump -T "$file" | grep -F '*UND*' || true)"
        # PREFIX:the library of the runtime that defines those versions.
        for spec in GLIBC:libc.so.6 GLIBCXX:libstdc++.so.6 CXXABI:libstdc++.so.6 GCC:libgcc_s.so.1; do
            IFS=: read -r prefix lib <<< "$spec"
            used="$(newest_version "$prefix" <<< "$imports")"
            [[ -n "$used" ]] || continue
            limit="$(objdump -T "$(system_lib "$lib")" | newest_version "$prefix")"
            [[ -n "$limit" ]] || die "cannot read the $prefix versions of $lib in this container"
            echo "    ${prefix}_$used is the newest it imports; the sniper runtime's $lib has up to ${prefix}_$limit"
            if version_le "$used" "$limit"; then continue; fi
            failed=1
            # The imports that are too new: "version symbol" per line.
            bad="$(awk -v p="${prefix}_" '{ for (i = 1; i <= NF; i++) { v = $i; gsub(/[()]/, "", v); if (index(v, p) == 1) print substr(v, length(p) + 1), $NF } }' <<< "$imports" |
                while read -r v sym; do version_le "$v" "$limit" || echo "${prefix}_$v $sym"; done | sort -uV | head -n 8 | tr '\n' ',' | sed 's/,$//; s/,/, /g')" || true
            case "$prefix" in
                GLIBC) line="it was not built against the sniper glibc. Build it with ./scripts/build-sniper.sh (the sniper SDK container), not on a newer system" ;;
                *) line="libstdc++/libgcc must be linked statically (-DFA_LINUX_STATIC_LIBSTDCXX=ON, the linux-sniper preset)" ;;
            esac
            fail_msg "$file needs ${prefix}_$used ($bad) but the sniper runtime only provides ${prefix}_$limit in $lib: it would not start there. Fix: $line"
        done
    done
    [[ "$failed" == 0 ]] || exit 1
    echo "==> check passed: nothing newer than the sniper runtime provides"
}

inside_smoke() {
    cd "$ROOT"
    local fa="$ROOT/${PROGRAMS[0]}" player="$ROOT/${PROGRAMS[1]}"
    local f missing tmp out version player_version
    echo "==> $(. /etc/os-release && echo "$PRETTY_NAME $BUILD_ID"), glibc $(ldd --version | head -n 1 | sed 's/.* //')"
    for f in "$fa" "$player"; do
        [[ -x "$f" ]] || die "$f does not exist: run ./scripts/build-sniper.sh build first"
        missing="$(ldd "$f" | grep 'not found' || true)"
        if [[ -n "$missing" ]]; then
            fail_msg "$f needs libraries the sniper runtime does not have: $(echo "$missing" | sed 's/^[[:space:]]*//' | tr '\n' ';')"
            exit 1
        fi
    done
    ldd "$fa" | sed 's/^/    /'

    tmp="$(mktemp -d)"
    export HOME="$tmp/home"
    mkdir -p "$HOME"
    # Mesa picks its software renderer (llvmpipe) when there is no GPU; this keeps a machine that has one from using it.
    export LIBGL_ALWAYS_SOFTWARE=1

    version="$("$fa" version)"
    player_version="$("$player" --version)"
    echo "$version"
    echo "$player_version"
    [[ "${player_version#factoria_player }" == "${version#factoria }" ]] ||
        { fail_msg "'$player_version' and '$version' are different versions"; exit 1; }

    "$fa" new "$tmp/game" --template 2d-empty
    # The run succeeds without a GPU too when no frame is drawn, so the screenshot proves a GPU context worked.
    out="$("$fa" run "$tmp/game" --headless --frames 1 --render-all --screenshot-at 0 --screenshot-pattern "$tmp/frame_{frame}.png" 2>&1)" ||
        { echo "$out"; fail_msg "'factoria run --headless --frames 1' failed in the sniper runtime (output above)"; exit 1; }
    echo "$out"
    [[ -s "$tmp/frame_0.png" ]] || { fail_msg "the headless frame wrote no screenshot ($tmp/frame_0.png) in the sniper runtime"; exit 1; }
    rm -rf "$tmp"
    echo "==> smoke passed"
}

# ---- starting a step in the container ----------------------------------------------------------------------------------

container_engine() {
    if command -v docker > /dev/null; then echo docker
    elif command -v podman > /dev/null; then echo podman
    else die "neither docker nor podman is installed. Install one (https://docs.docker.com/engine/install/ or 'apt install podman'), or run this inside a Steam Runtime sniper SDK container."
    fi
}

# run_step <image> <rw|ro> <step> [arguments]: this script's step <step> inside <image>, with this checkout at /src.
run_step() {
    local image="$1" mode="$2"; shift 2
    local engine; engine="$(container_engine)"
    local args=(run --rm -v "$ROOT:/src:$mode" -w /src -e HOME=/tmp/fa-home -e GITHUB_ACTIONS)
    if [[ "$engine" == podman ]]; then
        # Rootless: the same user inside, and no SELinux relabelling of the checkout.
        args+=(--userns=keep-id --security-opt label=disable)
    else
        args+=(--user "$(id -u):$(id -g)")
    fi
    if [[ "$mode" == rw ]]; then
        local cache="${FA_CCACHE_DIR:-$HOME/.cache/ccache}"
        mkdir -p "$cache" "$ROOT/build"
        # ccache 4.2 in the image has no base_dir argument (CMakeLists.txt passes one from 4.8): the environment does the
        # same, and /src is the same path in every run, so the cache is shared between runs and checkouts.
        args+=(-v "$cache:/ccache" -e CCACHE_DIR=/ccache -e CCACHE_BASEDIR=/src -e CCACHE_NOHASHDIR=1)
    fi
    echo "==> $engine run $image: $*"
    "$engine" "${args[@]}" "$image" /src/scripts/build-sniper.sh "$@"
}

# ---- main --------------------------------------------------------------------------------------------------------------

step=all
case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    build|check|smoke|all) step="$1"; shift ;;
    ''|--) ;;
    *) usage >&2; die "unknown step '$1': use build, check, smoke or all" ;;
esac
if [[ "${1:-}" == -- ]]; then shift; fi
[[ "$(uname -s)" == Linux ]] || die "this script is for Linux (Docker or Podman, or WSL on Windows)."

# In a sniper container already (started by run_step, or a CI job with `container:`): run the steps in place. The platform
# image has no compilers, the SDK image has everything.
if in_steamrt; then
    case "$step" in
        build) inside_build "$@" ;;
        check) inside_check ;;
        smoke) inside_smoke ;;
        all) inside_build "$@"; inside_check; inside_smoke ;;
    esac
    exit 0
fi

case "$step" in
    build) run_step "$SDK_IMAGE" rw build "$@" ;;
    check) run_step "$SDK_IMAGE" ro check ;;
    smoke) run_step "$PLATFORM_IMAGE" ro smoke ;;
    all)
        run_step "$SDK_IMAGE" rw build "$@"
        run_step "$SDK_IMAGE" ro check
        run_step "$PLATFORM_IMAGE" ro smoke
        ;;
esac
