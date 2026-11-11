#!/usr/bin/env bash
# Shows the performance warnings a green ctest run hides (docs/PERFORMANCE.md, "The band"). `perf.check` answers "status":
# "warn" and exits 0 when a time or the memory is inside the band between the warn and the fail limit, and ctest prints
# the output of a passing test nowhere. ctest does keep it in Testing/Temporary/LastTest.log of the build tree, so this
# reads the log and lists, per `*_perf` test, the warn messages: on stdout, as a GitHub annotation (::warning::) and,
# when GITHUB_STEP_SUMMARY is set, as a table in the job summary. Exit status 0 always: a warning is not a failure, and
# a missing log (the tests did not run) is only said.
#
#   scripts/ci-perf-warnings.sh <ctest build dir, e.g. build/linux-release> [log file]
#
# Run it right after the ctest step: the next ctest run in the same tree replaces the log.
set -u
dir="${1:-}"
[ -n "$dir" ] || { echo "usage: $0 <ctest build dir> [log file]" >&2; exit 2; }
log="${2:-$dir/Testing/Temporary/LastTest.log}"
if [ ! -f "$log" ]; then echo "perf warnings: no $log (ctest did not run in $dir)"; exit 0; fi

# LastTest.log: "N/M Testing: <name>" starts a test's block; the `perf.check` answer inside it has one line
# `"message": "..."` (JSON text, quotes escaped as \"). A CRLF log (Windows) loses its \r first.
found="$(tr -d '\r' < "$log" | awk '
    /^[0-9]+\/[0-9]+ Testing: / { name = $3; next }
    name ~ /_perf$/ && /"message": *"/ && (/Inside the warning band/ || /Over the time budget/) {
        line = $0
        sub(/^[ \t]*"message": *"/, "", line); sub(/",?[ \t]*$/, "", line); gsub(/\\"/, "\"", line)
        print name "\t" line
    }
')"

if [ -z "$found" ]; then echo "perf warnings: none in $log"; exit 0; fi
count="$(printf '%s\n' "$found" | wc -l | tr -d ' ')"
echo "perf warnings: $count test(s) inside the warning band (not failures; docs/PERFORMANCE.md, \"The band\"):"
tab="$(printf '\t')"
printf '%s\n' "$found" | while IFS="$tab" read -r name msg; do
    echo "  $name: $msg"
    echo "::warning title=perf warn ($name)::$msg"
done
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "### Performance warnings ($dir)"
        echo
        echo "Inside the warning band of the budget, so the tests passed. A time or memory that keeps showing up here is a game that got slower."
        echo
        echo "| Test | Message |"
        echo "| --- | --- |"
        printf '%s\n' "$found" | while IFS="$tab" read -r name msg; do
            echo "| \`$name\` | $(printf '%s' "$msg" | sed 's/|/\\|/g') |"
        done
        echo
    } >> "$GITHUB_STEP_SUMMARY"
fi
exit 0
