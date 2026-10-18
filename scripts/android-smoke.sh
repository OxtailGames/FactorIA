#!/usr/bin/env bash
#
# Installs an exported FactorIA APK on the running Android emulator/device, starts it and asserts that the game
# really runs. CI runs it inside reactivecircus/android-emulator-runner (job `android-emulator`); it also works against
# any adb device.
#
#   ./scripts/android-smoke.sh <apk> <applicationId> [timeoutSeconds] [outDir]
#
# What it checks, in this order (each step fails with its own message and the evidence in outDir):
#   1. ready      the system finished booting (sys.boot_completed, boot animation, package manager, provisioning),
#                 the keyguard is gone and the launcher has the window focus; after the install, the broadcast queues
#                 are idle (`am wait-for-broadcast-idle`, API 30+). No fixed sleep.
#   2. run        the process is alive, the player logged its run marker ("60 frames rendered", see
#                 engine/runtime/src/runners.cpp), and is still the same process 5 s later.
#   3. audio      the player opened an audio output device ("audio: output device open") and the platform pulled
#                 samples from it ("audio: stream running"); "no audio output device available" fails.
#   4. touch      `input touchscreen tap` on the middle of the screen reaches the player ("input: first touch").
#   5. suspend    HOME key: "player: suspended", the process survives; `am start`: "player: resumed" and
#                 "player: 60 frames rendered after resume" (the surface and the EGL context were rebuilt and the
#                 game draws again), the game has the window focus, the screen shows a picture.
#   6. config     a configuration change (font scale) does not restart the activity: a restarted NativeActivity ends
#                 the process (sokol_app exits in onDestroy), see configChanges in AndroidManifest.xml.
#   7. no crash   no Java exception, native signal, ANR or engine error; the activity was never destroyed or
#                 relaunched during the run; the display shows a picture (a black window passes none of this).
#   8. relaunch   a change of the app's assets paths (`am update-appinfo`, what an overlay or a wallpaper-colour change
#                 sends) relaunches the activity, which no configChanges value prevents: the old process ends cleanly
#                 (no native signal) and the system starts the game again in a new process, which renders and has the
#                 window focus.
#   9. back       optional, only when the environment variable FA_SMOKE_BACK is set to the text the game logs when its
#                 input.onBack handler consumes the Back button: `input keyevent KEYCODE_BACK` must reach the game
#                 (the line is logged once more), and the game stays alive and keeps the window focus (a Back that
#                 nobody consumes would leave the game: Android's default, which the game here must not get).
#  10. expect     optional, only when the environment variable FA_SMOKE_EXPECT is set: one extended regular expression
#                 per line, and each must match a line of the log. CI uses it for what the game's own script logs when
#                 it calls its native plugin (the Java class of the plugin answered through JNI).
#
# Output (outDir, default build/android-smoke): logcat.txt (whole log), logcat-app.txt (only the app process),
# logcat-app-relaunched.txt (the process after step 8), screen.png (what the display shows), summary.txt, state.txt on
# failure. Exit code 0 = the game runs.
set -uo pipefail

USAGE="usage: android-smoke.sh <apk> <applicationId> [timeoutSeconds] [outDir]"
APK="${1:?$USAGE}"
PKG="${2:?$USAGE}"
TIMEOUT="${3:-120}"
OUT="${4:-build/android-smoke}"
MARKER="player: 60 frames rendered"
ACTIVITY="$PKG/android.app.NativeActivity"  # the only activity (platforms/android/app/src/main/AndroidManifest.xml)
HERE="$(dirname "$0")"

ADB="${ADB:-adb}"
mkdir -p "$OUT"
SUMMARY="$OUT/summary.txt"
: >"$SUMMARY"
PID=""

note() { echo "$*" | tee -a "$SUMMARY"; }

# ---- device queries (adb prints CRLF) -------------------------------------------------------------------------------
prop() { "$ADB" shell getprop "$1" 2>/dev/null | tr -d '\r'; }
setting() { "$ADB" shell settings get "$1" "$2" 2>/dev/null | tr -d '\r'; }   # <global|secure|system> <key>
# No early-exiting reader (grep -q, head) behind a producer in a pipeline: with pipefail the producer's SIGPIPE fails it.
focus_line() { local w; w="$("$ADB" shell dumpsys window 2>/dev/null | tr -d '\r')"; grep -m 1 'mCurrentFocus' <<<"$w"; }
focus_has() { [[ "$(focus_line)" == *"$1"* ]]; }
app_pid() { "$ADB" shell pidof "$PKG" 2>/dev/null | tr -d '\r' | awk '{print $1}'; }
snapshot_log() { "$ADB" logcat -d -b all -v threadtime >"$OUT/logcat.txt" 2>/dev/null; }
log_count() { snapshot_log; grep -cF -- "$1" "$OUT/logcat.txt"; }   # lines containing the text, whole run so far

fail() {
    echo "FAIL: $*" | tee -a "$SUMMARY"
    snapshot_log
    "$ADB" exec-out screencap -p >"$OUT/screen.png" 2>/dev/null
    {
        echo "== window focus =="; focus_line
        echo "== resumed / top activity =="; "$ADB" shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -E 'topResumedActivity|mResumedActivity|ResumedActivity:'
        echo "== configuration =="; "$ADB" shell am get-config 2>/dev/null
        echo "== sim / boot properties =="; for p in sys.boot_completed init.svc.bootanim gsm.sim.state gsm.operator.numeric; do echo "$p=$(prop $p)"; done
    } >"$OUT/state.txt" 2>&1
    cat "$OUT/state.txt"
    echo "---- activity lifecycle (events buffer), configuration changes, crash and player lines of the log ----"
    grep -E 'wm_[a-z_]*_activity|configuration_changed|am_(crash|proc_start|proc_died|kill)|factoria|Fatal signal|FORTIFY|Abort message|FATAL EXCEPTION|AndroidRuntime|has died|Force removing|exited (cleanly|due to signal)' \
        "$OUT/logcat.txt" | grep -v 'CompatibilityChange' | tail -n 100
    exit 1
}

# wait_for_log <needle> <seconds> [baseline]   returns 0 once the log has MORE than <baseline> (default 0) lines containing
# <needle>, 1 after <seconds>. Fails at once when the app process is gone (a crash, a quit, or a restart by the system).
wait_for_log() {
    local needle="$1" limit="$2" base="${3:-0}" t0=$SECONDS now
    while :; do
        snapshot_log
        (( $(grep -cF -- "$needle" "$OUT/logcat.txt") > base )) && return 0
        now="$(app_pid)"
        [ "$now" = "$PID" ] || fail "the app process $PID is gone before it logged '$needle' (now: '${now:-none}'): it crashed, quit or was restarted"
        (( SECONDS - t0 < limit )) || return 1
        sleep 2
    done
}

# wait_until <seconds> <description> <function>   polls <function> every 2 s and notes "<description> (Ns)"; 1 after
# <seconds>.
wait_until() {
    local limit="$1" what="$2" check="$3" t0=$SECONDS
    until "$check"; do
        (( SECONDS - t0 < limit )) || return 1
        sleep 2
    done
    note "$what ($((SECONDS - t0))s)"
}

has_picture() {  # has_picture <png> <what>
    local shot
    shot="$(python3 "$HERE/png_has_content.py" "$1" 2>&1)" || fail "$2: the display shows no picture: $shot"
    note "$2: $shot"
}

# ---- 1. ready -------------------------------------------------------------------------------------------------------
"$ADB" wait-for-device
note "device: $(prop ro.product.model) / Android $(prop ro.build.version.release) (API $(prop ro.build.version.sdk), ABI $(prop ro.product.cpu.abi))"

# An activity started while the system is still provisioning can be restarted under the app (see the configChanges note
# in AndroidManifest.xml); start only when the system is up, the keyguard is gone and the launcher is on screen.
boot_completed() { [ "$(prop sys.boot_completed)" = 1 ]; }
boot_anim_done() { [ "$(prop init.svc.bootanim)" != running ]; }   # empty with -no-boot-anim
package_manager_up() { [[ "$("$ADB" shell pm path android 2>/dev/null)" == package:* ]]; }
provisioned() { [ "$(setting global device_provisioned)" != 0 ] && [ "$(setting secure user_setup_complete)" != 0 ]; }
wait_until 240 "ready: sys.boot_completed=1" boot_completed || fail "the device never finished booting (sys.boot_completed='$(prop sys.boot_completed)')"
wait_until 90 "ready: boot animation stopped" boot_anim_done || fail "the boot animation is still running (init.svc.bootanim='$(prop init.svc.bootanim)')"
wait_until 120 "ready: package manager answers" package_manager_up || fail "'pm path android' does not answer: the package manager is not up"
wait_until 90 "ready: device provisioned" provisioned || fail "device_provisioned='$(setting global device_provisioned)' user_setup_complete='$(setting secure user_setup_complete)': the setup wizard is still running"

"$ADB" shell input keyevent KEYCODE_WAKEUP
"$ADB" shell wm dismiss-keyguard
"$ADB" shell input keyevent KEYCODE_HOME
HOME_PKG="$("$ADB" shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null |
            tr -d '\r' | tail -n 1 | cut -d/ -f1)"
launcher_focused() { focus_has "$HOME_PKG"; }
if [[ "$HOME_PKG" =~ ^[A-Za-z0-9_.]+$ ]]; then
    # Best effort: a launcher that never shows (an ANR dialog on top of it, say) is reported, the run goes on.
    wait_until 90 "ready: launcher $HOME_PKG has the window focus" launcher_focused || note "WARNING: the launcher $HOME_PKG never got the window focus; focus is: $(focus_line)"
else
    note "WARNING: could not find the home app ('$HOME_PKG'), not waiting for it"
fi
note "configuration: $("$ADB" shell am get-config 2>/dev/null | tr -d '\r')"

"$ADB" install -r -t "$APK" 2>&1 | tee -a "$SUMMARY"
INSTALLED="$("$ADB" shell pm list packages "$PKG" | tr -d '\r')"
grep -qxF "package:$PKG" <<<"$INSTALLED" || fail "$PKG is not installed after adb install"

# ActivityManager still delivers BOOT_COMPLETED after sys.boot_completed=1, and the install sends its own broadcasts
# (PACKAGE_ADDED, PACKAGE_CHANGED); both update the app's ApplicationInfo. An activity started in the middle of that was
# relaunched for an assets-path change (wm_relaunch_resume_activity ... 80000000), which no configChanges value can
# prevent, and the run failed with "no process right after am start". Start the game once every broadcast queue is idle.
SDK_LEVEL="$(prop ro.build.version.sdk)"
if (( ${SDK_LEVEL:-0} >= 30 )); then
    "$ADB" shell am wait-for-broadcast-idle >"$OUT/broadcast-idle.txt" 2>&1 &
    BROADCAST_WAIT=$!
    broadcasts_idle() { ! kill -0 "$BROADCAST_WAIT" 2>/dev/null; }
    if ! wait_until 120 "ready: broadcast queues idle after the install" broadcasts_idle; then
        kill "$BROADCAST_WAIT" 2>/dev/null
        fail "the broadcast queues were still busy 120s after the install ('am wait-for-broadcast-idle' did not return)"
    fi
    wait "$BROADCAST_WAIT" || fail "'am wait-for-broadcast-idle' failed: $(tr -d '\r' <"$OUT/broadcast-idle.txt")"
else
    note "WARNING: API ${SDK_LEVEL:-?} has no 'am wait-for-broadcast-idle' (API 30+); not waiting for the broadcast queues"
fi

# ---- 2. run ---------------------------------------------------------------------------------------------------------
"$ADB" logcat -G 16M >/dev/null 2>&1   # the emulator's default buffer is small enough to lose early lines on a busy system
"$ADB" logcat -b all -c
START="$("$ADB" shell am start -W -n "$ACTIVITY" 2>&1 | tr -d '\r')"
echo "$START" | tee -a "$SUMMARY"
STARTED_AT=$SECONDS
grep -qiE '^Error|Status: (error|timeout)' <<<"$START" && fail "am start did not start $ACTIVITY (output above)"
PID="$(app_pid)"
[ -n "$PID" ] || fail "no process for $PKG right after am start"
note "pid $PID"

# Wait for the run marker (software rendering in the emulator can be slow), failing early when the process dies.
wait_for_log "$MARKER" "$TIMEOUT" || fail "no '$MARKER' within ${TIMEOUT}s"
note "marker after $((SECONDS - STARTED_AT))s"

# Still alive a few seconds after the marker, same process (a crash + restart would change the pid).
sleep 5
[ "$(app_pid)" = "$PID" ] || fail "the app process $PID is gone 5s after the marker (now: '$(app_pid)')"

# ---- 3. audio -------------------------------------------------------------------------------------------------------
snapshot_log
if grep -F 'no audio output device available' "$OUT/logcat.txt"; then
    fail "audio: the player found no audio output device (line above); sokol_audio could not start the platform stream"
fi
grep -m 1 -F 'audio: output device open' "$OUT/logcat.txt" | tee -a "$SUMMARY" ||
    fail "audio: no 'audio: output device open' line in the log: the player never opened an audio device"
wait_for_log "audio: stream running" 30 || fail "audio: the device opened but the platform never called the stream callback within 30s"
grep -m 1 -F 'audio: stream running' "$OUT/logcat.txt" | tee -a "$SUMMARY"

# ---- 4. touch -------------------------------------------------------------------------------------------------------
"$ADB" exec-out screencap -p >"$OUT/screen.png" 2>/dev/null
SIZE="$(python3 -c 'import struct, sys; print(*struct.unpack(">II", open(sys.argv[1], "rb").read(24)[16:24]))' "$OUT/screen.png" 2>/dev/null)"
read -r WIDTH HEIGHT <<<"$SIZE"
TAP_X=$(( ${WIDTH:-600} / 2 )); TAP_Y=$(( ${HEIGHT:-600} / 2 ))
note "touch: tapping the middle of the ${WIDTH:-?}x${HEIGHT:-?} screen ($TAP_X, $TAP_Y)"
"$ADB" shell input touchscreen tap "$TAP_X" "$TAP_Y"
wait_for_log "input: first touch" 20 || fail "touch: 'input touchscreen tap $TAP_X $TAP_Y' never reached the player ('input: first touch' missing)"
grep -m 1 -F 'input: first touch' "$OUT/logcat.txt" | tee -a "$SUMMARY"

# ---- 5. suspend / resume --------------------------------------------------------------------------------------------
SUSPENDED0="$(log_count 'player: suspended')"
RESUMED0="$(log_count 'player: resumed')"
AFTER0="$(log_count 'frames rendered after resume')"
CREATED0="$(log_count 'ANDROID_NATIVE_ACTIVITY_ONNATIVEWINDOWCREATED')"
DESTROYED0="$(log_count 'ANDROID_NATIVE_ACTIVITY_ONNATIVEWINDOWDESTROYED')"
grep -qF 'ANDROID_MSG_CREATE' "$OUT/logcat.txt" && SOKOL_NAMES=1 || SOKOL_NAMES=0   # only a debug sokol_app logs its lifecycle by name

"$ADB" shell input keyevent KEYCODE_HOME
wait_for_log "player: suspended" 30 "$SUSPENDED0" || fail "suspend: the HOME key never suspended the player ('player: suspended' missing)"
note "suspend: focus is now: $(focus_line)"
# Paused is not stopped: bring the game back only after the system took its surface away, or the rebuild is not tested.
if [ "$SOKOL_NAMES" = 1 ]; then
    wait_for_log "ANDROID_NATIVE_ACTIVITY_ONNATIVEWINDOWDESTROYED" 20 "$DESTROYED0" ||
        fail "suspend: the system did not destroy the game's native window within 20s of the HOME key"
fi
[ "$(app_pid)" = "$PID" ] || fail "suspend: the app process $PID died when it went to the background (now: '$(app_pid)')"

"$ADB" shell am start -W -n "$ACTIVITY" 2>&1 | tr -d '\r' | tee -a "$SUMMARY"
wait_for_log "player: resumed" 30 "$RESUMED0" || fail "resume: 'player: resumed' missing after bringing the app back"
wait_for_log "player: 60 frames rendered after resume" 60 "$AFTER0" ||
    fail "resume: the player did not draw 60 frames within 60s after coming back (the surface or the GL context was not restored)"
[ "$(app_pid)" = "$PID" ] || fail "resume: the app process changed from $PID to '$(app_pid)': the system restarted the app"
focus_has "$PKG" || fail "resume: the game does not have the window focus: $(focus_line)"
if [ "$SOKOL_NAMES" = 1 ]; then
    (( $(log_count 'ANDROID_NATIVE_ACTIVITY_ONNATIVEWINDOWCREATED') > CREATED0 )) ||
        fail "resume: the system gave the game no new native window"
    note "resume: the native window was destroyed and created again, and the GL context drew 60 frames on the new surface"
fi
"$ADB" exec-out screencap -p >"$OUT/screen-resumed.png" 2>/dev/null
has_picture "$OUT/screen-resumed.png" "resume"

# ---- 6. configuration change ----------------------------------------------------------------------------------------
# Not listed in configChanges before: Android restarted the activity, which ends a sokol_app process.
change_font_scale() {
    local before
    before="$(log_count 'configuration_changed')"
    "$ADB" shell settings put system font_scale "$1"
    wait_for_log "configuration_changed" 15 "$before" || note "WARNING: no configuration_changed event after font_scale=$1 (the log tag may differ); settling for 5s instead"
    sleep 3   # a restart (pause, stop, destroy, process exit) takes well under this
    [ "$(app_pid)" = "$PID" ] || fail "config: font_scale=$1 ended the app process $PID (now: '$(app_pid)'): the activity was restarted instead of handling the change"
}
trap '"$ADB" shell settings put system font_scale 1.0 >/dev/null 2>&1' EXIT   # a device must not keep it
change_font_scale 1.3
change_font_scale 1.0
note "config: two font scale changes, the process $PID and its activity survived"

# ---- 7. no crash ----------------------------------------------------------------------------------------------------
snapshot_log
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
# The activity must never have been destroyed or relaunched (the system restarting it is the failure this guards).
if grep -E "wm_(destroy|relaunch)[a-z_]*_activity.*$PKG" "$OUT/logcat.txt" >"$OUT/restarts.txt"; then
    cat "$OUT/restarts.txt"
    fail "the system destroyed or relaunched the activity during the run (lines above)"
fi

# The display shows a picture, not a black or flat window (the log alone cannot tell).
has_picture "$OUT/screen.png" "display"

echo "---- run evidence (logcat, tag factoria) ----" | tee -a "$SUMMARY"
grep -E 'factoria *: (engine: Graphics|scene: Loaded|audio: |input: |player: )' "$OUT/logcat-app.txt" | tee -a "$SUMMARY"

# ---- 8. relaunch ----------------------------------------------------------------------------------------------------
# A change of the assets paths (wallpaper colours or theme on Android 12+, an overlay turned on or off) relaunches every
# activity, and no configChanges value opts out of it. A destroyed NativeActivity ends a sokol_app process. That exit
# used to run the C++ static destructors under running threads (SIGABRT, "pthread_mutex_lock called on a destroyed
# mutex"), and Android then dropped the activity of the dead process, so the game vanished. The engine now ends the
# process with _exit (engine/platform/src/sokol_impl.c), and the activity is stateNotNeeded (AndroidManifest.xml), so
# the system starts the game again in a new process. `am update-appinfo` sends the app the ApplicationInfo update that
# an overlay change sends, without changing the device.
OLD_PID="$PID"
relaunch_count() { snapshot_log; grep -cE "wm_relaunch[a-z_]*_activity.*$PKG" "$OUT/logcat.txt"; }
RELAUNCH0="$(relaunch_count)"
MARKER0="$(log_count "$MARKER")"
USER_ID="$("$ADB" shell am get-current-user 2>/dev/null | tr -d '\r')"
[[ "$USER_ID" =~ ^[0-9]+$ ]] || USER_ID=0
"$ADB" shell am update-appinfo "$USER_ID" "$PKG" 2>&1 | tr -d '\r' | tee -a "$SUMMARY"
relaunched() { (( $(relaunch_count) > RELAUNCH0 )); }
wait_until 20 "relaunch: the system relaunched the activity" relaunched ||
    fail "relaunch: 'am update-appinfo $USER_ID $PKG' did not relaunch the activity within 20s (no wm_relaunch_*_activity event)"
rendered_again() { (( $(log_count "$MARKER") > MARKER0 )); }
wait_until "$TIMEOUT" "relaunch: '$MARKER' again" rendered_again ||
    fail "relaunch: no new '$MARKER' within ${TIMEOUT}s: the game did not come back after the relaunch (process now: '$(app_pid)')"
PID="$(app_pid)"
[ -n "$PID" ] || fail "relaunch: no process for $PKG after the relaunch"
if [ "$PID" = "$OLD_PID" ]; then
    note "relaunch: the process $PID handled the relaunch"
else
    note "relaunch: the process $OLD_PID ended, the system started the game again as pid $PID"
fi
sleep 3
[ "$(app_pid)" = "$PID" ] || fail "relaunch: the app process $PID is gone 3s after it rendered (now: '$(app_pid)')"
focus_has "$PKG" || fail "relaunch: the game does not have the window focus: $(focus_line)"

snapshot_log
"$ADB" logcat -d -b all -v threadtime --pid="$OLD_PID" >"$OUT/logcat-app.txt" 2>/dev/null   # now with its end
"$ADB" logcat -d -b all -v threadtime --pid="$PID" >"$OUT/logcat-app-relaunched.txt" 2>/dev/null
# The old process ended without a signal and without running the engine's teardown on a dead GL context (what the
# static destructors did); neither process crashed, the new one logged no engine error.
if grep -E "FATAL EXCEPTION|Fatal signal|FORTIFY|SIGSEGV|SIGABRT|tombstone|OpenGL ES API with no current context" \
        "$OUT/logcat-app.txt" "$OUT/logcat-app-relaunched.txt" >"$OUT/crash.txt" ||
   grep -E "ANR in $PKG|Process: $PKG,|am_crash: \[[0-9]+,[0-9]+,$PKG,|Process $OLD_PID exited due to signal" \
        "$OUT/logcat.txt" >>"$OUT/crash.txt"; then
    cat "$OUT/crash.txt"
    fail "relaunch: crash markers in the log (lines above)"
fi
if grep -E ' E factoria *:' "$OUT/logcat-app-relaunched.txt" >"$OUT/errors.txt"; then
    cat "$OUT/errors.txt"
    fail "relaunch: the engine logged errors after the relaunch (lines above)"
fi
grep -m 1 -E "Process $OLD_PID exited cleanly" "$OUT/logcat.txt" | tee -a "$SUMMARY"
"$ADB" exec-out screencap -p >"$OUT/screen-relaunched.png" 2>/dev/null
has_picture "$OUT/screen-relaunched.png" "relaunch"

# ---- 9. back --------------------------------------------------------------------------------------------------------
# The Back button (engine/platform/src/mobile_android.cpp): the player consumes it and the game's input.onBack handler
# decides. wait_for_log fails at once when the process ends, which is what an unconsumed Back (or a Back the player
# did not see and Android handled by leaving the activity) looks like.
if [ -n "${FA_SMOKE_BACK:-}" ]; then
    BACK0="$(log_count "$FA_SMOKE_BACK")"
    "$ADB" shell input keyevent KEYCODE_BACK
    wait_for_log "$FA_SMOKE_BACK" 20 "$BACK0" ||
        fail "back: 'input keyevent KEYCODE_BACK' never reached the game's input.onBack handler ('$FA_SMOKE_BACK' missing)"
    grep -F -- "$FA_SMOKE_BACK" "$OUT/logcat.txt" | tail -n 1 | tee -a "$SUMMARY"
    sleep 3
    [ "$(app_pid)" = "$PID" ] || fail "back: the app process $PID is gone 3s after Back (now: '$(app_pid)'): Back was not consumed"
    focus_has "$PKG" || fail "back: the game lost the window focus after Back: $(focus_line)"
    note "back: KEYCODE_BACK reached input.onBack, the game consumed it and stayed"
fi

# ---- 10. expect -----------------------------------------------------------------------------------------------------
# What the game itself has to have logged (FA_SMOKE_EXPECT, one pattern per line), checked against the whole log.
if [ -n "${FA_SMOKE_EXPECT:-}" ]; then
    snapshot_log
    while IFS= read -r pattern; do
        [ -n "$pattern" ] || continue
        grep -m 1 -E -- "$pattern" "$OUT/logcat.txt" | tee -a "$SUMMARY" ||
            fail "expect: no line of the log matches '$pattern' (FA_SMOKE_EXPECT): the game did not log what it should have"
    done <<<"$FA_SMOKE_EXPECT"
fi

note "OK: $PKG ran on the emulator (pid $OLD_PID, pid $PID after the relaunch): rendered, audio stream, touch, suspend/resume, configuration change, relaunch, no crash."
