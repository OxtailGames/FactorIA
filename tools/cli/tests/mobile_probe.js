// @ts-check
// The script the Android CI job adds to the game it runs in the emulator (.github/workflows/ci.yml, android-apk): it uses what a phone
// adds to the scripts, so scripts/android-smoke.sh can check it on a real Android. It logs the safe area, buzzes once and consumes the
// system Back button, logging a marker the smoke test waits for after `adb shell input keyevent KEYCODE_BACK` (FA_SMOKE_BACK).
// Without a handler like this one Back would leave the game, which is the default and what the smoke test must not see here.
import { Behaviour, input, screen } from "factoria";

export default class MobileProbe extends Behaviour {
  onStart() {
    const a = screen.safeArea;
    console.log(`probe safearea=${a.x},${a.y},${a.w},${a.h} of ${screen.size.x}x${screen.size.y}`);
    input.vibrate(0.05); // Vibrator through JNI; a failure is a warning in the log, never an error
    console.log("probe vibrate=sent");
    let presses = 0;
    input.onBack(() => {
      presses++;
      console.log(`probe back=consumed n=${presses}`);
      return true;
    });
  }
}
