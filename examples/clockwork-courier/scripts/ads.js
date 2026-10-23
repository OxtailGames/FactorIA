// @ts-check
// The rewarded "more time" of the retry screen, on top of the engine's ads service (`platform.ads`; the placement "more_time" is
// declared in factoria.json "platform.ads.placements"). While the store is the fake one the engine answers with a scripted test ad
// (tests choose its outcome with game.platform.ad(...)); a real build answers through the ad SDK of its platform plugin.
//
//   moreTimeOffer()    { mode: "free" | "ad" | "none" }: what the retry screen offers (see below)
//   adReady()          Promise<boolean>: an ad can be shown now (loaded, consent given)
//   requestMoreTime()  runs the offer: resolves { granted, mode, reason? }
//   adsRemoved()       true when the player bought "Remove ads"
//
// The "more time" offer: with "Remove ads" the button stays and is FREE (the player paid so that no ad stands between them
// and the game); without it the button is "Watch an ad" when the platform offers ads; with no ads service there is no button.
import { platform } from "factoria";
import * as store from "./store.js";

/** Seconds of spring a rewarded "more time" gives. */
export const MORE_TIME_SECONDS = 20;
/** The placement of factoria.json. */
export const PLACEMENT = "more_time";

export function adsRemoved() {
  return store.noAds();
}

/** @returns {{ mode: "free" | "ad" | "none" }} */
export function moreTimeOffer() {
  if (adsRemoved()) return { mode: "free" };
  return { mode: platform.has("ads") ? "ad" : "none" };
}

/** True when an ad can be shown now. */
export async function adReady() {
  try {
    return await platform.ads.available(PLACEMENT);
  } catch (e) {
    return false;
  }
}

/** @returns {Promise<{ granted: boolean, mode: string, reason?: string }>} */
export async function requestMoreTime() {
  const { mode } = moreTimeOffer();
  if (mode === "none") return { granted: false, mode, reason: "noProvider" };
  if (mode === "free") return { granted: true, mode };
  try {
    const r = await platform.ads.showRewarded(PLACEMENT);
    return r.rewarded ? { granted: true, mode } : { granted: false, mode, reason: r.reason ?? "skipped" };
  } catch (e) {
    return { granted: false, mode, reason: "failed" };
  }
}
