#!/usr/bin/env bash
# Measure every example's performance baseline on THIS machine and leave the entries in an output directory:
# the "Perf baselines" job of .github/workflows/ci.yml runs it on each runner and uploads the directory as an artifact
# (docs/PERFORMANCE.md, "Baselines from CI"). Nothing in the repository changes.
#
#   scripts/perf-baselines.sh <path to factoria> <output dir> [name ...]
#
# For each tools/cli/tests/perf/<name>.perf.json (every example scene and the skinned-sprites fixture; not the regression
# test's file) it copies the file into <output dir>, runs `factoria call perf.baseline` on that copy (so the frames, the
# scene and the other runners' entries stay as they are and only this runner's entry is written) and keeps the command's
# answer in <name>.result.json. To commit the numbers, copy `runners.<runner>` of each copy into the file of the same
# name in tools/cli/tests/perf/ (the runner id is in the result). A name list limits the run to those files.
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <path to factoria> <output dir> [name ...]" >&2
    exit 2
fi
factoria=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
mkdir -p "$2"
out=$(cd "$2" && pwd)
shift 2
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

failed=0
for file in tools/cli/tests/perf/*.perf.json; do
    name=$(basename "$file" .perf.json)
    [ "$name" = "regression" ] && continue
    if [ "$#" -gt 0 ]; then
        wanted=0
        for w in "$@"; do [ "$w" = "$name" ] && wanted=1; done
        [ "$wanted" = 1 ] || continue
    fi
    # <example>.perf.json, or <example>-<suffix>.perf.json for an example that measures several scenes.
    project=""
    for dir in examples/*/; do
        ex=$(basename "$dir")
        if [ "$name" = "$ex" ] || [[ "$name" == "$ex"-* ]]; then
            # The longest example name that prefixes the file name wins (an example named like another one's prefix).
            if [ -z "$project" ] || [ "${#ex}" -gt "${#project}" ]; then project=$ex; fi
        fi
    done
    if [ -n "$project" ]; then
        project="examples/$project"
    elif [ -d "tools/cli/tests/fixtures/$name" ]; then
        project="tools/cli/tests/fixtures/$name"
    else
        echo "perf-baselines: no project for $file" >&2
        failed=1
        continue
    fi
    cp "$file" "$out/$name.perf.json"
    echo "== $name ($project)"
    # The file argument is absolute: perf.baseline resolves a relative one inside the project. On Windows `pwd` gives a
    # /c/... path the program cannot open, so use the native form when cygpath exists.
    native="$out/$name.perf.json"
    if command -v cygpath >/dev/null 2>&1; then native=$(cygpath -m "$native"); fi
    if "$factoria" call --no-graphics --project "$project" perf.baseline "{\"file\":\"$native\",\"repeats\":3}" \
        > "$out/$name.result.json"; then
        grep -E '"(runner|cpuMsMedian|cpuMsP95|peakMemoryMB|drawCalls|entities)"' "$out/$name.result.json" || true
    else
        echo "perf-baselines: perf.baseline failed for $name" >&2
        failed=1
    fi
done
exit "$failed"
