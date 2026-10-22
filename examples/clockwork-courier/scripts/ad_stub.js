// @ts-check
// The stub ad provider and its test overlay: what scripts/ads.js uses while the store is the fake one. showRewarded() puts a
// full-screen "Test ad" panel over the game with a countdown; when it reaches zero the "Claim reward" button appears, "Skip"
// is always there. Tests drive it with game.click("ad_claim") / game.click("ad_skip"); a person sees what a rewarded ad flow
// looks like. A real ad SDK replaces the provider (ads.setProvider), this file then only serves the tests.
//
//   new StubAdProvider({ seconds })   seconds of countdown before the reward can be claimed (default 3)
//   StubAdProvider.shown              how many ads were shown (tests read it)
import { Behaviour, world, ui } from "factoria";

/** @type {((r: { rewarded: boolean, reason?: string }) => void) | null} */
let pending = null;

/** Closes the overlay and resolves the pending showRewarded(). */
function finish(rewarded, reason) {
  world.find("ad_overlay")?.destroy();
  const resolve = pending;
  pending = null;
  if (resolve) resolve(rewarded ? { rewarded: true } : { rewarded: false, reason });
}

export class StubAdProvider {
  /** @param {{ seconds?: number }} [options] */
  constructor(options = {}) {
    this.name = "test overlay";
    this.seconds = options.seconds ?? 3;
  }

  /** Total ads shown by every stub provider since the script context started. */
  static shown = 0;

  available() {
    return true;
  }

  /** @param {string} placement */
  showRewarded(placement) {
    // a scene load removes the overlay but not this module's state: an overlay that is gone is not an ad being shown
    if (pending && world.find("ad_overlay")) return Promise.resolve({ rewarded: false, reason: "busy" });
    pending = null;
    StubAdProvider.shown++;
    return new Promise((resolve) => {
      pending = resolve;
      world.spawn({
        id: "ad_overlay",
        components: {
          Panel: { size: [1280, 720], anchor: [0.5, 0.5], layer: 500, color: [0.02, 0.02, 0.05, 0.94], layout: "column", justify: "center", spacing: 16 },
          Script: { path: "scripts/ad_stub.js", props: { seconds: this.seconds, placement } },
        },
        children: [
          { id: "ad_title", components: { Text: { text: "", key: "ads.testAd", fontSize: 40, space: "screen", layer: 501, color: [1, 0.85, 0.3, 1] } } },
          { id: "ad_countdown", components: { Text: { text: "", fontSize: 28, space: "screen", layer: 501 } } },
          { id: "ad_claim", active: false, components: { Button: { autoSize: true, text: "", key: "ads.claim", layer: 502, autoFocus: true } } },
          { id: "ad_skip", components: { Button: { autoSize: true, text: "", key: "ads.skip", layer: 502 } } },
        ],
      });
    });
  }
}

/** The overlay entity's script: counts down, then lets the player claim. */
export default class AdOverlay extends Behaviour {
  /** Seconds of countdown. */
  seconds = 3;
  /** What the ad was shown for. */
  placement = "more_time";

  onStart() {
    this.left = this.seconds;
    this.claimed = false;
    ui.on("click", "ad_claim", () => finish(true));
    ui.on("click", "ad_skip", () => finish(false, "skipped"));
    this.refresh();
  }

  onUpdate(dt) {
    if (this.left > 0) {
      this.left = Math.max(0, this.left - dt);
      this.refresh();
    }
  }

  refresh() {
    const claim = world.find("ad_claim");
    const text = world.find("ad_countdown");
    if (claim && this.left <= 0 && !claim.active) {
      claim.active = true;
      try {
        ui.focus(claim);
      } catch (e) {
        /* not focusable right now: the mouse and touch still work */
      }
    }
    if (text) text.get("Text").text = this.left > 0 ? `${Math.ceil(this.left)}` : "";
  }
}
