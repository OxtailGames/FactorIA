// @ts-check
// The script the Android CI job adds to a game that carries the AdMob plugin next to the Google Play one (platforms/plugins/admob,
// .github/workflows/ci.yml, android-apk): it logs which backend answers the ads, what the plugin's admob.status command says (the
// manifest's app id and test flag, written by the export) and the answer to a call that needs neither network nor consent, so the C
// bridge, the JNI callbacks and the Java code (the Mobile Ads SDK and UMP are linked into the dex) really run on the emulator, which
// has no Google Play. It does not wait for an ad: that needs Google's network. A wrong answer is a script error.
import { Behaviour, fa, platform } from "factoria";

export default class AdmobProbe extends Behaviour {
  onStart() {
    console.log(`probe adsbackend=${platform.adsBackend} store=${platform.backend}`);
    const status = fa.call("admob.status", {});
    console.log(`probe admob test=${status.test} audience=${status.audience} appId=${status.appId}`);
    console.log(`probe admob sdkReady=${status.sdkReady} problems=${status.problems.length}`);
    if (platform.adsBackend !== "admob" || !platform.has("ads") || platform.backend !== "googleplay") {
      throw new Error(`probe: unexpected backends ${platform.adsBackend} / ${platform.backend} ${JSON.stringify(status)}`);
    }
    // The age of the player goes through the C bridge to the Java code, which answers through JNI.
    platform.ads.setUnderAge(false).then(
      () => console.log("probe underage=ok"),
      (e) => console.log(`probe underage=${e.code}`),
    );
  }
}
