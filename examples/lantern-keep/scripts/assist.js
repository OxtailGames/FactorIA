// @ts-check
// Assist mode (Options > Accessibility): a slower game and invincibility. level.js asks here and applies the speed when a
// level starts; the options panel applies it when the player changes it while the game is paused. Pausing and resuming
// need no code: game.paused = false restores the time.scale the game had.
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

/** Sets time.scale to the assist speed. While the game is paused this only changes the speed that resuming restores. */
export function applySpeed() {
  time.scale = current().speed;
}
