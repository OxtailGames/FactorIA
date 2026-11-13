#!/usr/bin/env bash
# Formats first-party C and C++ (.c .cc .cpp .h .hpp under engine, tools, player, platforms, examples, templates) with
# the clang-format pinned in scripts/lint-tools.sh and the rules of .clang-format; .clang-format-ignore lists what is
# never touched (external/, generated shader headers, test data). Objective-C (.m, .mm) is not formatted.
#
#   scripts/format.sh                     format every file in place
#   scripts/format.sh --check             change nothing; list the files that need formatting, exit 1 if any
#   scripts/format.sh --changed <base>    only the files changed against <base> (a branch, tag or commit; also the
#                                         uncommitted changes), e.g. --changed origin/main
# Works the same on Linux, macOS and Windows (Git Bash). The first run installs the tools into build/lint-venv.
set -u
cd "$(dirname "$0")/.." || exit 1
source scripts/lint-tools.sh
FA_LINT_EXT='\.(c|cc|cpp|h|hpp)$'

check=0 base=""
while [ $# -gt 0 ]; do
    case "$1" in
        --check) check=1 ;;
        --changed) shift; base="${1:?--changed needs a base, e.g. origin/main}" ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "error: unknown argument '$1'. Usage: scripts/format.sh [--check] [--changed <base>]" >&2; exit 2 ;;
    esac
    shift
done

tool="$(fa_lint_tool format)" || exit 2
files="$(fa_lint_files "$base")" || { echo "error: could not diff against '$base'. Hint: fetch it first (git fetch origin) and pass origin/main" >&2; exit 2; }
if [ -z "$files" ]; then echo "format: no C/C++ files to check"; exit 0; fi
count=$(printf '%s\n' "$files" | wc -l | tr -d ' ')
fixcmd="scripts/format.sh${base:+ --changed $base}"

if [ $check -eq 0 ]; then
    printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 "$tool" -i --style=file
    rc=$?
    if [ $rc -ne 0 ]; then echo "format: clang-format failed (exit $rc, see above)" >&2; exit 2; fi
    echo "format: $count files formatted"
    exit 0
fi

# --dry-run reports "code should be clang-formatted" with the file name for each file it would change; it exits 0 for
# those, so a non-zero exit is a real failure (bad config, unreadable file).
out="$(printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 "$tool" --dry-run --style=file 2>&1)"
rc=$?
bad="$(grep -E ': (warning|error): code should be clang-formatted' <<< "$out" | sed -E 's/:[0-9]+:[0-9]+: .*//' | sort -u)"
other="$(grep -E '^[^ ]+:[0-9]+:[0-9]+: error:|^clang-format:' <<< "$out" | grep -v 'code should be clang-formatted' | head -5)"
if [ -n "$other" ] || { [ $rc -ne 0 ] && [ -z "$bad" ]; }; then
    echo "${other:-$out}" | head -20
    echo "format: clang-format failed (exit $rc, see above)" >&2
    exit 2
fi
if [ -n "$bad" ]; then
    echo "These files need formatting:"
    sed 's/^/  /' <<< "$bad"
    echo "Fix them with: $fixcmd"
    exit 1
fi
echo "format: $count files are formatted"
