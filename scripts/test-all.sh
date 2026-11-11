#!/usr/bin/env bash
# The full check before a push, in one command (CLAUDE.md, "Finishing a task"; docs/BUILDING.md, "Testing"):
#
#   1. a Debug build of every target and the whole Debug ctest suite (the example games' tests are registered DISABLED
#      there: they run the engine for minutes and a Debug build is several times slower), then
#   2. an optimized (Release) build of the factoria CLI and `ctest -L example`: the example games' tests, validations and
#      perf budgets.
#
#   scripts/test-all.sh                      # both steps
#   scripts/test-all.sh --debug-only         # only step 1
#   scripts/test-all.sh --examples-only      # only step 2
#   FA_TEST_DEBUG_DIR=build/agent-x FA_TEST_RELEASE_DIR=build/agent-x-rel FA_TEST_JOBS=8 scripts/test-all.sh
#
# FA_TEST_JOBS: build jobs (default: the CPU count). FA_TEST_CTEST_JOBS: parallel tests (default 3: some tests are timing
# sensitive and the examples are heavy). ccache is used when it is installed: CMakeLists.txt finds it and gives it the
# settings that let every checkout and worktree share one cache, so no compiler launcher is passed here (passing one
# turns those settings off). Prints the time of each step. Exit code 1 when anything fails; both steps run even if the
# first one fails.
set -uo pipefail
cd "$(dirname "$0")/.."

DEBUG_DIR="${FA_TEST_DEBUG_DIR:-build/dev}"
RELEASE_DIR="${FA_TEST_RELEASE_DIR:-build/release}"
JOBS="${FA_TEST_JOBS:-$( (nproc || sysctl -n hw.ncpu) 2>/dev/null || echo 4)}"
CTEST_JOBS="${FA_TEST_CTEST_JOBS:-3}"
do_debug=1; do_examples=1
case "${1:-}" in
    --debug-only) do_examples=0 ;;
    --examples-only) do_debug=0 ;;
    "") ;;
    *) echo "usage: $0 [--debug-only | --examples-only]"; exit 2 ;;
esac

# GPU tests need a display on Linux: Xvfb when there is none.
with_display() {
    if [ "$(uname -s)" = "Linux" ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
        xvfb-run -a -s "-screen 0 1280x720x24" "$@"
    else "$@"; fi
}

status=0
summary=()
step() {  # step <name> <command...>: runs it, records the result and the time
    local name="$1"; shift
    local t0=$SECONDS
    echo "==> $name"
    if "$@"; then summary+=("PASS  $name ($((SECONDS - t0)) s)")
    else summary+=("FAIL  $name ($((SECONDS - t0)) s)"); status=1; return 1; fi
}

debug_suite() {
    cmake -S . -B "$DEBUG_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Debug || return 1
    step "Debug: build every target" cmake --build "$DEBUG_DIR" -j "$JOBS" || return 1
    step "Debug: ctest (examples disabled)" with_display ctest --test-dir "$DEBUG_DIR" -j "$CTEST_JOBS" --output-on-failure
}

example_suite() {
    cmake -S . -B "$RELEASE_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Release || return 1
    step "Release: build factoria" cmake --build "$RELEASE_DIR" -j "$JOBS" --target factoria || return 1
    step "Release: ctest -L example" with_display ctest --test-dir "$RELEASE_DIR" -L example -j "$CTEST_JOBS" --output-on-failure
}

[ $do_debug = 1 ] && debug_suite
[ $do_examples = 1 ] && example_suite

echo; echo "==== test-all summary"
printf '%s\n' "${summary[@]}"
exit $status
