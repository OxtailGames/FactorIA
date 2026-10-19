// @ts-check
// Assist mode (Options > Accessibility): a slower game and invincibility. level.js asks here; pause_menu.js calls
// applySpeed() after a resume, because game.paused = false puts time.scale back to 1.
import { time } from "factoria";
import * as settings from "./settings.js";

/** The assist options as saved now: { speed: 0.6..1, invincible }. */
export function current() {
  return settings.load().assist;
}

/** True while any assist option is on: such a run is flagged `assisted: true` in `level_completed`. */
export function active() {
  const a = current();
  return a.speed < 1 || a.invincible;
}

/** Sets time.scale to the assist speed. Call it when gameplay (re)starts: a level start and a resume. */
export function applySpeed() {
  time.scale = current().speed;
}
