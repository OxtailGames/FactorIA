#!/usr/bin/env bash
# Checks the replay-hash line that tools/cli/tests/determinism_probe.js logs ("FA_DET_HASH math=.. script=.. physics2d=..
# physics3d=.. nav=.. ...") in a log file against tools/cli/tests/determinism_expected.txt (M91.3). The Android, iOS and web smoke
# tests call it after their game has run with the probe added (the `android-emulator`, `ios` and `web` jobs of ci.yml): the hashes
# must be the ones every desktop computes, so a platform whose floating point or Box2D/solver/nav arithmetic differs fails here
# with the section that differs. The line is printed either way, so the CI log shows what a platform computed.
#
#   scripts/det-hash-check.sh <log file> [expected file (default tools/cli/tests/determinism_expected.txt)]
#
# Exit code 0 = every key of the expected file is in the logged line with the same value.
set -uo pipefail

log="${1:?usage: det-hash-check.sh <log file> [expected file]}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
expected_file="${2:-$here/tools/cli/tests/determinism_expected.txt}"

[ -f "$log" ] || { echo "det-hash: the log $log does not exist"; exit 1; }
[ -f "$expected_file" ] || { echo "det-hash: $expected_file does not exist"; exit 1; }

line="$(grep -F -m 1 'FA_DET_HASH ' "$log" | tr -d '\r' || true)"
if [ -z "$line" ]; then
    echo "det-hash: no 'FA_DET_HASH ' line in $log: the determinism probe (tools/cli/tests/determinism_probe.js) did not run to its" \
        "step 60, or its script failed (look for a script error in the log)"
    exit 1
fi
got="${line#*FA_DET_HASH }"
expected="$(sed -n 1p "$expected_file" | tr -d '\r')"
echo "det-hash: this platform printed: $got"
echo "det-hash: expected:              $expected"

status=0
for pair in $expected; do
    key="${pair%%=*}"
    want="${pair#*=}"
    have=""
    for token in $got; do
        [ "${token%%=*}" = "$key" ] && have="${token#*=}"
    done
    if [ "$have" != "$want" ]; then
        echo "det-hash: section '$key' differs: this platform computed '${have:-(missing)}', the committed value is '$want'." \
            "math = the scripts' Math.*, script = a seeded generator plus Math, physics2d = Box2D, physics3d = the 3D solver," \
            "nav = the nav bake and path search (docs/ARCHITECTURE.md, 'Determinism')."
        status=1
    fi
done
[ "$status" -eq 0 ] && echo "det-hash: OK, every hash equals the committed one"
exit "$status"
