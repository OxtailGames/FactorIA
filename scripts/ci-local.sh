#!/usr/bin/env bash
# Local CI: runs the project's checks on THIS machine instead of GitHub-hosted
# runners (no Actions minutes needed). Every job that the host can run is run;
# the others are reported as skipped with the reason and how to enable them.
#
#   ./scripts/ci-local.sh                # all jobs this host supports
#   ./scripts/ci-local.sh linux windows  # only some jobs
#   FA_CI_JOBS=4 ./scripts/ci-local.sh   # parallel build jobs (default: nproc)
#
# Jobs
#   linux    Linux build (GCC/Clang) + full ctest. GPU tests use Mesa llvmpipe
#            through Xvfb when there is no display.
#   windows  On a Windows host: MSVC build + ctest through scripts/build.ps1
#            (Visual Studio 2022+). On Linux: Windows x64 cross-build with
#            MinGW-w64 (D3D11 backend) + every unit-test executable and a CLI
#            smoke test under Wine (catches Windows API/backend bugs; MSVC-only
#            quirks need the Windows host).
#   android  factoria_player for arm64-v8a (needs ANDROID_NDK_HOME, NDK r27+).
#   web      Web player (Emscripten, preset web-release; needs EMSDK set), the factoria CLI, a template game exported with
#            `factoria export --platform web`, the zip checked as itch.io takes it and the export run in headless Chrome
#            until the first frames render (scripts/web-smoke.sh; needs Node 22+ and Chrome/Chromium or CHROME_BIN).
#   macos    macOS build + ctest (only on a Mac).
#   sniper   Linux release programs built in the Steam Runtime sniper SDK container, checked and run in the sniper
#            runtime image (scripts/build-sniper.sh; needs Docker or Podman). Not part of the default set: it pulls
#            about 1.5 GB of images the first time.
#   ios      iOS Simulator build of factoria_player (only on a Mac with Xcode).
#
# Exit code: 0 if every job that ran passed, 1 otherwise.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
JOBS="${FA_CI_JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
HOST="$(uname -s)"
case "$HOST" in MINGW*|MSYS*|CYGWIN*) HOST=Windows ;; esac
LOGDIR="$ROOT/build/ci-logs"
mkdir -p "$LOGDIR"

declare -a RESULTS=()
FAILED=0

note()   { printf '\n\033[1m== %s\033[0m\n' "$*"; }
record() { RESULTS+=("$(printf '%-8s %-7s %s' "$1" "$2" "$3")"); [ "$2" = "FAIL" ] && FAILED=1; return 0; }

# Run a command, keep its full log, show the tail on failure.
run_logged() {
    local log="$1"; shift
    if "$@" >"$log" 2>&1; then return 0; fi
    echo "---- last lines of $log ----"; tail -n 40 "$log"; return 1
}

with_display() {
    if [ -n "${DISPLAY:-}" ] || [ "$HOST" = "Darwin" ]; then "$@"
    elif command -v xvfb-run >/dev/null; then xvfb-run -a -s "-screen 0 1600x900x24" "$@"
    else "$@"; fi
}

job_linux() {
    note "linux"
    [ "$HOST" = "Linux" ] || { record linux SKIP "not a Linux host"; return; }
    local b=build/ci-linux
    run_logged "$LOGDIR/linux-configure.log" cmake -S . -B "$b" -G Ninja -DCMAKE_BUILD_TYPE=Release \
        || { record linux FAIL "configure (see $LOGDIR/linux-configure.log)"; return; }
    run_logged "$LOGDIR/linux-build.log" cmake --build "$b" -j "$JOBS" \
        || { record linux FAIL "build (see $LOGDIR/linux-build.log)"; return; }
    if run_logged "$LOGDIR/linux-test.log" with_display ctest --test-dir "$b" -j "$JOBS" --output-on-failure; then
        record linux PASS "$(grep -E 'tests passed' "$LOGDIR/linux-test.log" | tail -1)"
    else
        record linux FAIL "tests (see $LOGDIR/linux-test.log)"
    fi
}

job_windows_native() {
    note "windows (MSVC via scripts/build.ps1)"
    local ps=powershell; command -v pwsh >/dev/null && ps=pwsh
    if run_logged "$LOGDIR/windows-msvc.log" "$ps" -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 release -Test; then
        record windows PASS "MSVC build + ctest (windows-release preset)"
    else
        record windows FAIL "see $LOGDIR/windows-msvc.log"
    fi
}

job_windows() {
    if [ "$HOST" = "Windows" ]; then job_windows_native; return; fi
    note "windows (MinGW-w64 cross build + Wine)"
    if ! command -v x86_64-w64-mingw32-g++-posix >/dev/null && ! command -v x86_64-w64-mingw32-g++ >/dev/null; then
        record windows SKIP "no MinGW-w64 (Debian/Ubuntu: apt install g++-mingw-w64-x86-64-posix)"; return
    fi
    local b=build/ci-windows-mingw
    run_logged "$LOGDIR/windows-configure.log" cmake -S . -B "$b" -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/mingw-w64.cmake \
        || { record windows FAIL "configure (see $LOGDIR/windows-configure.log)"; return; }
    run_logged "$LOGDIR/windows-build.log" cmake --build "$b" -j "$JOBS" \
        || { record windows FAIL "build (see $LOGDIR/windows-build.log)"; return; }
    if ! command -v wine >/dev/null; then
        record windows PASS "build only (install wine to also run the tests: apt install wine64 wine)"; return
    fi
    export WINEDEBUG=-all
    export WINEPREFIX="${FA_WINEPREFIX:-$ROOT/build/ci-wineprefix}"
    # Initialise the prefix under the same (virtual) display the tests use, then wait for the
    # wineserver to exit: a server started without a display makes D3D11 (wined3d) unavailable.
    if [ ! -d "$WINEPREFIX" ]; then with_display wineboot -i >/dev/null 2>&1 || true; fi
    wineserver -w 2>/dev/null || true
    local failed=() passed=0
    while IFS= read -r exe; do
        local name; name="$(basename "$exe" .exe)"
        wineserver -w 2>/dev/null || true
        if with_display wine "$exe" >"$LOGDIR/windows-$name.log" 2>&1 \
            && tr -d '\r' <"$LOGDIR/windows-$name.log" | grep -q 'Status: SUCCESS'; then
            passed=$((passed + 1))
        else
            failed+=("$name"); tr -d '\r' <"$LOGDIR/windows-$name.log" | grep -A8 'ERROR' | head -20
        fi
    done < <(find "$b" -name 'fa_test_*.exe' | sort)
    # End-to-end: the Windows CLI creates, validates, tests and renders a project (D3D11 readback).
    local smoke="$ROOT/build/ci-windows-smoke"; rm -rf "$smoke"; mkdir -p "$smoke"
    local cli="$ROOT/$b/tools/cli/factoria.exe"
    wineserver -k 2>/dev/null || true; wineserver -w 2>/dev/null || true
    # One display for the whole sequence: the wineserver must be started with it (see above).
    if with_display bash -c "cd '$smoke' && wine '$cli' new game --template 2d-platformer && wine '$cli' validate game \
         && wine '$cli' test game \
         && wine '$cli' run game --headless --frames 30 --screenshot-at 29 --screenshot-pattern shot.png \
         && test -s shot.png" >"$LOGDIR/windows-cli-smoke.log" 2>&1 \
       && ! grep -q 'No renderer' "$LOGDIR/windows-cli-smoke.log"; then
        passed=$((passed + 1))
    else
        failed+=("cli-smoke"); tail -n 20 "$LOGDIR/windows-cli-smoke.log"
    fi
    if [ ${#failed[@]} -eq 0 ]; then record windows PASS "$passed suites under Wine (incl. CLI smoke)"
    else record windows FAIL "failed: ${failed[*]} (logs in $LOGDIR)"; fi
}

job_android() {
    note "android"
    if [ -z "${ANDROID_NDK_HOME:-}" ] || [ ! -f "$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" ]; then
        record android SKIP "set ANDROID_NDK_HOME to an NDK r27+ (Android Studio > SDK Manager > NDK)"; return
    fi
    if run_logged "$LOGDIR/android.log" bash -c "cmake --preset android-arm64 && cmake --build --preset android-arm64 --target factoria_player -j $JOBS"; then
        record android PASS "factoria_player arm64-v8a"
    else
        record android FAIL "see $LOGDIR/android.log"
    fi
}

job_sniper() {
    note "sniper"
    [ "$HOST" = "Linux" ] || { record sniper SKIP "not a Linux host"; return; }
    if ! command -v docker >/dev/null && ! command -v podman >/dev/null; then
        record sniper SKIP "needs Docker or Podman"; return
    fi
    if run_logged "$LOGDIR/sniper.log" ./scripts/build-sniper.sh all; then
        record sniper PASS "linux-sniper build, symbol versions, run in the sniper runtime"
    else
        record sniper FAIL "see $LOGDIR/sniper.log"
    fi
}

job_web() {
    note "web"
    if [ -z "${EMSDK:-}" ] || [ ! -f "$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" ]; then
        record web SKIP "set EMSDK: source emsdk_env.sh of an activated Emscripten SDK 6.0.10 (docs/BUILDING.md, \"Web\")"; return
    fi
    local major; major="$(node --version 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/')"
    if [ -z "$major" ] || [ "$major" -lt 22 ]; then record web SKIP "needs Node 22+ (the emsdk ships one: \$EMSDK/node/*/bin)"; return; fi
    if [ -z "${CHROME_BIN:-}" ] && ! command -v google-chrome >/dev/null && ! command -v chromium >/dev/null \
        && ! command -v chromium-browser >/dev/null && ! command -v chrome >/dev/null; then
        record web SKIP "needs Chrome or Chromium (or CHROME_BIN=/path/to/chrome)"; return
    fi
    run_logged "$LOGDIR/web-player.log" bash -c "cmake --preset web-release && cmake --build --preset web-release -j $JOBS" \
        || { record web FAIL "web player (see $LOGDIR/web-player.log)"; return; }
    local b=build/ci-web-tools
    run_logged "$LOGDIR/web-cli.log" bash -c "cmake -S . -B $b -G Ninja -DCMAKE_BUILD_TYPE=Release -DFA_BUILD_EDITOR=OFF -DFA_BUILD_TESTS=OFF \
        && cmake --build $b --target factoria -j $JOBS" \
        || { record web FAIL "factoria CLI (see $LOGDIR/web-cli.log)"; return; }
    if run_logged "$LOGDIR/web-smoke.log" ./scripts/web-smoke.sh "$b/tools/cli/factoria" build/web-release/player build/ci-web-smoke; then
        record web PASS "web player, export, zip check, first frames in headless Chrome"
    else
        record web FAIL "see $LOGDIR/web-smoke.log"
    fi
}

job_macos() {
    note "macos"
    [ "$HOST" = "Darwin" ] || { record macos SKIP "needs a Mac (run this script on macOS)"; return; }
    if run_logged "$LOGDIR/macos.log" bash -c "cmake --preset macos-release && cmake --build --preset macos-release -j $JOBS && ctest --preset macos-release -j $JOBS"; then
        record macos PASS "build + ctest"
    else
        record macos FAIL "see $LOGDIR/macos.log"
    fi
}

job_ios() {
    note "ios"
    if [ "$HOST" != "Darwin" ] || ! command -v xcodebuild >/dev/null; then
        record ios SKIP "needs a Mac with Xcode"; return
    fi
    if run_logged "$LOGDIR/ios.log" bash -c "cmake --preset ios-simulator -DFA_GAME_PROJECT_DIR=$ROOT/templates/2d-platformer && cmake --build --preset ios-simulator --target factoria_player -- -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO"; then
        record ios PASS "factoria_player.app (simulator)"
    else
        record ios FAIL "see $LOGDIR/ios.log"
    fi
}

ALL=(linux windows android web macos ios)
SELECTED=("$@")
[ ${#SELECTED[@]} -eq 0 ] && SELECTED=("${ALL[@]}")
for j in "${SELECTED[@]}"; do
    case "$j" in
        linux|windows|android|web|macos|ios|sniper) "job_$j" ;;
        *) echo "unknown job '$j' (valid: ${ALL[*]} sniper)"; exit 2 ;;
    esac
done

note "summary ($(date -u +%Y-%m-%dT%H:%M:%SZ), $(git rev-parse --short HEAD 2>/dev/null))"
printf '%s\n' "${RESULTS[@]}"
exit $FAILED
