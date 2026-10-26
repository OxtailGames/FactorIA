// @ts-check
// Reads the input of one player for this frame: where to walk, whether the dig button is down and whether a torch was asked for.
// The device of the player (players.js) decides which input counts: a keys or pad player is `input.player(id)` of the engine,
// the project's actions read from its own key scheme or gamepad with its own bindings (controls.js), so up to four miners can
// share one keyboard and several pads without reading each other's keys. A player on `{ kind: "any" }` reads the global
// input: the project's actions, which the keyboard (WASD or arrows, Space or J) and every gamepad (left stick or d-pad, A or X) feed.
import { input, world } from "factoria";
import { holdModeOf } from "../settings.js";

/**
 * @typedef {object} MinerInput
 * @property {number} x      -1 left .. 1 right.
 * @property {number} y      -1 down .. 1 up (the world's +Y).
 * @property {boolean} dig   The dig action is on: the button is held ("hold" mode), or it was pressed an odd number of times since the last stop ("toggle" mode, Options > Access; a player who cannot hold a button down).
 * @property {boolean} torch  The torch button went down this frame (a press, not a hold).
 */

/** Limits a vector to length 1 (two keys at once do not walk faster; a half-tilted stick stays slower). */
function clamp(x, y) {
  const len = Math.hypot(x, y);
  return len > 1 ? { x: x / len, y: y / len } : { x, y };
}

/** Toggle mode, by player id: the dig button as last read (to find the press) and whether the toggle is on. */
const digToggle = new Map();

/** Turns every dig toggle off (a new shift, a miner that went down). */
export function resetToggles() {
  digToggle.clear();
}

/** Turns the dig toggle of a player off. */
export function stopDig(playerId) {
  digToggle.delete(playerId);
}

/** Whether the dig toggle of a player is on right now (tests, the HUD). */
export function digToggled(playerId) {
  return !!digToggle.get(playerId)?.on;
}

/**
 * The dig action of a player from the raw button: the button itself in "hold" mode; in "toggle" mode a press turns it on and the
 * next press turns it off. A frame is read once (the same answer if read twice).
 */
function digOf(player, down) {
  if (holdModeOf(player.id) !== "toggle") {
    digToggle.delete(player.id);
    return down;
  }
  const was = digToggle.get(player.id) ?? { down: false, on: false, frame: -1 };
  if (was.frame === world.frame) return was.on;
  const on = down && !was.down ? !was.on : was.on;
  digToggle.set(player.id, { down, on, frame: world.frame });
  return on;
}

/**
 * @param {import("./players.js").Player} player
 * @returns {MinerInput}
 */
export function readInput(player) {
  const d = player.device;
  if (d.kind === "any") {
    const v = clamp(input.axis("move_left", "move_right"), input.axis("move_down", "move_up"));
    return { ...v, dig: digOf(player, input.down("dig")), torch: input.pressed("torch") };
  }
  // keys and pads: the engine's actions of this player, read from its own device with its own bindings (the defaults of the
  // key scheme in factoria.json, or what the player rebound in Options > Controls; controls.js)
  const me = input.player(player.id);
  const v = me.vector("move_left", "move_right", "move_down", "move_up");
  return { x: v.x, y: v.y, dig: digOf(player, me.down("dig")), torch: me.pressed("torch") };
}
