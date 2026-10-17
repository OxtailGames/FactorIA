// @ts-check
// The script the Android CI job adds to a game that carries the Google Play plugin (platforms/plugins/googleplay, .github/workflows/ci.yml,
// android-apk): it logs which backend the game runs, what the plugin's googleplay.status command says and what the plugin answers to a
// call that needs no Google account, so the C bridge, the JNI callbacks and the Java code (Billing, Play Games, Play Integrity are linked
// into the dex) really run on the emulator, which has no Google Play. A wrong answer is a script error.
import { Behaviour, fa, platform } from "factoria";

export default class GooglePlayProbe extends Behaviour {
  onStart() {
    console.log(`probe backend=${platform.backend}`);
    const status = fa.call("googleplay.status", {});
    console.log(`probe services=${JSON.stringify(status.services)}`);
    console.log(`probe playgames=${status.playGames.enabled} id=${status.playGames.projectId}`);
    console.log(`probe playservices=${status.playServices.available}`);
    console.log(`probe problems=${status.problems.length}`);
    if (platform.backend !== "googleplay" || !platform.has("purchases") || !platform.has("overlay")) {
      throw new Error(`probe: unexpected ${platform.backend} ${JSON.stringify(status)}`);
    }
    // Play Games without Google Play services is a teaching refusal, not a crash: the request went through the C bridge to the Java code,
    // which answered through JNI.
    platform.signIn().then(
      (p) => console.log(`probe signin=ok signedIn=${p.signedIn}`),
      (e) => console.log(`probe signin=${e.code}`),
    );
  }
}
