// @ts-check
// Rewarded ads behind one module. The engine has no ads API (nothing to show an ad with, no consent flow), so the game talks
// to an ad PROVIDER, an object with this shape, and everything else (the retry screen, the tests) only calls this module:
//
//   provider = {
//     name: string,                                   "test overlay", "AdMob"...
//     available(): boolean,                           an ad can be shown now (loaded, consent given, network up)
//     showRewarded(placement): Promise<{ rewarded: boolean, reason?: string }>
//                                                     shows a full-screen ad; resolves when it closes: rewarded true only when
//                                                     the player watched it to the end. reason: "skipped", "failed", "noFill"
//   }
//
// Which provider runs: the test overlay (scripts/ad_stub.js) while the store is the fake one (`platform.backend === "fake"`,
// the development run), none otherwise (a build without an ad SDK shows no ad offer). A real SDK plugin calls setProvider()
// at start-up with an object of this shape. The ads API the engine should have is FB-0023 in ENGINE_FEEDBACK.json.
//
//   moreTimeOffer()    { mode: "free" | "ad" | "none" }: what the retry screen offers (see below)
//   requestMoreTime()  runs the offer: resolves { granted, mode, reason? }
//   adsRemoved()       true when the player bought "Remove ads"
//
// The "more time" offer: with "Remove ads" the button stays and is FREE (the player paid so that no ad stands between them
// and the game); without it the button is "Watch an ad" when a provider can show one; with no provider there is no button.
import { platform } from "factoria";
import * as store from "./store.js";
import { StubAdProvider } from "./ad_stub.js";

/** Seconds of spring a rewarded "more time" gives. */
export const MORE_TIME_SECONDS = 20;

/** @type {any} */
let custom = null;
let stub = null;

/** Installs an ad provider (a real SDK plugin); null goes back to the default. */
export function setProvider(provider) {
  custom = provider;
}

/** The provider in use, or null when the game cannot show ads. */
export function provider() {
  if (custom) return custom;
  if (platform.backend !== "fake") return null;
  stub ??= new StubAdProvider();
  return stub;
}

export function adsRemoved() {
  return store.noAds();
}

/** @returns {{ mode: "free" | "ad" | "none" }} */
export function moreTimeOffer() {
  if (adsRemoved()) return { mode: "free" };
  const p = provider();
  return { mode: p && p.available() ? "ad" : "none" };
}

/** @returns {Promise<{ granted: boolean, mode: string, reason?: string }>} */
export async function requestMoreTime() {
  const { mode } = moreTimeOffer();
  if (mode === "none") return { granted: false, mode, reason: "noProvider" };
  if (mode === "free") return { granted: true, mode };
  try {
    const r = await /** @type {any} */ (provider()).showRewarded("more_time");
    return r.rewarded ? { granted: true, mode } : { granted: false, mode, reason: r.reason ?? "skipped" };
  } catch (e) {
    return { granted: false, mode, reason: "failed" };
  }
}
