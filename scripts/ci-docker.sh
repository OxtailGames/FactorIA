#!/usr/bin/env bash
# Runs jobs of scripts/ci-local.sh inside a Linux container, so a Mac (or any host with Docker but without Linux) can
# check what GitHub's Linux and Windows (MinGW-w64 + Wine) CI jobs check before a push.
#
#   ./scripts/ci-docker.sh                  # linux and windows
#   ./scripts/ci-docker.sh linux            # one job
#   ./scripts/ci-docker.sh linux windows sniper
#
# Jobs: linux and windows run `ci-local.sh <job>` in the image of tools/ci/docker/Dockerfile (Ubuntu 24.04, linux/amd64
# like the GitHub runners; on Apple silicon Colima's Rosetta runs it). sniper runs scripts/build-sniper.sh, which starts
# the Steam Runtime containers itself, from the host (also linux/amd64).
#
# The checkout is bind-mounted at /src. The Linux build trees, the Wine prefix, ccache and the home directory
# (~/.factoria, the shader compiler) live in Docker volumes, so no Linux object ever lands in a host build directory and
# a second run is warm. Logs go to build/ci-logs/ on the host, like ci-local.sh.
#
# Exit code: 0 every job passed, 1 a job failed, 77 not set up (no docker, or its daemon is not running; on a Mac run
# scripts/setup-docker-macos.sh).
#
# Environment:
#   FA_CI_JOBS          parallel build jobs inside the container (default: the CPUs Docker has)
#   FA_CI_DOCKER_PLATFORM  image platform (default linux/amd64)
#   FA_CI_DOCKER_RESET=1   delete the volumes (build trees, ccache, Wine prefix) before running
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
PLATFORM="${FA_CI_DOCKER_PLATFORM:-linux/amd64}"
DOCKERFILE_DIR=tools/ci/docker
NOT_SET_UP=77

not_set_up() {
    echo "ci-docker: $1" >&2
    if [ "$(uname -s)" = Darwin ]; then echo "ci-docker: run ./scripts/setup-docker-macos.sh (installs Colima and Docker, starts the VM)" >&2
    else echo "ci-docker: install Docker (https://docs.docker.com/engine/install/) and start its daemon" >&2; fi
    exit $NOT_SET_UP
}

command -v docker >/dev/null 2>&1 || not_set_up "docker is not installed"
docker info >/dev/null 2>&1 || not_set_up "the Docker daemon is not running"

JOBS=()
for j in "$@"; do
    case "$j" in
        linux|windows|sniper) JOBS+=("$j") ;;
        -h|--help) sed -n '2,/^set -uo/{/^set -uo/d;s/^# \{0,1\}//;p}' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "ci-docker: unknown job '$j' (valid: linux windows sniper)" >&2; exit 2 ;;
    esac
done
[ ${#JOBS[@]} -eq 0 ] && JOBS=(linux windows)

LOGDIR="$ROOT/build/ci-logs"; mkdir -p "$LOGDIR"
FAILED=0

# The image is tagged with the hash of its Dockerfile, so editing it rebuilds it and nothing else does.
hash_of() { { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi; } | cut -c1-12; }
IMAGE="factoria-ci:$(hash_of "$ROOT/$DOCKERFILE_DIR/Dockerfile")"

ensure_image() {
    if docker image inspect "$IMAGE" >/dev/null 2>&1; then return 0; fi
    echo "==> building $IMAGE ($PLATFORM; the first time takes a few minutes)"
    docker build --platform "$PLATFORM" -t "$IMAGE" "$ROOT/$DOCKERFILE_DIR" >"$LOGDIR/docker-image.log" 2>&1 \
        || { tail -n 40 "$LOGDIR/docker-image.log"; echo "ci-docker: the image build failed (log: $LOGDIR/docker-image.log)" >&2; exit 1; }
}

reset_volumes() {
    docker volume rm -f factoria-ci-home factoria-ci-linux factoria-ci-windows >/dev/null
}

run_container_job() {
    local job="$1" build_volume
    case "$job" in linux) build_volume="factoria-ci-linux:/src/build/ci-linux" ;; windows) build_volume="factoria-ci-windows:/src/build/ci-windows-mingw" ;; esac
    local cpus; cpus="${FA_CI_JOBS:-$(docker info --format '{{.NCPU}}' 2>/dev/null || echo 4)}"
    # /root is a volume: ccache (~/.cache/ccache), ~/.factoria (the shader compiler) and the Wine prefix survive runs.
    # CCACHE_BASEDIR/NOHASHDIR make the cache independent of the checkout's path, as in build-sniper.sh.
    # A git worktree's .git is a file naming the main repository's directory by host path: mount that directory at the
    # same path, or git fails in the container and the build has no identity (fingerprint "unknown"; tests need one).
    local git_mount=()
    local common; common="$(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    case "$common" in "$ROOT"/*|"") ;; *) git_mount=(-v "$common:$common:ro") ;; esac
    # The perf budgets (CPU time, peak memory) are the numbers of GitHub's runners; the emulated x86-64 here uses about
    # 30% more memory and twice the CPU time, so they would all fail. FA_CI_DOCKER_PERF=1 runs them anyway.
    local exclude="${FA_CI_CTEST_EXCLUDE-}"
    if [ -z "$exclude" ] && [ "${FA_CI_DOCKER_PERF:-}" != 1 ]; then
        exclude='_perf$'
        echo "ci-docker: the perf budget tests (*_perf) are not run here: emulated x86-64 is slower and bigger than the runners (FA_CI_DOCKER_PERF=1 runs them)"
    fi
    docker run --rm --platform "$PLATFORM" --ulimit core=0 -w /src \
        -v "$ROOT:/src" ${git_mount[@]+"${git_mount[@]}"} -v "$build_volume" -v factoria-ci-home:/root \
        -e FA_CI_CTEST_EXCLUDE="$exclude" \
        -e FA_CI_JOBS="$cpus" -e FA_WINEPREFIX=/root/.wine-ci -e CCACHE_BASEDIR=/src -e CCACHE_NOHASHDIR=1 \
        -e FA_CI_IN_DOCKER=1 \
        "$IMAGE" ./scripts/ci-local.sh "$job"
}

run_sniper() {
    # build-sniper.sh mounts the checkout into the Steam Runtime images with the docker of this host.
    DOCKER_DEFAULT_PLATFORM="$PLATFORM" ./scripts/build-sniper.sh all
}

[ "${FA_CI_DOCKER_RESET:-}" = 1 ] && reset_volumes
for j in "${JOBS[@]}"; do
    case "$j" in
        linux|windows)
            ensure_image
            echo "==> ci-docker: $j in $IMAGE"
            run_container_job "$j" 2>&1 | tee "$LOGDIR/docker-$j.log"
            [ "${PIPESTATUS[0]}" -eq 0 ] || FAILED=1 ;;
        sniper)
            echo "==> ci-docker: sniper"
            run_sniper 2>&1 | tee "$LOGDIR/docker-sniper.log"
            [ "${PIPESTATUS[0]}" -eq 0 ] || FAILED=1 ;;
    esac
done
exit $FAILED
