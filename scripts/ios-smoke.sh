#!/usr/bin/env bash
#
# Boots an iOS Simulator, installs a built FactorIA player app, launches it with its console captured and asserts
# that the game really runs: the process is alive, the player logged its run marker ("60 frames rendered", see
# engine/runtime/src/runners.cpp), nothing crashed and the display shows a picture. CI runs it in the `ios` job;
# needs a Mac with Xcode.
#
#   ./scripts/ios-smoke.sh <factoria_player.app> <bundleId> [timeoutSeconds] [outDir]
#   ./scripts/ios-smoke.sh --boot    only start booting the simulator it would use, and return
#
# The app must be built for the simulator (`cmake --build --preset ios-simulator ... -sdk iphonesimulator`). The
# first simulator boot takes 5-7 minutes on a hosted runner and slows a build on the same machine, so CI runs
# `--boot` on one runner while another builds the app.
#
# Output (outDir, default build/ios-smoke): stdout.log / stderr.log (the player's console; the engine logs to
# stderr), screen.png, summary.txt; on failure also unified.log (the simulator's system log) and crash reports.
# Exit code 0 = the game runs.
set -uo pipefail

# The newest iOS runtime's first iPhone.
IFS= read -r -d '' PICK_DEVICE <<'PY'
import json, sys
data = json.load(sys.stdin)["devices"]
def version(key):
    tail = key.rsplit(".", 1)[-1]  # "iOS-18-2"
    return [int(p) for p in tail.split("-")[1:] if p.isdigit()]
for runtime in sorted((k for k in data if ".iOS-" in k), key=version, reverse=True):
    phones = [d for d in data[runtime] if d.get("isAvailable", True) and d["name"].startswith("iPhone")]
    if phones:
        print(phones[0]["udid"])
        break
PY
UDID="$(xcrun simctl list devices available -j | python3 -c "$PICK_DEVICE")"
if [ "${1:-}" = --boot ]; then
    [ -n "$UDID" ] && xcrun simctl boot "$UDID"
    exit
fi

APP="${1:?usage: ios-smoke.sh <factoria_player.app> <bundleId> [timeoutSeconds] [outDir]}"
BUNDLE_ID="${2:?usage: ios-smoke.sh <factoria_player.app> <bundleId> [timeoutSeconds] [outDir]}"
TIMEOUT="${3:-90}"
OUT="${4:-build/ios-smoke}"
MARKER="player: 60 frames rendered"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
: >"$OUT/summary.txt"

if [ -z "$UDID" ]; then
    xcrun simctl list devices available | tee -a "$OUT/summary.txt"
    echo "FAIL: no available iPhone simulator on this machine" >&2
    exit 1
fi

trap 'xcrun simctl shutdown "$UDID" >/dev/null 2>&1' EXIT

fail() {
    echo "FAIL: $*" | tee -a "$OUT/summary.txt"
    xcrun simctl io "$UDID" screenshot "$OUT/screen.png" >/dev/null 2>&1
    xcrun simctl spawn "$UDID" log show --style compact --last 10m \
        --predicate 'process == "factoria_player" OR eventMessage CONTAINS "factoria_player"' >"$OUT/unified.log" 2>&1
    cp ~/Library/Logs/DiagnosticReports/factoria_player* "$OUT/" 2>/dev/null
    echo "---- stdout.log / stderr.log ----"
    tail -n 60 "$OUT/stdout.log" "$OUT/stderr.log" 2>/dev/null
    exit 1
}

echo "host: $(sw_vers -productName) $(sw_vers -productVersion) $(uname -m), $(xcodebuild -version | tr '\n' ' ')" | tee -a "$OUT/summary.txt"
echo "simulator: $UDID" | tee -a "$OUT/summary.txt"

# Boot, sign ad hoc like Xcode does for simulator builds, install.
xcrun simctl boot "$UDID" >/dev/null 2>&1
xcrun simctl bootstatus "$UDID" -b 2>&1 | tail -n 2 | tee -a "$OUT/summary.txt"
codesign --force --sign - --timestamp=none "$APP" 2>&1 | tee -a "$OUT/summary.txt"
xcrun simctl install "$UDID" "$APP" 2>&1 | tee -a "$OUT/summary.txt" || fail "simctl install failed"

# Launch with the console in files.
: >"$OUT/stdout.log"; : >"$OUT/stderr.log"
LAUNCH="$(xcrun simctl launch --terminate-running-process --stdout="$OUT/stdout.log" --stderr="$OUT/stderr.log" \
          "$UDID" "$BUNDLE_ID" 2>&1)"
echo "$LAUNCH" | tee -a "$OUT/summary.txt"
PID="$(echo "$LAUNCH" | sed -n "s/^$BUNDLE_ID: \([0-9][0-9]*\).*/\1/p" | tail -n 1)"
[ -n "$PID" ] || fail "simctl launch did not report a pid for $BUNDLE_ID"
STARTED_AT=$SECONDS
alive() { kill -0 "$PID" 2>/dev/null; }   # simulator processes are ordinary host processes

# Wait for the run marker, failing early when the process dies.
found=0
while (( SECONDS - STARTED_AT < TIMEOUT )); do
    if grep -qF "$MARKER" "$OUT/stderr.log" "$OUT/stdout.log"; then found=1; break; fi
    alive || fail "the app process $PID is gone before it logged '$MARKER': it crashed or quit"
    sleep 2
done
[ "$found" = 1 ] || fail "no '$MARKER' within ${TIMEOUT}s"
echo "marker after $((SECONDS - STARTED_AT))s" | tee -a "$OUT/summary.txt"

# Still alive a few seconds after the marker, no engine errors, no crash report.
sleep 5
alive || fail "the app process $PID is gone 5s after the marker"
xcrun simctl io "$UDID" screenshot "$OUT/screen.png" >/dev/null 2>&1
if grep -E '^\[ *[0-9.]+\] ERROR ' "$OUT/stderr.log" "$OUT/stdout.log"; then fail "the engine logged errors (lines above)"; fi
if ls ~/Library/Logs/DiagnosticReports/factoria_player* >/dev/null 2>&1; then fail "a crash report exists for factoria_player"; fi

# The display shows a picture, not a black or flat window (the log alone cannot tell).
SHOT="$(python3 "$(dirname "$0")/png_has_content.py" "$OUT/screen.png" 2>&1)" || fail "the display shows no picture: $SHOT"
echo "$SHOT" | tee -a "$OUT/summary.txt"

echo "---- run evidence (player console) ----" | tee -a "$OUT/summary.txt"
grep -hE '(engine: Graphics|scene: Loaded|player: )' "$OUT/stderr.log" "$OUT/stdout.log" | tee -a "$OUT/summary.txt"
echo "OK: $BUNDLE_ID ran on the simulator (pid $PID), rendered frames, no crash." | tee -a "$OUT/summary.txt"
