#!/usr/bin/env bash
#
# Installs an exported FactorIA APK on the running Android emulator/device, starts it and asserts that the game
# really runs: the process is alive, the player logged its run marker ("60 frames rendered", see
# engine/runtime/src/runners.cpp), nothing crashed and the display shows a picture. CI runs it inside reactivecircus/android-emulator-runner
# (job `android-emulator`); it also works against any adb device.
#
#   ./scripts/android-smoke.sh <app-debug.apk> <applicationId> [timeoutSeconds] [outDir]
#
# Output (outDir, default build/android-smoke): logcat.txt (whole log), logcat-app.txt (only the app process),
# screen.png (what the display shows), summary.txt. Exit code 0 = the game runs.
set -uo pipefail

APK="${1:?usage: android-smoke.sh <apk> <applicationId> [timeoutSeconds] [outDir]}"
PKG="${2:?usage: android-smoke.sh <apk> <applicationId> [timeoutSeconds] [outDir]}"
TIMEOUT="${3:-120}"
OUT="${4:-build/android-smoke}"
MARKER="player: 60 frames rendered"

ADB="${ADB:-adb}"
mkdir -p "$OUT"

fail() {
    echo "FAIL: $*" | tee -a "$OUT/summary.txt"
    "$ADB" logcat -d -b all -v threadtime >"$OUT/logcat.txt" 2>/dev/null
    "$ADB" exec-out screencap -p >"$OUT/screen.png" 2>/dev/null
    echo "---- activity lifecycle (events buffer) and crash / player lines of the log ----"
    grep -E 'wm_(create|restart|pause|resume|finish|destroy)_activity|am_(crash|proc_died|kill)|factoria|Fatal signal|Abort message|FATAL EXCEPTION|AndroidRuntime|has died'         "$OUT/logcat.txt" | grep -v 'CompatibilityChange' | tail -n 80
    exit 1
}

app_pid() { "$ADB" shell pidof "$PKG" 2>/dev/null | tr -d '\r' | awk '{print $1}'; }

: >"$OUT/summary.txt"
echo "device: $("$ADB" shell getprop ro.product.model | tr -d '\r') / Android $("$ADB" shell getprop ro.build.version.release | tr -d '\r')" \
     "(API $("$ADB" shell getprop ro.build.version.sdk | tr -d '\r'), ABI $("$ADB" shell getprop ro.product.cpu.abi | tr -d '\r'))" |
    tee -a "$OUT/summary.txt"

"$ADB" install -r -t "$APK" 2>&1 | tee -a "$OUT/summary.txt"
"$ADB" shell pm list packages "$PKG" | grep -q "package:$PKG\$" || fail "$PKG is not installed after adb install"

# Right after the first boot the system is still provisioning (default roles, setup wizard -> home) for several
# seconds; an activity started in that window can be paused and destroyed by the system. Go home and let it settle.
"$ADB" shell input keyevent KEYCODE_HOME
sleep 20

"$ADB" logcat -b all -c
# NativeActivity is the only activity (platforms/android/app/src/main/AndroidManifest.xml). -W waits for the launch.
"$ADB" shell am start -W -n "$PKG/android.app.NativeActivity" 2>&1 | tee -a "$OUT/summary.txt"
STARTED_AT=$SECONDS
PID="$(app_pid)"
[ -n "$PID" ] || fail "no process for $PKG right after am start"
echo "pid $PID" | tee -a "$OUT/summary.txt"

# Wait for the run marker (software rendering in the emulator can be slow), failing early when the process dies.
found=0
while (( SECONDS - STARTED_AT < TIMEOUT )); do
    "$ADB" logcat -d -b all -v threadtime >"$OUT/logcat.txt"
    if grep -qF "$MARKER" "$OUT/logcat.txt"; then found=1; break; fi
    NOW="$(app_pid)"
    [ "$NOW" = "$PID" ] || fail "the app process $PID is gone before it logged '$MARKER' (now: '${NOW:-none}'): it crashed or quit"
    sleep 2
done
[ "$found" = 1 ] || fail "no '$MARKER' within ${TIMEOUT}s"
echo "marker after $((SECONDS - STARTED_AT))s" | tee -a "$OUT/summary.txt"

# Still alive a few seconds after the marker, same process (a crash + restart would change the pid).
sleep 5
NOW="$(app_pid)"
[ "$NOW" = "$PID" ] || fail "the app process $PID is gone 5s after the marker (now: '${NOW:-none}')"

"$ADB" logcat -d -b all -v threadtime >"$OUT/logcat.txt"
"$ADB" logcat -d -b all -v threadtime --pid="$PID" >"$OUT/logcat-app.txt" 2>/dev/null
"$ADB" exec-out screencap -p >"$OUT/screen.png" 2>/dev/null

# No crash: Java exceptions, native signals, ANRs, the process dying; no error-level line from the engine.
if grep -E "FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|tombstone" "$OUT/logcat-app.txt" >"$OUT/crash.txt" ||
   grep -E "ANR in $PKG|Process $PKG .*has died|Process: $PKG," "$OUT/logcat.txt" >>"$OUT/crash.txt"; then
    cat "$OUT/crash.txt"
    fail "crash markers in the log"
fi
if grep -E ' E factoria *:' "$OUT/logcat-app.txt" >"$OUT/errors.txt"; then
    cat "$OUT/errors.txt"
    fail "the engine logged errors (lines above)"
fi

# The display shows a picture, not a black or flat window (the log alone cannot tell).
SHOT="$(python3 "$(dirname "$0")/png_has_content.py" "$OUT/screen.png" 2>&1)" || fail "the display shows no picture: $SHOT"
echo "$SHOT" | tee -a "$OUT/summary.txt"

echo "---- run evidence (logcat, tag factoria) ----" | tee -a "$OUT/summary.txt"
grep -E 'factoria *: (engine: Graphics|scene: Loaded|player: )' "$OUT/logcat-app.txt" | tee -a "$OUT/summary.txt"
echo "OK: $PKG ran on the emulator (pid $PID), rendered frames, no crash." | tee -a "$OUT/summary.txt"
