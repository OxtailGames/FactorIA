// @ts-check
// The script the Android CI job adds to the game it runs in the emulator (.github/workflows/ci.yml, android-apk): it uses what a phone
// adds to the scripts, so scripts/android-smoke.sh can check it on a real Android. It logs the safe area, buzzes once, consumes the
// first press of the system Back button (the marker FA_SMOKE_BACK waits for after `adb shell input keyevent KEYCODE_BACK`) and lets
// the second one through, which ends the game like Android's default. Its game.on("quit") handler logs a marker (FA_SMOKE_QUIT) and
// counts the quits in storage with storage.setAsync; the next start logs that count ("probe quits stored=1" after the relaunch of a
// fresh install), which shows the write of the destroyed process reached the disk.
import { Behaviour, game, input, screen, storage } from "factoria";

export default class MobileProbe extends Behaviour {
  onStart() {
    const a = screen.safeArea;
    console.log(`probe safearea=${a.x},${a.y},${a.w},${a.h} of ${screen.size.x}x${screen.size.y}`);
    input.vibrate(0.05); // Vibrator through JNI; a failure is a warning in the log, never an error
    console.log("probe vibrate=sent");
    console.log(`probe quits stored=${storage.get("probe.quits", 0)}`);
    game.on("quit", () => {
      // Android: the activity is being destroyed (a relaunch, the second Back below); the engine writes the value before the
      // process ends.
      const n = storage.get("probe.quits", 0) + 1;
      storage.setAsync("probe.quits", n);
      console.log(`probe quit n=${n}`);
    });
    let presses = 0;
    input.onBack(() => {
      presses++;
      if (presses >= 2) {
        console.log(`probe back=passed n=${presses}`);
        return false; // not consumed: the game ends (the smoke test's last step)
      }
      console.log(`probe back=consumed n=${presses}`);
      return true;
    });
  }
}
