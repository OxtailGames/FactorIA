#!/usr/bin/env bash
#
# Boots an iOS Simulator, installs a built FactorIA player app, launches it with its console captured and asserts
# that the game really runs. CI runs it in the `ios` job; needs a Mac with Xcode.
#
#   ./scripts/ios-smoke.sh <factoria_player.app> <bundleId> [timeoutSeconds] [outDir]
#   ./scripts/ios-smoke.sh --boot    only start booting the simulator it would use, and return
#
# What it checks, in this order (each step fails with its own message and the evidence in outDir):
#   1. run        the process is alive, the player logged its run marker ("60 frames rendered", see
#                 engine/runtime/src/runners.cpp), and is still the same process 5 s later.
#   2. audio      the player opened an audio output device ("audio: output device open") and the platform pulled
#                 samples from it ("audio: stream running"); "no audio output device available" fails.
#   3. touch      NOT covered: `simctl` cannot inject touches (see docs/MOBILE.md).
#   4. suspend    Settings is launched on top of the app: "player: suspended", the process survives; the app is
#                 launched again: same process, "player: resumed" and "player: 60 frames rendered after resume"
#                 (the Metal view draws again), the screen shows a picture.
#   5. no crash   no engine error, no crash report; the display shows a picture (a black window passes none of this).
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

# Lines of the console containing the text, in both files.
count() { grep -hcF -- "$1" "$OUT/stderr.log" "$OUT/stdout.log" | awk '{n += $1} END {print n + 0}'; }
first_line() { grep -hF -- "$1" "$OUT/stderr.log" "$OUT/stdout.log" | sed -n 1p; }

# wait_for_log <needle> <seconds> [baseline]   returns 0 once the console has MORE than <baseline> (default 0) lines
# containing <needle>, 1 after <seconds>. Fails at once when the app process is gone.
wait_for_log() {
    local needle="$1" limit="$2" base="${3:-0}" t0=$SECONDS
    while :; do
        (( $(count "$needle") > base )) && return 0
        alive || fail "the app process $PID is gone before it logged '$needle': it crashed or quit"
        (( SECONDS - t0 < limit )) || return 1
        sleep 2
    done
}

has_picture() {  # has_picture <png> <what>
    local shot
    shot="$(python3 "$(dirname "$0")/png_has_content.py" "$1" 2>&1)" || fail "$2: the display shows no picture: $shot"
    echo "$2: $shot" | tee -a "$OUT/summary.txt"
}

# ---- 1. run ---------------------------------------------------------------------------------------------------------
# Wait for the run marker, failing early when the process dies.
wait_for_log "$MARKER" "$TIMEOUT" || fail "no '$MARKER' within ${TIMEOUT}s"
echo "marker after $((SECONDS - STARTED_AT))s" | tee -a "$OUT/summary.txt"

# Still alive a few seconds after the marker.
sleep 5
alive || fail "the app process $PID is gone 5s after the marker"

# ---- 2. audio -------------------------------------------------------------------------------------------------------
NO_AUDIO="$(first_line 'no audio output device available')"
if [ -n "$NO_AUDIO" ]; then
    echo "$NO_AUDIO"
    echo "---- host audio devices (system_profiler SPAudioDataType) ----"
    system_profiler SPAudioDataType 2>&1 | tail -n 30
    fail "audio: the player found no audio output device (line above); sokol_audio could not start the AudioQueue"
fi
AUDIO_OPEN="$(first_line 'audio: output device open')"
[ -n "$AUDIO_OPEN" ] || fail "audio: no 'audio: output device open' line in the console: the player never opened an audio device"
echo "$AUDIO_OPEN" | tee -a "$OUT/summary.txt"
wait_for_log "audio: stream running" 30 || fail "audio: the device opened but the platform never called the stream callback within 30s"
first_line 'audio: stream running' | tee -a "$OUT/summary.txt"

# ---- 3. touch -------------------------------------------------------------------------------------------------------
echo "touch: not covered on iOS (simctl cannot inject touches)" | tee -a "$OUT/summary.txt"

# ---- 4. suspend / resume --------------------------------------------------------------------------------------------
SUSPENDED0="$(count 'player: suspended')"
RESUMED0="$(count 'player: resumed')"
AFTER0="$(count 'frames rendered after resume')"

# Another app in front of ours: the scene resigns active (sokol_app: SUSPENDED) and the Metal display link pauses.
xcrun simctl launch "$UDID" com.apple.Preferences 2>&1 | tee -a "$OUT/summary.txt"
[ "${PIPESTATUS[0]}" = 0 ] || fail "suspend: could not launch com.apple.Preferences to cover the app"
wait_for_log "player: suspended" 30 "$SUSPENDED0" || fail "suspend: launching Settings on top never suspended the player ('player: suspended' missing)"
alive || fail "suspend: the app process $PID died when it went to the background"

# Launching an app that is running brings it to the front without starting a new process.
RELAUNCH="$(xcrun simctl launch "$UDID" "$BUNDLE_ID" 2>&1)"
echo "$RELAUNCH" | tee -a "$OUT/summary.txt"
NEWPID="$(echo "$RELAUNCH" | sed -n "s/^$BUNDLE_ID: \([0-9][0-9]*\).*/\1/p" | tail -n 1)"
[ "$NEWPID" = "$PID" ] || fail "resume: simctl launch gave pid '${NEWPID:-none}' instead of bringing $PID back to the front"
wait_for_log "player: resumed" 30 "$RESUMED0" || fail "resume: 'player: resumed' missing after bringing the app back"
wait_for_log "player: 60 frames rendered after resume" 60 "$AFTER0" ||
    fail "resume: the player did not draw 60 frames within 60s after coming back (the Metal view does not draw again)"
alive || fail "resume: the app process $PID is gone"
xcrun simctl io "$UDID" screenshot "$OUT/screen-resumed.png" >/dev/null 2>&1
has_picture "$OUT/screen-resumed.png" "resume"

# ---- 5. no crash ----------------------------------------------------------------------------------------------------
xcrun simctl io "$UDID" screenshot "$OUT/screen.png" >/dev/null 2>&1
if grep -E '^\[ *[0-9.]+\] ERROR ' "$OUT/stderr.log" "$OUT/stdout.log"; then fail "the engine logged errors (lines above)"; fi
if ls ~/Library/Logs/DiagnosticReports/factoria_player* >/dev/null 2>&1; then fail "a crash report exists for factoria_player"; fi

# The display shows a picture, not a black or flat window (the log alone cannot tell).
has_picture "$OUT/screen.png" "display"

echo "---- run evidence (player console) ----" | tee -a "$OUT/summary.txt"
grep -hE '(engine: Graphics|scene: Loaded|audio: |player: )' "$OUT/stderr.log" "$OUT/stdout.log" | tee -a "$OUT/summary.txt"
echo "OK: $BUNDLE_ID ran on the simulator (pid $PID): rendered, audio stream, suspend/resume, no crash (touch not covered)." | tee -a "$OUT/summary.txt"
