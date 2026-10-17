// @ts-check
// The script the iOS CI job adds to a game that carries the Apple plugin (platforms/plugins/apple, scripts/ios-smoke.sh with
// FA_IOS_APPLE_PROBE=1): it logs which backend the game runs and what the plugin's apple.status command says, and asks the
// plugin for something that needs no Apple Account, so the Swift code, StoreKit and Game Center are really linked and running
// in the simulator. A wrong answer is a script error.
import { Behaviour, fa, platform } from "factoria";

export default class AppleProbe extends Behaviour {
  onStart() {
    console.log(`probe backend=${platform.backend}`);
    const status = fa.call("apple.status", {});
    console.log(`probe apple=${JSON.stringify({ platform: status.platform, payments: status.canMakePayments, player: status.gameCenter.signedIn })}`);
    if (platform.backend !== "apple" || status.platform !== "ios") throw new Error(`probe: unexpected ${platform.backend} ${JSON.stringify(status)}`);
    // Game Center before the sign-in is a teaching refusal, not a crash: the request went through the Swift plugin.
    platform.achievements.unlock("first_win").then(
      () => console.log("probe unlock=ok"),
      (e) => console.log(`probe unlock=${e.code}`),
    );
  }
}
