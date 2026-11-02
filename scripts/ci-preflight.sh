#!/usr/bin/env bash
# Everything to run before a push, in one command, so the PR passes GitHub CI the first time (docs/BUILDING.md,
# "Before a push"). It looks for what CI exercises and a developer machine does not: Windows file semantics, timing waits
# and budgets on loaded 4-vCPU VMs, MSVC/GCC-only compile errors, other platforms.
#
#   1. risk scan   the lines the branch adds (git diff BASE...HEAD) checked against a table of risky patterns; prints a
#                  checklist of file:line + why + what to check. Never fails the run, unless --strict.
#   2. test-all    scripts/test-all.sh (Debug build + Debug ctest, Release build + `ctest -L example`).
#   3. stress      the editor autotests and example tests the diff touches, repeated (ctest --repeat until-fail:N) while
#                  CPU burners keep every core busy, like a loaded CI VM. Needs the build dirs of step 2.
#   4. platforms   scripts/ci-local.sh jobs this host supports (Mac: macos ios web android; Linux: linux windows android
#                  web; they skip themselves when tooling is missing), then scripts/ci-docker.sh linux windows and
#                  scripts/ci-remote-windows.sh when they exist (exit 0 pass, 1 fail, 77 not set up -> SKIP).
#   5. summary     PASS/FAIL/SKIP and time per step; logs in build/ci-logs/preflight-<step>.log; exit 1 if a step failed.
#
#   scripts/ci-preflight.sh                  # everything
#   scripts/ci-preflight.sh --quick          # risk scan + test-all only
#   scripts/ci-preflight.sh --no-stress      # without step 3
#   scripts/ci-preflight.sh --no-platforms   # without step 4
#   scripts/ci-preflight.sh --no-test        # without step 2 (the build dirs of an earlier run are reused by step 3)
#   scripts/ci-preflight.sh --repeat 5       # stress repetitions (default 3)
#   scripts/ci-preflight.sh --base origin/dev  # diff base (default origin/main, else main)
#   scripts/ci-preflight.sh --strict         # a risk-scan finding fails the run
#   scripts/ci-preflight.sh --scan-only      # only the risk scan
#   scripts/ci-preflight.sh --plan           # only print which stress tests the diff selects
#
# Environment: FA_TEST_DEBUG_DIR, FA_TEST_RELEASE_DIR, FA_TEST_JOBS, FA_TEST_CTEST_JOBS go to test-all.sh and the stress
# pass uses the same dirs; FA_CI_JOBS goes to ci-local.sh. On Windows (Git Bash) only the risk scan runs: use
# `scripts\agent-build.ps1 build\agent-<name> -Test -Examples` for the build and tests there.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

BASE=""; REPEAT=3; STRICT=0; DO_TEST=1; DO_STRESS=1; DO_PLATFORMS=1; SCAN_ONLY=0; PLAN=0
while [ $# -gt 0 ]; do
    case "$1" in
        --quick) DO_STRESS=0; DO_PLATFORMS=0 ;;
        --no-stress) DO_STRESS=0 ;;
        --no-test) DO_TEST=0 ;;
        --no-platforms) DO_PLATFORMS=0 ;;
        --strict) STRICT=1 ;;
        --scan-only) SCAN_ONLY=1 ;;
        --plan) PLAN=1; DO_STRESS=0 ;;  # only print which stress tests the diff selects
        --repeat) shift; REPEAT="${1:-}" ;;
        --base) shift; BASE="${1:-}" ;;
        -h|--help) sed -n '2,/^set -uo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option '$1' (try -h)"; exit 2 ;;
    esac
    shift
done
case "$REPEAT" in ''|*[!0-9]*|0) echo "--repeat needs a positive number"; exit 2 ;; esac

HOST="$(uname -s)"
case "$HOST" in MINGW*|MSYS*|CYGWIN*) HOST=Windows ;; esac
NCPU="$( (nproc || sysctl -n hw.ncpu) 2>/dev/null || echo 4)"
LOGDIR="$ROOT/build/ci-logs"; mkdir -p "$LOGDIR"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fa-preflight.XXXXXX")"
DEBUG_DIR="${FA_TEST_DEBUG_DIR:-build/dev}"
RELEASE_DIR="${FA_TEST_RELEASE_DIR:-build/release}"
CTEST_JOBS="${FA_TEST_CTEST_JOBS:-3}"

# ---------------------------------------------------------------- cleanup: burners and children never outlive the script
BURNERS=()
kill_tree() {  # kill_tree <pid> [signal]: the process and everything below it, children first
    local c
    for c in $(pgrep -P "$1" 2>/dev/null); do kill_tree "$c" "${2:-TERM}"; done
    kill "-${2:-TERM}" "$1" 2>/dev/null
}
stop_burners() {
    local p
    for p in ${BURNERS[@]+"${BURNERS[@]}"}; do kill "$p" 2>/dev/null; wait "$p" 2>/dev/null; done
    BURNERS=()
}
cleanup() {
    trap '' INT TERM
    stop_burners
    local c
    local kids; kids="$(pgrep -P $$ 2>/dev/null)"
    for c in $kids; do kill_tree "$c"; done
    sleep 1
    for c in $kids; do kill_tree "$c" KILL; done   # whatever ignored TERM
    rm -rf "$TMP"
}
trap cleanup EXIT
trap 'echo; echo "interrupted"; exit 130' INT TERM

# ---------------------------------------------------------------- results
RESULTS=(); FAILED=0
note() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
record() {  # record <PASS|FAIL|SKIP> <name> <seconds> <detail>
    RESULTS+=("$(printf '%-5s %-26s %5s s  %s' "$1" "$2" "$3" "$4")")
    [ "$1" = FAIL ] && FAILED=1
    return 0
}
# run_step <name> <command...>: log in build/ci-logs/preflight-<name>.log, tail on failure; rc 77 = SKIP
run_step() {
    local name="$1"; shift
    local log="$LOGDIR/preflight-$name.log" t0=$SECONDS rc
    note "$name"
    # In the background + wait: bash runs a trap while it waits, but not while a foreground child runs (Ctrl-C or TERM
    # would leave the CPU burners alive until the child ends).
    "$@" >"$log" 2>&1 & wait $!; rc=$?
    local dt=$((SECONDS - t0))
    if [ $rc = 0 ]; then record PASS "$name" "$dt" "log: ${log#$ROOT/}"; return 0; fi
    if [ $rc = 77 ]; then record SKIP "$name" "$dt" "$(tail -n 1 "$log")"; return 0; fi
    echo "---- last lines of $log ----"; tail -n 40 "$log"
    record FAIL "$name" "$dt" "log: ${log#$ROOT/}"; return 1
}

# ---------------------------------------------------------------- 1. risk scan
# Base of the diff.
if [ -z "$BASE" ]; then
    for c in origin/main main; do git rev-parse --verify -q "$c" >/dev/null && { BASE="$c"; break; }; done
fi
if [ -z "$BASE" ] || ! git rev-parse --verify -q "$BASE" >/dev/null; then
    echo "base '$BASE' not found: run 'git fetch' or pass --base <ref>"; exit 2
fi

# The risk table. One rule per line, fields separated by ";;" (spaces around it are trimmed, empty fields allowed):
#   id ;; mode ;; files (ERE on the path) ;; added line (ERE, empty = any line) ;; header must include (or empty) ;; why + check
# mode: line = every matching line is listed, file = once per file with the number of lines.
# Add a rule by adding a line (awk ERE: no \b, \d; use [^A-Za-z0-9_] for a word edge).
RULES='
file-io ;; line ;; \.(cpp|h|hpp|mm|cc)$ ;; std::(ifstream|ofstream)|(std::filesystem|fs)::(rename|remove|remove_all|last_write_time) ;; ;; Windows refuses rename/remove/overwrite of a file another thread or process holds open (sharing violation), POSIX does not. Check who else may have it open, and prefer fs::write_bytes / the fa::fs helpers (they retry the replace on a sharing violation).
timing ;; line ;; (tests?/|autotest_|\.test\.|_test\.|tests\.) ;; sleep_for|usleep|[^A-Za-z_]Sleep\(|steady_clock|system_clock|high_resolution_clock|wait_until|timeout|Timeout|Date\.now|performance\.now ;; ;; Fixed waits, wall-clock timing and timeouts fail on a loaded 4-vCPU VM. Wait for the condition, not for a time; give wait_until generous timeouts counted in frames or CPU time.
autotest-wait ;; line ;; tools/editor/src/autotest_ ;; wait_until|wait_frames|frames *[<>=]+|[0-9]+ *\* *60 ;; ;; Editor autotest waits and frame budgets: CI renders with llvmpipe/WARP at a fraction of your frame rate. Run the entry under load (the stress pass does).
perf-budget ;; line ;; tools/cli/tests/perf/.*\.json$ ;; ;; ;; Perf/memory budget file. drawCalls and entities must match on every runner entry (compare with `factoria call --project examples/<name> perf.measure`); times and memory are only measured in CI, keep headroom.
platform-if ;; line ;; \.(cpp|h|hpp|mm|c|cc|cmake|txt)$ ;; ^\+?[ ]*#[ ]*(if|ifdef|ifndef|elif).*(_WIN32|__APPLE__|__ANDROID__|__EMSCRIPTEN__|__linux__|TARGET_OS_) ;; ;; A platform branch: check the other platforms (Windows, macOS, Linux, Android, Web) still compile and behave, i.e. there is an #else or a sibling _win32/_apple/_linux file.
shader-source ;; file ;; \.glsl$ ;; ;; ;; Shader source edited: run tools/shaders/compile_shaders.sh and commit the regenerated engine/render/src/shaders/*.glsl.h (checked below).
render-backend ;; line ;; (engine/render/|engine/platform/|tools/editor/src/.*(window|gpu|render)) ;; SOKOL_(GLCORE|GLES3|D3D11|METAL|WGPU)|SG_BACKEND|d3d11|ID3D11|MTL[A-Z]|\[MTL|glGet|glEnable|GL_[A-Z_]+ ;; ;; Backend-specific render code: GL, D3D11 and Metal differ (clip space, texture origin, formats, limits). Check the same picture on the others (ci-local windows/macos, the gpu tests).
inc-format ;; line ;; \.(h|hpp)$ ;; std::(format|format_to|formatted_size)[^A-Za-z_] ;; format ;; Header uses std::format without #include <format>: it only compiles where another header pulls it in (MSVC/GCC/libc++ differ).
inc-ranges ;; line ;; \.(h|hpp)$ ;; std::(ranges|views)::|std::(ranges|views)[^A-Za-z_:] ;; ranges ;; Header uses std::ranges/views without #include <ranges>.
inc-thread ;; line ;; \.(h|hpp)$ ;; std::(thread|jthread|this_thread)[^A-Za-z_] ;; thread ;; Header uses std::thread without #include <thread>.
inc-chrono ;; line ;; \.(h|hpp)$ ;; std::chrono ;; chrono ;; Header uses std::chrono without #include <chrono>.
inc-cstring ;; line ;; \.(h|hpp)$ ;; (std::)?(memcpy|memset|memcmp|strlen|strcmp|strncmp|strerror)\( ;; cstring ;; Header uses a <cstring> function without #include <cstring>.
format-width ;; line ;; \.(cpp|h|hpp|mm|c|cc)$ ;; %l[dux]|%ll[dux]|%z[dux]|%I64|[^A-Za-z0-9_]long[ ]+(long |int |unsigned )?[a-z_]+[ ]*[=;,)(] ;; ;; long is 32-bit on Windows and 64-bit elsewhere: %ld/long mismatch fails -Werror=format on one side. Use int64_t/uint64_t with PRId64 or cast, size_t with %zu.
crlf ;; line ;; \.(cpp|h|hpp|mm|cc|js|ts|sh|py)$ ;; getline|\.split\(|split_lines|find\(.\\n.\)|== *.\\n.|"\\n"[ ]*\) ;; ;; Text parsing: a file checked out or written on Windows has CRLF. Strip a trailing \r, and test with a CRLF input.
workflow ;; file ;; \.github/workflows/ ;; ;; ;; CI workflow edited: only the real run proves it. Check YAML syntax, cache keys, runner labels, and that every path/command exists on every runner OS.
'

DIFFFILE="$TMP/added.tsv"; NAMES="$TMP/names.txt"
git diff --name-only "$BASE"...HEAD >"$NAMES" 2>/dev/null || { echo "git diff $BASE...HEAD failed"; exit 2; }
# Added lines as file<TAB>line<TAB>text
git diff -U0 --no-color "$BASE"...HEAD | awk '
    /^\+\+\+ b\// { f = substr($0, 7); next }
    /^\+\+\+ /    { f = ""; next }
    /^@@ / { s = $3; sub(/^\+/, "", s); split(s, a, ","); n = a[1] + 0; next }
    /^\+/ && f != "" { printf "%s\t%d\t%s\n", f, n, substr($0, 2); n++ }
' | grep -v '^scripts/ci-preflight\.sh	' >"$DIFFFILE"

field() { awk -F';;' -v n="$1" '{ f = $n; gsub(/^[ ]+|[ ]+$/, "", f); print f }'; }

FINDINGS=0
risk_scan() {
    note "risk scan: $(wc -l <"$NAMES" | tr -d ' ') files changed since $BASE, $(wc -l <"$DIFFFILE" | tr -d ' ') lines added"
    [ -z "$(git status --porcelain 2>/dev/null)" ] || echo "(the working tree has uncommitted changes; the scan reads only commits)"
    local line id mode files text inc why out
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        id="$(printf '%s' "$line" | field 1)"
        mode="$(printf '%s' "$line" | field 2)"
        files="$(printf '%s' "$line" | field 3)"
        text="$(printf '%s' "$line" | field 4)"
        inc="$(printf '%s' "$line" | field 5)"
        why="$(printf '%s' "$line" | field 6)"
        # Matches as "file:line: text"; a header that has the required include already is not reported.
        out="$(FRE="$files" TRE="$text" awk -F'\t' 'BEGIN { fre = ENVIRON["FRE"]; tre = ENVIRON["TRE"] }
            $1 ~ fre && (tre == "" || $3 ~ tre) { t = $3; sub(/^[ \t]+/, "", t); if (length(t) > 100) t = substr(t, 1, 100) "..."; print $1 ":" $2 ": " t }
        ' "$DIFFFILE")"
        if [ -n "$inc" ] && [ -n "$out" ]; then
            local kept="" l f
            while IFS= read -r l; do
                f="${l%%:*}"
                grep -Eq "^[ ]*#[ ]*include[ ]*<$inc>" "$f" 2>/dev/null || kept="$kept$l"$'\n'
            done <<EOF
$out
EOF
            out="${kept%$'\n'}"
        fi
        [ -z "$out" ] && continue
        FINDINGS=$((FINDINGS + 1))
        printf '\n[%s] %s\n' "$id" "$why"
        if [ "$mode" = file ]; then
            printf '%s\n' "$out" | awk -F: '{c[$1]++; if (!($1 in first)) first[$1] = $2} END {for (f in c) printf "    %s (%d added lines, first at %s)\n", f, c[f], first[f]}' | sort
        else
            printf '%s\n' "$out" | head -n 12 | sed 's/^/    /'
            local n; n="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
            [ "$n" -gt 12 ] && echo "    ... $((n - 12)) more"
        fi
    done <<EOF
$RULES
EOF
    # Cross-file checks the table cannot express.
    if grep -q '\.glsl$' "$NAMES" && ! grep -Eq 'shaders/.*\.glsl\.h$' "$NAMES"; then
        FINDINGS=$((FINDINGS + 1))
        printf '\n[shader-headers] a .glsl changed and no engine/render/src/shaders/*.glsl.h did: run tools/shaders/compile_shaders.sh and commit the headers.\n'
    fi
    local dup; dup="$(git ls-files | awk '{k = tolower($0); if (k in s && s[k] != $0) print s[k] " <-> " $0; s[k] = $0}' | head -n 5)"
    if [ -n "$dup" ]; then
        FINDINGS=$((FINDINGS + 1))
        printf '\n[case-paths] tracked paths that differ only by case (macOS and Windows would merge them):\n%s\n' "$(printf '%s\n' "$dup" | sed 's/^/    /')"
    fi
    # Paths in the diff whose lower-case form is referenced with another case elsewhere are too slow to grep for; remind.
    if grep -Eq '^(examples|templates|docs|tools|engine)/' "$NAMES" && git diff --name-status "$BASE"...HEAD | grep -q '^[AR]'; then
        printf '\n[case-refs] files were added or renamed: check that every include/require/asset path you wrote matches the file name letter by letter (Linux is case-sensitive, Windows and macOS are not, so a wrong case only fails on Linux CI).\n'
    fi
    echo
    if [ $FINDINGS = 0 ]; then echo "risk scan: nothing flagged."
    else echo "risk scan: $FINDINGS item(s) to check above. Each is a place CI has failed before, not necessarily a bug."; fi
}

t0=$SECONDS
risk_scan
if [ $FINDINGS != 0 ] && [ $STRICT = 1 ]; then record FAIL "risk scan" $((SECONDS - t0)) "$FINDINGS item(s), --strict"
else record PASS "risk scan" $((SECONDS - t0)) "$FINDINGS item(s) to check"; fi
[ $FINDINGS != 0 ] && [ $STRICT = 1 ] && FAILED=1

print_summary() {
    echo; echo "==== ci-preflight summary (vs $BASE, $(git rev-parse --short HEAD))"
    printf '%s\n' "${RESULTS[@]}"
}

if [ $SCAN_ONLY = 1 ]; then print_summary; exit $FAILED; fi
if [ "$HOST" = Windows ]; then
    record SKIP "everything else" 0 "Windows host: run scripts\\agent-build.ps1 build\\agent-<name> -Test -Examples"
    print_summary; exit $FAILED
fi

# Which tests the diff touches: tools/editor -> editor autotests; examples/<n> -> that example; engine, tools/cli (and
# anything else that is code: cmake, scripts that build) -> all editor autotests + every example; docs only -> none.
select_stress() {  # sets EDITOR_RE, EXAMPLE_RE
    EDITOR_RE=""; EXAMPLE_RE=""
    local all_ex=0 all_ed=0 ex_list="" f n
    while IFS= read -r f; do
        case "$f" in
            tools/editor/*) all_ed=1 ;;
            examples/*) n="${f#examples/}"; n="${n%%/*}"; ex_list="$ex_list $n" ;;
            engine/*|tools/cli/*|tools/common/*|external/*|CMakeLists.txt|cmake/*|CMakePresets.json) all_ed=1; all_ex=1 ;;
        esac
    done <"$NAMES"
    [ $all_ed = 1 ] && EDITOR_RE='^editor_autotest'
    if [ $all_ex = 1 ]; then EXAMPLE_RE='^example_'
    elif [ -n "$ex_list" ]; then
        EXAMPLE_RE="^example_($(printf '%s\n' $ex_list | sort -u | sed 's/-/_/g;s/_/[-_]/g' | paste -sd'|' -))_"
    fi
}

if [ $PLAN = 1 ]; then
    select_stress
    echo "stress plan: editor='${EDITOR_RE:-none}' examples='${EXAMPLE_RE:-none}'"; exit 0
fi

# ---------------------------------------------------------------- 2. test-all
if [ $DO_TEST = 1 ]; then
    run_step test-all "$ROOT/scripts/test-all.sh"
fi

# ---------------------------------------------------------------- 3. stress
start_burners() {
    local i
    for i in $(seq 1 "$NCPU"); do yes >/dev/null 2>&1 & BURNERS+=("$!"); done
}

stress_ctest() {  # stress_ctest <dir> <regex>: repeats the matching tests under load; rc 77 when none exist
    local dir="$1" re="$2"
    [ -f "$dir/CTestTestfile.cmake" ] || { echo "$dir is not built: run test-all first"; return 77; }
    local n; n="$(ctest --test-dir "$dir" -N -R "$re" 2>/dev/null | sed -n 's/^Total Tests: *//p')"
    [ "${n:-0}" -gt 0 ] || { echo "no ctest entry matches '$re' in $dir (the editor autotest does not run on this host?)"; return 77; }
    echo "$n test(s) matching $re in $dir, repeated until-fail:$REPEAT with $NCPU CPU burners"
    ctest --test-dir "$dir" -R "$re" --repeat "until-fail:$REPEAT" -j "$CTEST_JOBS" --output-on-failure
}

if [ $DO_STRESS = 1 ]; then
    select_stress
    if [ -z "$EDITOR_RE$EXAMPLE_RE" ]; then
        record SKIP "stress" 0 "the diff touches no editor, engine, CLI or example code"
    else
        echo; echo "stress selection: editor='${EDITOR_RE:-none}' examples='${EXAMPLE_RE:-none}'"
        start_burners
        if [ -n "$EDITOR_RE" ]; then
            if [ "$HOST" = Linux ] && [ -z "${DISPLAY:-}" ] && ! command -v xvfb-run >/dev/null 2>&1; then
                record SKIP "stress: editor autotests" 0 "no display and no xvfb-run"
            else run_step stress-editor stress_ctest "$DEBUG_DIR" "$EDITOR_RE"; fi
        fi
        [ -n "$EXAMPLE_RE" ] && run_step stress-examples stress_ctest "$RELEASE_DIR" "$EXAMPLE_RE"
        stop_burners
    fi
fi

# ---------------------------------------------------------------- 4. other platforms
if [ $DO_PLATFORMS = 1 ]; then
    case "$HOST" in
        Darwin) JOBS_LIST="macos ios web android" ;;
        Linux) JOBS_LIST="linux windows android web" ;;
        *) JOBS_LIST="" ;;
    esac
    if [ -n "$JOBS_LIST" ]; then
        # shellcheck disable=SC2086
        run_step ci-local "$ROOT/scripts/ci-local.sh" $JOBS_LIST
        # ci-local.sh prints one line per job: carry them into the summary (a skipped job is not a failure).
        grep -E '^(linux|windows|android|web|macos|ios) +(PASS|FAIL|SKIP) ' "$LOGDIR/preflight-ci-local.log" >"$TMP/ci-local-jobs.txt" 2>/dev/null
    fi
    for s in ci-docker:"linux windows" ci-remote-windows:""; do
        name="${s%%:*}"; args="${s#*:}"
        if [ -x "$ROOT/scripts/$name.sh" ]; then
            # shellcheck disable=SC2086
            run_step "$name" "$ROOT/scripts/$name.sh" $args
        else
            record SKIP "$name" 0 "scripts/$name.sh does not exist yet"
        fi
    done
fi

print_summary
[ -s "$TMP/ci-local-jobs.txt" ] && { echo "ci-local jobs:"; sed 's/^/    /' "$TMP/ci-local-jobs.txt"; }
exit $FAILED
