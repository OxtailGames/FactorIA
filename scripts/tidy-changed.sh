#!/usr/bin/env bash
# Runs the clang-tidy pinned in scripts/lint-tools.sh (checks of .clang-tidy: bug finders only) over the first-party
# .cpp files changed against <base>, with the compile_commands.json of a CMake configure.
#
#   scripts/tidy-changed.sh <base> [build-dir]
#
# <base> is a branch, tag or commit (origin/main); files changed and not yet committed count too. [build-dir] defaults
# to build/tidy, configured on first use (configure only: nothing is compiled, so it takes seconds). Exit 1 when a
# check reports something, 2 for a setup problem. A hit that is a false positive: rewrite the line, or end it with
# `// NOLINT(<check name>)` and a reason.
set -u
cd "$(dirname "$0")/.." || exit 1
source scripts/lint-tools.sh
FA_LINT_EXT='\.(cpp|cc)$'

base="${1:-}"
[ -n "$base" ] || { echo "Usage: scripts/tidy-changed.sh <base> [build-dir]   (e.g. origin/main)" >&2; exit 2; }
build="${2:-build/tidy}"

tool="$(fa_lint_tool tidy)" || exit 2
files="$(fa_lint_files "$base")" || { echo "error: could not diff against '$base'. Hint: fetch it first (git fetch origin) and pass origin/main" >&2; exit 2; }
# Windows-only and Apple-only sources do not compile on this host.
case "$(uname -s)" in
    Darwin*) files="$(grep -Ev '_(win32|android|linux|egl|web)\.' <<< "$files")" ;;
    Linux*) files="$(grep -Ev '_(win32|apple|android|web)\.' <<< "$files")" ;;
esac
if [ -z "$files" ]; then echo "tidy: no C++ sources changed against $base"; exit 0; fi

if [ ! -f "$build/compile_commands.json" ]; then
    echo "Configuring $build for compile_commands.json ..." >&2
    cmake -S . -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON > "$build.configure.log" 2>&1 ||
        { echo "error: CMake configure failed, see $build.configure.log" >&2; exit 2; }
fi

extra=()
if [ "$(uname -s)" = Darwin ]; then
    # The pip clang-tidy has no Apple toolchain around it: point it at the SDK's headers.
    sdk="$(xcrun --show-sdk-path)"
    extra=(--extra-arg=-isysroot --extra-arg="$sdk" --extra-arg=-isystem"$sdk/usr/include/c++/v1")
fi

count=$(printf '%s\n' "$files" | wc -l | tr -d ' ')
echo "tidy: $count files against $base"
jobs="${FA_TIDY_JOBS:-2}"
log="$(mktemp)"
printf '%s\n' "$files" | xargs -P "$jobs" -n 4 "$tool" -p "$build" --quiet ${extra[@]+"${extra[@]}"} > "$log" 2>&1
rc=$?
# Only the diagnostics: --quiet leaves the "N warnings generated" counters out.
# A header that only a build writes (fa_build_fingerprint.h) is not there after a configure: that is not a finding.
if grep -E ': (warning|error): ' "$log" | grep -qv "file not found \[clang-diagnostic-error\]"; then
    grep -vE '^[0-9]+ (warnings?|errors?) (and [0-9]+ (warnings?|errors?) )?generated' "$log"
    echo "tidy: findings above (check names in [brackets]; .clang-tidy lists the checks)"
    rm -f "$log"; exit 1
fi
[ $rc -eq 0 ] || { cat "$log"; rm -f "$log"; echo "tidy: clang-tidy failed (see above)" >&2; exit 2; }
rm -f "$log"
echo "tidy: clean"
