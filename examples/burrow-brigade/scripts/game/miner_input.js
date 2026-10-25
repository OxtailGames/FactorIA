// @ts-check
// Reads the input of one player for this frame: where to walk and whether the dig button is down. The device of the player
// (players.js) decides which input counts, so up to four miners can share one keyboard and several pads without reading each
// other's keys. P1 has one player on `{ kind: "any" }`: the project's actions, which the keyboard (WASD or arrows, Space or J)
// and every gamepad (left stick or d-pad, A or X) feed.
import { input } from "factoria";
import { KEY_SCHEMES } from "./players.js";

/**
 * @typedef {object} MinerInput
 * @property {number} x      -1 left .. 1 right.
 * @property {number} y      -1 down .. 1 up (the world's +Y).
 * @property {boolean} dig   The dig button is held.
 */

/** Limits a vector to length 1 (two keys at once do not walk faster; a half-tilted stick stays slower). */
function clamp(x, y) {
  const len = Math.hypot(x, y);
  return len > 1 ? { x: x / len, y: y / len } : { x, y };
}

/**
 * @param {import("./players.js").Player} player
 * @returns {MinerInput}
 */
export function readInput(player) {
  const d = player.device;
  if (d.kind === "keys") {
    const k = KEY_SCHEMES[d.scheme];
    const v = clamp((input.keyDown(k.right) ? 1 : 0) - (input.keyDown(k.left) ? 1 : 0), (input.keyDown(k.up) ? 1 : 0) - (input.keyDown(k.down) ? 1 : 0));
    return { ...v, dig: input.keyDown(k.dig) };
  }
  if (d.kind === "pad") {
    const pad = input.gamepad(d.index);
    const x = pad.axis("LeftX") + (pad.down("DpadRight") ? 1 : 0) - (pad.down("DpadLeft") ? 1 : 0);
    const y = pad.axis("LeftY") + (pad.down("DpadUp") ? 1 : 0) - (pad.down("DpadDown") ? 1 : 0);
    return { ...clamp(x, y), dig: pad.down("A") || pad.down("X") };
  }
  const v = clamp(input.axis("move_left", "move_right"), input.axis("move_down", "move_up"));
  return { ...v, dig: input.down("dig") };
}
