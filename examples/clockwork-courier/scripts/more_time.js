// @ts-check
// "More time" on the retry screen: after the spring ran down the player may get 20 more seconds and carry on from the last
// checkpoint, once per attempt. The offer comes from scripts/ads.js (a rewarded ad, or free with "Remove ads"; no button
// when no ad can be shown). The retry screen is part of every level scene; the button is added here at run time so the eight
// scenes stay as they are:
//
//   install(flow)         level flow, onStart: creates the button inside "retry_panel_box", above the other buttons
//   onRetryShown(flow)    level flow, when the retry screen appears: shows the button (or hides it), and focuses it
//
// A level that continued is flagged: `flow.continued` is true and the level_completed event carries `continued: true`, so the
// leaderboards (scripts/services.js) skip it. Events: more_time_granted { level, seconds } (scripts/events.js).
import { world, ui, i18n } from "factoria";
import { EVENTS, emit } from "./events.js";
import * as ads from "./ads.js";

const BUTTON = "retry_more_time";

/** @param {any} flow the LevelFlow behaviour of the scene */
export function install(flow) {
  flow.moreTimeUsed = false;
  flow.continued = false;
  flow.askingForTime = false;
  const box = world.find("retry_panel_box");
  if (!box || world.find(BUTTON)) return;
  world.spawn({ id: BUTTON, active: false, components: { Button: { autoSize: true, text: "", layer: 302 } } }, { parent: box });
  // The layout stacks children in the order of the hierarchy: take the two stock buttons out and back in, behind the new one
  // (spawn cannot insert at an index, FB-0032).
  for (const id of ["retry_retry", "retry_title"]) world.find(id)?.setParent(box);
  ui.on("click", BUTTON, () => run(flow));
}

/** Shows or hides the button for the retry screen that just appeared. */
export function onRetryShown(flow) {
  const button = world.find(BUTTON);
  if (!button) return;
  const offer = flow.moreTimeUsed ? { mode: "none" } : ads.moreTimeOffer();
  button.active = offer.mode !== "none";
  if (!button.active) return;
  flow.moreTimeMode = offer.mode;
  refreshLabel(flow);
  try {
    ui.focus(button);
  } catch (e) {
    /* not focusable right now: the mouse and touch still work */
  }
}

/** Writes the button's label again (the offer's mode is kept in flow.moreTimeMode): also when the player changes language. */
export function refreshLabel(flow) {
  const button = world.find(BUTTON);
  if (!button || !button.active) return;
  const key = flow.moreTimeMode === "free" ? "ads.moreTimeFree" : "ads.moreTimeAd";
  button.get("Button").text = i18n.t(key, { count: ads.MORE_TIME_SECONDS });
}

/** Runs the offer; on success the level carries on. */
export async function run(flow) {
  if (flow.moreTimeUsed || flow.askingForTime || !flow.finished) return;
  flow.askingForTime = true;
  const panel = world.find(flow.retryId);
  if (panel) panel.active = false; // out of the way of the ad
  const r = await ads.requestMoreTime();
  flow.askingForTime = false;
  if (!r.granted) {
    if (panel) panel.active = true;
    onRetryShown(flow);
    return;
  }
  flow.moreTimeUsed = true;
  continueWithMoreTime(flow, ads.MORE_TIME_SECONDS);
}

/** Gives the spring `seconds` more and puts the courier back at the last checkpoint. */
export function continueWithMoreTime(flow, seconds) {
  const courier = flow.courier;
  flow.finished = false;
  flow.timer = -1;
  flow.pending = null;
  flow.continued = true;
  const panel = world.find(flow.retryId);
  if (panel) panel.active = false;
  flow.spring?.resume(seconds);
  if (courier) {
    courier.respawnAtCheckpoint();
    courier.locked = false;
    courier.isCaught = false;
    courier.anim?.trigger("recover");
  }
  emit(EVENTS.moreTimeGranted, { level: flow.levelId, seconds });
}
