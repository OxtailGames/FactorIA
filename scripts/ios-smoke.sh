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
#   3. touch      `simctl` cannot inject touches, so a UI test (platforms/ios/touch-test, XCUITest) taps the middle of
#                 the screen of the running app: the player logs "input: first touch at design (x, y)", at the middle
#                 of the design size for the "fit" and "stretch" scale modes (read from <app>/game/factoria.json), and
#                 the process survives. Needs CMake (the UI test project is generated, then built by xcodebuild).
#   4. suspend    Settings is launched on top of the app: "player: suspended", the process survives; the app is
#                 launched again: same process, "player: resumed" and "player: 60 frames rendered after resume"
#                 (the Metal view draws again), the screen shows a picture.
#   5. no crash   no engine error, no crash report; the display shows a picture (a black window passes none of this).
#   (1b. plugin   only with FA_IOS_PLUGIN_PROBE=1: the game declares the native plugin "example" (platforms/plugin) and runs
#                 tools/cli/tests/plugin_probe.js, which calls it when the game starts: the console must show "probe add=3"
#                 and a "probe info=" line naming the plugin, so the static library is linked into the app and registered.)
#
# The app must be built for the simulator (`cmake --build --preset ios-simulator ... -sdk iphonesimulator`). The
# first simulator boot takes 5-7 minutes on a hosted runner and slows a build on the same machine, so CI runs
# `--boot` on one runner while another builds the app.
#
# Output (outDir, default build/ios-smoke): console.log (the player's stdout and stderr; the engine logs to stderr),
# screen.png, summary.txt; on failure also unified.log (the simulator's system log) and crash reports.
#
# The console is captured with `simctl launch --console-pty`, not with --stdout/--stderr: from the iOS 27 runtime
# (Xcode 27) on, those two paths are opened inside the simulator's own file system (`/tmp/x` lands in
# `<device>/data/tmp/x`, a path under the host's home makes the launch fail), so the files on the host stay empty.
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

CONSOLE_PID=
trap '[ -n "$CONSOLE_PID" ] && kill "$CONSOLE_PID" 2>/dev/null; xcrun simctl shutdown "$UDID" >/dev/null 2>&1' EXIT

fail() {
    echo "FAIL: $*" | tee -a "$OUT/summary.txt"
    xcrun simctl io "$UDID" screenshot "$OUT/screen.png" >/dev/null 2>&1
    xcrun simctl spawn "$UDID" log show --style compact --last 10m \
        --predicate 'process == "factoria_player" OR eventMessage CONTAINS "factoria_player"' >"$OUT/unified.log" 2>&1
    cp ~/Library/Logs/DiagnosticReports/factoria_player* "$OUT/" 2>/dev/null
    echo "---- console.log ----"
    tail -n 60 "$OUT/console.log" 2>/dev/null
    exit 1
}

echo "host: $(sw_vers -productName) $(sw_vers -productVersion) $(uname -m), $(xcodebuild -version | tr '\n' ' ')" | tee -a "$OUT/summary.txt"
echo "simulator: $UDID" | tee -a "$OUT/summary.txt"

# Boot, sign ad hoc like Xcode does for simulator builds, install.
xcrun simctl boot "$UDID" >/dev/null 2>&1
xcrun simctl bootstatus "$UDID" -b 2>&1 | tail -n 2 | tee -a "$OUT/summary.txt"
codesign --force --sign - --timestamp=none "$APP" 2>&1 | tee -a "$OUT/summary.txt"
xcrun simctl install "$UDID" "$APP" 2>&1 | tee -a "$OUT/summary.txt" || fail "simctl install failed"

# The pid of the running app, from the simulator's launchd ("<pid> <status> UIKitApplication:<bundleId>[...]");
# simulator processes are ordinary host processes, so the host can watch it.
app_pid() {
    xcrun simctl spawn "$UDID" launchctl list 2>/dev/null |
        awk -v app="UIKitApplication:$BUNDLE_ID[" 'index($3, app) == 1 && $1 ~ /^[0-9]+$/ {print $1; exit}'
}

# Launch with the console in a file: simctl stays attached in the background and copies everything the app writes to
# stdout and stderr (with --console-pty it does not print the pid, so launchd is asked for it).
: >"$OUT/console.log"
xcrun simctl launch --terminate-running-process --console-pty "$UDID" "$BUNDLE_ID" >"$OUT/console.log" 2>&1 &
CONSOLE_PID=$!
PID=
for _ in $(seq 1 30); do
    sleep 1
    PID="$(app_pid)"
    [ -n "$PID" ] && break
    kill -0 "$CONSOLE_PID" 2>/dev/null || break
done
[ -n "$PID" ] || fail "the app $BUNDLE_ID is not running 30s after simctl launch (console above)"
echo "launched: $BUNDLE_ID pid $PID" | tee -a "$OUT/summary.txt"
STARTED_AT=$SECONDS
alive() { kill -0 "$PID" 2>/dev/null; }   # simulator processes are ordinary host processes

# Lines of the console containing the text (the pty ends lines with CR LF; strip the CR).
count() { grep -cF -- "$1" "$OUT/console.log"; }
first_line() { grep -F -- "$1" "$OUT/console.log" | sed -n 1p | tr -d '\r'; }

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

# ---- 1b. plugin -----------------------------------------------------------------------------------------------------
if [ -n "${FA_IOS_PLUGIN_PROBE:-}" ]; then
    wait_for_log "probe add=3" 10 ||
        fail "plugin: no 'probe add=3' in the console: plugins.example.add(1, 2) was not answered by the native plugin (is it linked into the app and registered before main? a 'plugin' warning above says why it did not load)"
    first_line 'probe add=3' | tee -a "$OUT/summary.txt"
    PROBE_INFO="$(first_line 'probe info=')"
    case "$PROBE_INFO" in
        *'"plugin":"example"'*) echo "$PROBE_INFO" | tee -a "$OUT/summary.txt" ;;
        *) fail "plugin: the 'probe info=' line is missing or does not name the plugin \"example\": '$PROBE_INFO'" ;;
    esac
fi

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
# The UI test activates the running app (same process, the console stays captured) and taps the middle of its screen.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOUCH_BUILD="${FA_IOS_TOUCH_TEST_BUILD:-$ROOT/build/ios-touch-test}"
cmake -S "$ROOT/platforms/ios/touch-test" -B "$TOUCH_BUILD" -G Xcode -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_OSX_SYSROOT=iphonesimulator >"$OUT/touch-test.log" 2>&1 ||
    fail "touch: cannot generate the UI test project (platforms/ios/touch-test): see touch-test.log"
TEST_RUNNER_FA_TOUCH_BUNDLE_ID="$BUNDLE_ID" xcodebuild test -project "$TOUCH_BUILD/FactoriaTouch.xcodeproj" \
    -scheme FactoriaTouchHost -destination "id=$UDID" CODE_SIGNING_ALLOWED=NO \
    -test-timeouts-enabled YES -maximum-test-execution-time-allowance 120 >>"$OUT/touch-test.log" 2>&1 || {
    grep -E 'error|Test Case|failed' "$OUT/touch-test.log" | tail -n 20
    fail "touch: the UI test that taps the screen failed (lines above, full log in touch-test.log)"
}
grep -E "Test Case .* passed|Tap Application" "$OUT/touch-test.log" | tee -a "$OUT/summary.txt"
wait_for_log "input: first touch" 15 ||
    fail "touch: the UI test tapped the middle of the screen but the player logged no 'input: first touch'"
TOUCH="$(first_line 'input: first touch')"
echo "$TOUCH" | tee -a "$OUT/summary.txt"
alive || fail "touch: the app process $PID is gone after the tap"
IFS= read -r -d '' CHECK_TOUCH <<'PY'
import json, re, sys
line, project = sys.argv[1], sys.argv[2]
m = re.search(r"design \((-?[0-9.]+), (-?[0-9.]+)\)", line)
if not m:
    sys.exit(f"cannot read the design position in: {line}")
x, y = float(m.group(1)), float(m.group(2))
display = json.load(open(project)).get("display", {})
w, h, mode = display.get("width", 1280), display.get("height", 720), display.get("scaleMode", "fit")
if mode not in ("fit", "stretch"):
    print(f"position not checked: scaleMode '{mode}' shows more than the design area")
    sys.exit(0)
if abs(x - w / 2) > 0.03 * w or abs(y - h / 2) > 0.03 * h:
    sys.exit(f"the tap in the middle of the screen landed at design ({x:.0f}, {y:.0f}), expected about "
             f"({w / 2:.0f}, {h / 2:.0f}) for a {w}x{h} design (scaleMode {mode}): touch positions are converted wrong")
print(f"position ok: ({x:.0f}, {y:.0f}) is the middle of the {w}x{h} design")
PY
CHECKED="$(python3 -c "$CHECK_TOUCH" "$TOUCH" "$APP/game/factoria.json" 2>&1)" || fail "touch: $CHECKED"
echo "touch: $CHECKED" | tee -a "$OUT/summary.txt"

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
if grep -E '^\[ *[0-9.]+\] ERROR ' "$OUT/console.log"; then fail "the engine logged errors (lines above)"; fi
if ls ~/Library/Logs/DiagnosticReports/factoria_player* >/dev/null 2>&1; then fail "a crash report exists for factoria_player"; fi

# The display shows a picture, not a black or flat window (the log alone cannot tell).
has_picture "$OUT/screen.png" "display"

echo "---- run evidence (player console) ----" | tee -a "$OUT/summary.txt"
grep -E '(engine: Graphics|scene: Loaded|audio: |player: |input: |plugin|probe )' "$OUT/console.log" | tr -d '\r' | tee -a "$OUT/summary.txt"
echo "OK: $BUNDLE_ID ran on the simulator (pid $PID): rendered, audio stream, touch, suspend/resume, no crash." | tee -a "$OUT/summary.txt"
