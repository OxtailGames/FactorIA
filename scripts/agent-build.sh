#!/usr/bin/env bash
# Build (and test) a Ninja Debug tree from any shell, printing only what matters: the Linux and macOS twin of
# scripts/agent-build.ps1, made for AI agents. See docs/design/BUILDING_SCRIPTS.md, "Linux and macOS, short output".
#
#   scripts/agent-build.sh <build dir> [--target t1,t2] [--test | --tests REGEX] [--examples | --examples-only]
#                                      [--jobs N] [--ctest-jobs N] [--wait-s N]
#   scripts/agent-build.sh <build dir> --wait | --status | --stop
#
# The work runs as a job detached from the calling shell, and the command waits for it for at most --wait-s seconds
# (default 100: agent harnesses stop or background a command after two or three minutes, and the agent then spends its
# turns polling). A job that is still running prints one `agent-build: RUNNING ...` line and exits with status 3: call
# `--wait` until the last line is `agent-build: DONE ok` (status 0), `agent-build: DONE FAILED` (status 1) or
# `agent-build: DONE INCOMPLETE` (status 77: nothing failed, but tests were left out, see below). One job per build dir;
# `--status` reports without waiting and `--stop` ends the job.
#
# Output: errors, each distinct warning of the files the branch changes compared with origin/main (the warnings of the
# rest of the tree are counted; those of external/ are left out), every failing test with its output (at most 80
# lines, without the engine log lines of a doctest program), ctest's summary and the time of each step, with paths
# relative to the checkout. The full output goes to agent-configure.log, agent-build.log and agent-ctest.log in the
# build dir. --test runs every test, --tests the ones matching a regex (ctest -R). --examples adds a Release
# build of factoria in <build dir>-release and `ctest -L example` (the example games' tests, disabled in a Debug
# build); --test --examples is the full check before a push, --examples-only skips the Debug part.
#
# The Debug tree is compiled with `-O1 -g1` instead of CMake's `-g` (FA_AGENT_DEBUG_FLAGS, read when the build dir is
# first configured): assertions stay on and a crash still names functions and lines, and the Debug suite takes less
# than half the time. For a debugger session configure a plain Debug tree, or pass FA_AGENT_DEBUG_FLAGS=-g.
#
# A Mac whose displays are all asleep (lid closed, or idle for longer than the display sleep time) draws no frame in any
# window, so a test that opens one waits until its time limit (five minutes each). Those tests (ctest label `window`)
# are left out then and listed as SKIPPED, never as passed; FA_TEST_NO_WINDOW=1 is set for the others (a test case that
# runs a windowed program skips that step and is listed too), and the job ends as `DONE INCOMPLETE`. Wake the display
# and run the listed tests, or leave them to CI. FA_AGENT_WINDOW_TESTS=run runs them whatever the display says (and sets
# FA_TEST_IGNORE_DISPLAY_SLEEP=1). A display that falls asleep DURING the run, or a plain ctest, is caught by the
# programs themselves: after ~10 s without a frame and with every display asleep they exit 77, ctest's SKIP_RETURN_CODE
# of those tests, and the script lists what ctest reports as Skipped in the same note.
#
# At most three jobs build or test at once on one machine (FA_AGENT_MAX_JOBS), counting every checkout and worktree of
# this user: one more waits for a free slot and reports `RUNNING (waiting for a build slot ...)` meanwhile.
#
# Environment: FA_AGENT_MAX_JOBS (jobs at once on this machine, default 3), FA_AGENT_JOBS (build jobs, default the CPU
# count divided by FA_AGENT_MAX_JOBS, 2 to 8), FA_AGENT_CTEST_JOBS (parallel tests, default 3: some tests are timing
# sensitive), FA_AGENT_SLOTS_DIR, FA_AGENT_WAIT_S, FA_AGENT_DEBUG_FLAGS, FA_AGENT_WINDOW_TESTS. bash 3.2 (macOS) runs
# this file: no associative arrays, no mapfile.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SELF="$ROOT/scripts/agent-build.sh"
OPTIONS="--target t1,t2  --test  --tests REGEX  --examples  --examples-only  --jobs N  --ctest-jobs N  --wait-s N"
OPTIONS="$OPTIONS  --wait  --status  --stop"

usage() {
    echo "usage: scripts/agent-build.sh <build dir> [$OPTIONS]"
    echo "       e.g. scripts/agent-build.sh build/agent-<name> --target fa_test_core --tests core"
    exit "${1:-2}"
}
die() {  # die <what is wrong> [<how to fix it>]
    echo "error: $1" >&2
    [ -n "${2:-}" ] && echo "hint: $2" >&2
    exit 2
}

[ $# -ge 1 ] || usage
case "$1" in
    -h|--help) usage 0 ;;
    -*) die "the first argument is the build dir, got '$1'" "scripts/agent-build.sh build/agent-<name> --test" ;;
esac
BUILD_DIR="$1"; shift
case "$BUILD_DIR" in /*) ;; *) BUILD_DIR="$ROOT/$BUILD_DIR" ;; esac
while [ "${BUILD_DIR%/}" != "$BUILD_DIR" ]; do BUILD_DIR="${BUILD_DIR%/}"; done
# Ninja names the sources relative to a build dir inside the checkout: "../../" for build/agent-<name>.
UP=""
case "$BUILD_DIR" in
    "$ROOT"/*)
        UP="$(printf '%s\n' "${BUILD_DIR#"$ROOT"/}" |
            awk -F/ '{ for (i = 1; i <= NF; i++) if ($i != "") printf "../" }')"
        ;;
esac

ncpu="$( (nproc || sysctl -n hw.ncpu) 2>/dev/null || echo 4)"
# At most MAX_JOBS jobs build or test at once on this machine, whatever checkout or build dir they come from: twelve
# agents building side by side (load 108 on a 10-core Mac) left the computer unusable. A job past the limit waits for a
# slot (it shows as `RUNNING (waiting for a build slot ...)`). Each job's share of the cores is its default -j.
MAX_JOBS="${FA_AGENT_MAX_JOBS:-3}"
case "$MAX_JOBS" in ''|*[!0-9]*|0) MAX_JOBS=3 ;; esac
SLOTS_DIR="${FA_AGENT_SLOTS_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/factoria/agent-build-slots}"
share=$(( (ncpu + MAX_JOBS - 1) / MAX_JOBS ))
[ $share -lt 2 ] && share=2
JOBS="${FA_AGENT_JOBS:-$(( share < 8 ? share : 8 ))}"
CTEST_JOBS="${FA_AGENT_CTEST_JOBS:-3}"
WAIT_S="${FA_AGENT_WAIT_S:-100}"
DEBUG_FLAGS="${FA_AGENT_DEBUG_FLAGS:--O1 -g1}"
TARGETS=""; DO_TEST=0; TESTS_RE=""; EXAMPLES=0; EXAMPLES_ONLY=0; MODE=start
ORIG=("$@")

value() { [ $# -ge 2 ] || die "$1 needs a value" "options: $OPTIONS"; }
while [ $# -gt 0 ]; do
    case "$1" in
        --target)        value "$@"; TARGETS="$2"; shift 2 ;;
        --test)          DO_TEST=1; shift ;;
        --tests)         value "$@"; TESTS_RE="$2"; DO_TEST=1; shift 2 ;;
        --examples)      EXAMPLES=1; shift ;;
        --examples-only) EXAMPLES=1; EXAMPLES_ONLY=1; shift ;;
        --jobs)          value "$@"; JOBS="$2"; shift 2 ;;
        --ctest-jobs)    value "$@"; CTEST_JOBS="$2"; shift 2 ;;
        --wait-s)        value "$@"; WAIT_S="$2"; shift 2 ;;
        --wait)          MODE=wait; shift ;;
        --status)        MODE=status; shift ;;
        --stop)          MODE=stop; shift ;;
        --run-job)       MODE=job; shift ;;  # internal: the detached job itself
        -h|--help)       usage 0 ;;
        *) die "unknown option '$1'" "options: $OPTIONS" ;;
    esac
done
for n in "$JOBS" "$CTEST_JOBS" "$WAIT_S"; do
    case "$n" in ''|*[!0-9]*) die "--jobs, --ctest-jobs and --wait-s take a whole number, got '$n'" ;; esac
done
# What the job does, to tell "the same job again" (wait for it) from another one (refused while this one runs).
SIG="target=${TARGETS:-all} test=$DO_TEST tests=${TESTS_RE:-all} examples=$EXAMPLES examples-only=$EXAMPLES_ONLY"

PID_FILE="$BUILD_DIR/agent-job.pid"      # the job's process (and process group) id
ARGS_FILE="$BUILD_DIR/agent-job.args"    # the arguments it was started with
PHASE_FILE="$BUILD_DIR/agent-job.phase"  # line 1: the step it is on; line 2: the log that step writes
OUT_FILE="$BUILD_DIR/agent-job.out"      # the short report, printed when the job ends
RC_FILE="$BUILD_DIR/agent-job.rc"        # its exit status; written last, so its presence means "finished"

job_running() {
    [ -f "$PID_FILE" ] && [ ! -f "$RC_FILE" ] || return 1
    local pid
    pid="$(cat "$PID_FILE" 2>/dev/null)"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

# ---------------------------------------------------------------------------------------------------------------------
# Build slots, shared by every job of this user on this machine: $SLOTS_DIR/slot-<n> is a directory (mkdir is atomic)
# holding the pid and build dir of the job that owns it. A slot whose job is gone (killed, machine restarted) is taken
# over. The job holds its slot from configure to the last test, and frees it when it exits.

SLOT=""
slot_owner_alive() {  # slot_owner_alive <slot dir>
    local pid
    pid="$(sed -n 1p "$1/owner" 2>/dev/null)"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}
release_slot() {
    [ -n "$SLOT" ] && [ "$(sed -n 1p "$SLOT/owner" 2>/dev/null)" = "$$" ] && rm -rf "$SLOT"
    SLOT=""
}
acquire_slot() {
    local i dir busy waited=0
    mkdir -p "$SLOTS_DIR" 2>/dev/null || { say "note: cannot create $SLOTS_DIR: building without the job limit"; return 0; }
    while :; do
        i=1
        while [ $i -le "$MAX_JOBS" ]; do
            dir="$SLOTS_DIR/slot-$i"
            if mkdir "$dir" 2>/dev/null; then
                printf '%s\n%s\n' "$$" "$BUILD_DIR" > "$dir/owner"
                SLOT="$dir"
                [ $waited = 1 ] && say "waited $((SECONDS - T_WAIT)) s for a build slot ($MAX_JOBS jobs at most)"
                return 0
            fi
            # A slot left by a job that no longer runs (or that is still being written: give it a moment).
            if [ -f "$dir/owner" ] && ! slot_owner_alive "$dir"; then rm -rf "$dir"; continue; fi
            if [ ! -f "$dir/owner" ] && [ -n "$(find "$dir" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
                rm -rf "$dir"; continue
            fi
            i=$((i + 1))
        done
        if [ $waited = 0 ]; then waited=1; T_WAIT=$SECONDS; fi
        busy="$(for dir in "$SLOTS_DIR"/slot-*; do sed -n 2p "$dir/owner" 2>/dev/null; done | relative |
            tr '\n' ' ' | sed 's/ *$//')"
        set_phase "waiting for a build slot ($MAX_JOBS jobs at most; running: ${busy:-?})" ""
        sleep 5
    done
}

# ---------------------------------------------------------------------------------------------------------------------
# The job (detached): writes the short report to $OUT_FILE.

say() { printf '%s\n' "$*" >> "$OUT_FILE"; }
set_phase() { printf '%s\n%s\n' "$1" "$2" > "$PHASE_FILE"; }

# Paths inside the checkout are shown relative to it (engine/core/src/x.cpp:12:5), whether the tool wrote them absolute
# or relative to the build dir: shorter, and what an editor tool takes.
relative() {
    awk -v root="$ROOT/" -v up="$UP" '
        function strip(s, prefix, at_path_start,    out, i) {
            out = ""
            while ((i = index(s, prefix)) > 0) {
                if (at_path_start && i > 1 && substr(s, i - 1, 1) ~ /[A-Za-z0-9_.\/-]/) {
                    out = out substr(s, 1, i + length(prefix) - 1)
                } else {
                    out = out substr(s, 1, i - 1)
                }
                s = substr(s, i + length(prefix))
            }
            return out s
        }
        {
            $0 = strip($0, root, 0)
            if (up != "") $0 = strip($0, up, 1)
            print
        }'
}

# The files this branch and its working tree change compared with origin/main, one per line (nothing without git).
changed_files() {
    local base
    base="$(git -C "$ROOT" merge-base HEAD origin/main 2>/dev/null)" || return 0
    git -C "$ROOT" diff --name-only "$base" 2>/dev/null
    git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null
}

# GPU and window tests need a display on Linux: Xvfb when there is none (as scripts/test-all.sh).
with_display() {
    if [ "$(uname -s)" = "Linux" ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] \
        && command -v xvfb-run >/dev/null 2>&1; then
        xvfb-run -a -s "-screen 0 1280x720x24" "$@"
    else
        "$@"
    fi
}

# True on a Mac that has displays and every one of them is asleep: no window gets a frame there.
displays_asleep() {
    [ "$(uname -s)" = Darwin ] || return 1
    [ "${FA_AGENT_WINDOW_TESTS:-auto}" = run ] && return 1
    local info total asleep
    info="$(system_profiler SPDisplaysDataType 2>/dev/null)" || return 1
    total="$(printf '%s\n' "$info" | grep -c 'Resolution:')"
    asleep="$(printf '%s\n' "$info" | grep -c 'Display Asleep: Yes')"
    [ "$total" -gt 0 ] && [ "$asleep" -ge "$total" ]
}

configure() {  # configure <dir> <Debug|Release>: only the first time
    local dir="$1" type="$2" log="$1/agent-configure.log" t0=$SECONDS
    [ -f "$dir/build.ninja" ] && return 0
    mkdir -p "$dir"
    local what="$type" lang
    local args=(-S "$ROOT" -B "$dir" -G Ninja "-DCMAKE_BUILD_TYPE=$type")
    if [ "$type" = Debug ]; then
        # Every agent tree gets the same flags, so they all share ccache's entries (a plain `-g` tree has its own).
        what="$type, $DEBUG_FLAGS"
        for lang in C CXX OBJC OBJCXX; do args+=("-DCMAKE_${lang}_FLAGS_DEBUG=$DEBUG_FLAGS"); done
    fi
    set_phase "configure ($what)" "$log"
    # No compiler launcher here: CMakeLists.txt finds ccache itself and passes it the settings that let every checkout
    # and worktree share one cache.
    if ! cmake "${args[@]}" > "$log" 2>&1; then
        say "configure ($what): FAILED. Full log: $log"
        if grep -q 'CMake Error' "$log"; then
            grep -A 6 'CMake Error' "$log" | head -n 40 | relative >> "$OUT_FILE"
        else
            tail -n 40 "$log" | relative >> "$OUT_FILE"
        fi
        return 1
    fi
    say "configure ($what): ok ($((SECONDS - t0)) s, $dir)"
}

ERROR_RE=': (fatal )?error[: ]|^FAILED: |CMake Error|ninja: error|clang(\+\+)?: error|collect2: error'
ERROR_RE="$ERROR_RE"'|^ld: |^Undefined symbols|^  "[^"]*", referenced from:|undefined reference to'
ERROR_RE="$ERROR_RE"'|multiple definition of|duplicate symbol'

build() {  # build <dir> <label> [target...]
    local dir="$1" label="$2"; shift 2
    local log="$dir/agent-build.log" t0=$SECONDS rc=0 errors warnings count own own_count
    local cmd=(cmake --build "$dir" -j "$JOBS")
    [ $# -gt 0 ] && cmd+=(--target "$@")
    set_phase "$label" "$log"
    "${cmd[@]}" > "$log" 2>&1 || rc=$?
    if [ $rc -ne 0 ]; then
        say "$label: FAILED (exit $rc, $((SECONDS - t0)) s). Full log: $log"
        errors="$(grep -E "$ERROR_RE" "$log" | awk '!seen[$0]++')"
        if [ -n "$errors" ]; then
            printf '%s\n' "$errors" | head -n 40 | relative >> "$OUT_FILE"
            count="$(printf '%s\n' "$errors" | wc -l | tr -d ' ')"
            [ "$count" -gt 40 ] && say "... $((count - 40)) more error lines in the log"
        else
            tail -n 40 "$log" | relative >> "$OUT_FILE"
        fi
    else
        say "$label: ok ($((SECONDS - t0)) s)"
    fi
    # The compiler repeats a header's warning once per translation unit, and external/ is never edited: noise. The
    # warnings of the files this branch changes are shown; those of the rest of the tree are only counted.
    warnings="$(grep -E ': warning: ' "$log" | grep -v '/external/' | relative | awk '!seen[$0]++')"
    if [ -n "$warnings" ]; then
        changed_files > "$dir/agent-changed.txt"
        if [ -s "$dir/agent-changed.txt" ]; then
            own="$(printf '%s\n' "$warnings" | awk 'NR == FNR { own[$0] = 1; next }
                { path = $0; sub(/:.*/, "", path); if (path in own) print }' "$dir/agent-changed.txt" -)"
            count="$(printf '%s\n' "$warnings" | wc -l | tr -d ' ')"
            if [ -n "$own" ]; then
                own_count="$(printf '%s\n' "$own" | wc -l | tr -d ' ')"
                say "$own_count distinct warning line(s) in the files this branch changes:"
                printf '%s\n' "$own" | head -n 30 >> "$OUT_FILE"
                [ "$own_count" -gt 30 ] && say "... $((own_count - 30)) more in the log"
                count=$((count - own_count))
            fi
            [ "$count" -gt 0 ] && say "$count distinct warning line(s) in files this branch does not change" \
                "(grep ': warning: ' $log)"
        else
            count="$(printf '%s\n' "$warnings" | wc -l | tr -d ' ')"
            say "$count distinct warning line(s):"
            printf '%s\n' "$warnings" | head -n 15 >> "$OUT_FILE"
        fi
    fi
    return $rc
}

# What a test run could not do without a window: window_note <label> <asleep 0|1> <tests left out> <steps skipped>
# <the tests those steps are in> <the tests that ended themselves with 77>.
window_note() {
    local label="$1" asleep="$2" tests="$3" steps="$4" entries="$5" own="${6:-}" note again
    note="$label: SKIPPED (not passed):"
    if [ -n "$own" ]; then
        # The program's own watchdog (engine/platform/src/display_watchdog.h) found no frame and every display asleep:
        # the test ended with 77, ctest's SKIP_RETURN_CODE. The display went to sleep after the start-of-run check, or
        # this is a plain ctest.
        note="$note $(printf '%s\n' "$own" | wc -w | tr -d ' ') test(s) that ended themselves with 77 ($own): every"
        note="$note display of this Mac was asleep, so no window got a frame. Wake the display and run them again"
        # shellcheck disable=SC2086  # one name per word
        again="$(printf '%s\n' $own | sort -u | tr '\n' '|' | sed 's/|*$//')"
        note="$note (--tests '^($again)\$'), or say in your report that only CI runs them."
        [ -n "$tests$steps" ] || { printf '%s\n' "$note"; return; }
        note="$note Also:"
    fi
    if [ -n "$tests" ]; then
        note="$note $(printf '%s\n' "$tests" | wc -w | tr -d ' ') test(s) that open a window ($tests);"
    fi
    if [ -n "$steps" ]; then
        note="$note the step that runs a windowed program, in $(printf '%s\n' "$steps" | wc -w | tr -d ' ') test"
        note="$note case(s) ($steps);"
    fi
    if [ "$asleep" = 1 ]; then
        note="${note%;}. Every display of this Mac is asleep (lid closed or idle), so a window gets no frame. Wake the"
        note="$note display and run them again"
        # shellcheck disable=SC2086  # one name per word
        again="$(printf '%s\n' $tests $entries | sort -u | tr '\n' '|' | sed 's/^|*//; s/|*$//')"
        [ -n "$again" ] && note="$note (--tests '^($again)\$')"
        note="$note, or say in your report that only CI runs them."
    else
        note="${note%;}. FA_TEST_NO_WINDOW is set in the environment: unset it and run them again."
    fi
    printf '%s\n' "$note"
}

# Status 0: every test passed. 1: a test failed or none matched. 77: none failed, but tests that open a window were
# left out (displays_asleep) or a test case skipped the step that runs a windowed program (FA_TEST_NO_WINDOW).
run_ctest() {  # run_ctest <dir> <label> <log> <ctest arguments...>
    local dir="$1" label="$2" log="$3"; shift 3
    local t0=$SECONDS rc=0 disabled asleep=0 skipped="" steps="" entries="" own=""
    set_phase "$label" "$log"
    # FA_AGENT_WINDOW_TESTS=run: the windowed programs do not skip themselves either (display_watchdog.h)
    [ "${FA_AGENT_WINDOW_TESTS:-auto}" = run ] && export FA_TEST_IGNORE_DISPLAY_SLEEP=1
    if displays_asleep; then
        # No window gets a frame. The tests that open one (label `window`) are left out; a test case of another test
        # that runs a windowed program skips that step and says so (FA_TEST_NO_WINDOW), which is counted below.
        asleep=1
        export FA_TEST_NO_WINDOW=1
        skipped="$(ctest --test-dir "$dir" -N "$@" -L '^window$' 2>/dev/null | sed -n 's/^ *Test *#[0-9]*: *//p' |
            tr '\n' ' ' | sed 's/ *$//')"
        if [ -n "$skipped" ]; then
            set -- "$@" -LE '^window$'
            if ctest --test-dir "$dir" -N "$@" 2>/dev/null | grep -q '^Total Tests: 0$'; then
                : > "$log"
                say "$(window_note "$label" 1 "$skipped" "")"
                return 77
            fi
        fi
    fi
    with_display ctest --test-dir "$dir" --output-on-failure "$@" > "$log" 2>&1 || rc=$?
    # A failing test's result line (***Failed, ***Exception, ***Timeout, ***Not Run) is followed by its output, up to
    # the next "Start" or result line (tests run in parallel) or the summary. A doctest program's output is its failed
    # checks plus the engine log lines of every case that provokes an error on purpose: those log lines are left out.
    # At most 80 lines of each test: the first 40 and the last 40 (the first failures, and the summary or the crash).
    awk -v cap=80 -v log_path="$log" '
        function flush(    i, n, hidden, doctest) {
            if (!collecting) return
            collecting = 0
            doctest = 0
            for (i = 1; i <= count; i++) if (index(lines[i], "[doctest]") == 1) { doctest = 1; break }
            n = 0; hidden = 0
            for (i = 1; i <= count; i++) {
                if (doctest && lines[i] ~ /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\.[0-9]+ \[ *[0-9.]+\] /) {
                    hidden++
                    continue
                }
                kept[++n] = lines[i]
            }
            print result
            if (n <= cap) {
                for (i = 1; i <= n; i++) print kept[i]
            } else {
                for (i = 1; i <= cap / 2; i++) print kept[i]
                printf "... %d lines of this test skipped (%s) ...\n", n - cap, log_path
                for (i = n - cap / 2 + 1; i <= n; i++) print kept[i]
            }
            if (hidden) printf "(%d engine log lines of this test are not shown: %s)\n", hidden, log_path
        }
        /^ *Start +[0-9]+: / || /^ *[0-9]+\/[0-9]+ Test +#[0-9]+: / || /^[0-9]+% tests passed/ { flush() }
        /^ *[0-9]+\/[0-9]+ Test +#[0-9]+: .*\*\*\*/ && !/\*\*\*Not Run \(Disabled\)/ && !/\*\*\*Skipped/ {
            collecting = 1; result = $0; count = 0
            next
        }
        collecting { lines[++count] = $0 }
        END { flush() }
    ' "$log" | relative >> "$OUT_FILE"
    grep -E '^[0-9]+% tests passed|^Total Test time' "$log" >> "$OUT_FILE"
    grep -E '^[[:space:]]+[0-9]+ - .+\(' "$log" | grep -v -E '\((Disabled|Skipped)\)' >> "$OUT_FILE"  # the failed tests
    disabled="$(grep -c -E '^[[:space:]]+[0-9]+ - .+\(Disabled\)' "$log")"
    if [ "${disabled:-0}" -gt 0 ]; then
        say "$disabled tests are disabled in this build (the example games' tests run in Release: --examples)"
    fi
    if grep -q 'No tests were found' "$log"; then
        say "$label: FAILED: no test matches (the names: ctest --test-dir $dir -N)"
        return 1
    fi
    if [ -n "${FA_TEST_NO_WINDOW:-}" ]; then
        # ctest keeps what every test printed, the passing ones too: the places (file:line) where a test case said it
        # skipped its windowed step.
        steps="$(grep -o '[^/\\ ]*:[0-9]*: MESSAGE: FA_TEST_NO_WINDOW is set' "$dir/Testing/Temporary/LastTest.log" \
            2>/dev/null | sed 's/: MESSAGE: .*//' | sort -u | tr '\n' ' ' | sed 's/ *$//')"
        # And the tests they are in: every test's part of that log starts with "<n>/<total> Test: <name>".
        entries="$(awk '/^[0-9]+\/[0-9]+ Test: / { name = $3 }
            /: MESSAGE: FA_TEST_NO_WINDOW is set/ && name != "" { print name }' \
            "$dir/Testing/Temporary/LastTest.log" 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/ *$//')"
    fi
    # Tests that ended themselves with 77 (SKIP_RETURN_CODE, the display watchdog): ctest lists them as (Skipped).
    own="$(grep -E '^[[:space:]]+[0-9]+ - .+\(Skipped\)' "$log" | sed -E 's/^[[:space:]]*[0-9]+ - //; s/ \(Skipped\)$//' |
        sort -u | tr '\n' ' ' | sed 's/ *$//')"
    [ -n "$skipped$steps$own" ] && say "$(window_note "$label" $asleep "$skipped" "$steps" "$entries" "$own")"
    if [ $rc -ne 0 ]; then
        say "$label: FAILED ($((SECONDS - t0)) s). Full log: $log"
        return 1
    fi
    if [ -n "$skipped$steps$own" ]; then
        say "$label: everything else passed ($((SECONDS - t0)) s)"
        return 77
    fi
    say "$label: ok ($((SECONDS - t0)) s)"
}

debug_part() {
    local targets=() args=(-j "$CTEST_JOBS")
    configure "$BUILD_DIR" Debug || return 1
    [ -n "$TARGETS" ] && IFS=', ' read -r -a targets <<< "$TARGETS"
    build "$BUILD_DIR" build ${targets[@]+"${targets[@]}"} || return 1
    [ $DO_TEST = 1 ] || return 0
    [ -n "$TESTS_RE" ] && args+=(-R "$TESTS_RE")
    run_ctest "$BUILD_DIR" ctest "$BUILD_DIR/agent-ctest.log" "${args[@]}"  # the function's status: 0, 1 or 77
}

# Release build of the CLI and `ctest -L example`: the example games run the whole engine for minutes, so they are
# tests of an optimized build (FA_EXAMPLE_TESTS, docs/design/BUILDING_TESTS.md, "Running tests").
example_part() {
    local rel="$BUILD_DIR-release"
    configure "$rel" Release || return 1
    build "$rel" "release build" factoria || return 1
    run_ctest "$rel" "example tests" "$rel/agent-ctest.log" -L example -j "$CTEST_JOBS"
}

# The job's status: 1 when a part failed, 77 when none failed and one left tests out (run_ctest), else 0. The example
# part runs after a Debug part that left tests out, not after one that failed.
run_job() {
    local rc=0 part
    : > "$OUT_FILE"
    trap release_slot EXIT
    trap 'exit 143' TERM INT HUP
    acquire_slot
    if [ $EXAMPLES_ONLY = 0 ]; then
        debug_part; part=$?
        case $part in 0) ;; 77) rc=77 ;; *) rc=1 ;; esac
    fi
    if [ $rc != 1 ] && [ $EXAMPLES = 1 ]; then
        example_part; part=$?
        case $part in 0) ;; 77) rc=77 ;; *) rc=1 ;; esac
    fi
    echo $rc > "$RC_FILE.tmp" && mv "$RC_FILE.tmp" "$RC_FILE"
    exit $rc
}

# ---------------------------------------------------------------------------------------------------------------------
# The caller: starts the job, waits a bounded time, prints the report.

start_job() {
    mkdir -p "$BUILD_DIR" || die "cannot create the build dir $BUILD_DIR"
    if job_running; then
        if [ "$(cat "$ARGS_FILE" 2>/dev/null)" = "$SIG" ]; then
            echo "note: this job was already running in $BUILD_DIR: waiting for it"
            return 0
        fi
        die "another job is running in $BUILD_DIR ($(cat "$ARGS_FILE" 2>/dev/null))" \
            "wait for it (--wait), stop it (--stop) or use another build dir"
    fi
    rm -f "$RC_FILE" "$OUT_FILE" "$PHASE_FILE"
    printf '%s\n' "$SIG" > "$ARGS_FILE"
    # Job control for one command: the job gets its own process group, so --stop ends its whole tree (ninja, compilers,
    # tests) and whatever stops the caller's group leaves it alone.
    set -m
    nohup bash "$SELF" "$BUILD_DIR" ${ORIG[@]+"${ORIG[@]}"} --run-job < /dev/null > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    set +m
}

report() {  # report <seconds to wait>
    local deadline=$((SECONDS + $1)) phase log last
    [ -f "$PID_FILE" ] || die "no job has run in $BUILD_DIR" "start one: scripts/agent-build.sh <build dir> --test"
    while job_running && [ $SECONDS -lt $deadline ]; do sleep 0.5; done
    if [ -f "$RC_FILE" ]; then
        cat "$OUT_FILE" 2>/dev/null
        case "$(cat "$RC_FILE")" in
            0)  echo "agent-build: DONE ok"; exit 0 ;;
            77) echo "agent-build: DONE INCOMPLETE (nothing failed, but what is listed as SKIPPED did not run)"
                exit 77 ;;
        esac
        echo "agent-build: DONE FAILED"
        exit 1
    fi
    if job_running; then
        phase="$(sed -n 1p "$PHASE_FILE" 2>/dev/null)"
        log="$(sed -n 2p "$PHASE_FILE" 2>/dev/null)"
        last=""
        [ -n "$log" ] && [ -f "$log" ] && last="$(tail -n 1 "$log" | relative | cut -c1-120)"
        echo "agent-build: RUNNING (${phase:-starting}${last:+: $last})"
        echo "Not finished: run \`scripts/agent-build.sh <build dir> --wait\` until it prints DONE" \
            "(no sleep loops, no second build in this dir)."
        exit 3
    fi
    cat "$OUT_FILE" 2>/dev/null
    echo "agent-build: DONE FAILED (the job ended without a result: stopped or killed. Logs: $BUILD_DIR/agent-*.log)"
    exit 1
}

stop_job() {
    local pid i
    if ! job_running; then echo "agent-build: no job is running in $BUILD_DIR"; exit 0; fi
    pid="$(cat "$PID_FILE")"
    kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null
    for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$pid" 2>/dev/null
    rm -f "$PID_FILE"
    echo "agent-build: stopped the job in $BUILD_DIR"
}

case "$MODE" in
    job)    run_job ;;
    start)  start_job; report "$WAIT_S" ;;
    wait)   report "$WAIT_S" ;;
    status) report 0 ;;
    stop)   stop_job ;;
esac
