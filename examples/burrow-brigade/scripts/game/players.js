// @ts-check
// The players registry: who is in the mine (1 to 4 miners), with which input device and colour, and in which state.
// P1 registers one player on the project's input actions (keyboard or any gamepad). The code that moves a miner reads only
// its player record, so the local co-op package (P3) adds players here, with `{ kind: "keys" }` and `{ kind: "pad" }`
// devices, and nothing in the miner changes.
import * as events from "./events.js";

export const MAX_PLAYERS = 4;

/** Hearts a miner starts every shift with. */
export const MAX_HP = 3;
/** Seconds a miner cannot be hurt again after a hit. */
export const HURT_GRACE = 1.2;

/** Lamp and marker colour of player 0..3 (rgba 0..1). */
export const PLAYER_COLORS = Object.freeze([
  [1.0, 0.82, 0.4, 1],
  [0.45, 0.8, 1.0, 1],
  [0.55, 1.0, 0.5, 1],
  [1.0, 0.55, 0.8, 1],
]);

/** The key schemes a keyboard player can use. P1 uses the project's actions instead (`{ kind: "any" }`). */
export const KEY_SCHEMES = Object.freeze({
  wasd: { left: "A", right: "D", up: "W", down: "S", dig: "Space", torch: "E" },
  arrows: { left: "Left", right: "Right", up: "Up", down: "Down", dig: "Enter", torch: "RightShift" },
  ijkl: { left: "J", right: "L", up: "I", down: "K", dig: "U", torch: "O" },
  // The whole keyboard for one player (the join screen's Enter): WASD or the arrows, Space or J to dig, T or E for a torch.
  // controls.js adds the second key of each action; the names here are the first ones.
  keyboard: { left: "A", right: "D", up: "W", down: "S", dig: "Space", torch: "T" },
});

/**
 * Which input drives a player:
 *  - `{ kind: "any" }`: the project's actions (move_left ... dig in factoria.json): the keyboard and every gamepad. One player only.
 *  - `{ kind: "keys", scheme: "wasd" | "arrows" | "ijkl" | "keyboard" }`: that block of keys ("keyboard": the whole keyboard, what the join screen gives).
 *  - `{ kind: "pad", index: 0..3 }`: that gamepad (left stick or d-pad to move, A or X to dig, B or Y to place a torch).
 * @typedef {{kind: "any"} | {kind: "keys", scheme: keyof typeof KEY_SCHEMES} | {kind: "pad", index: number}} Device
 */

/**
 * @typedef {object} Player
 * @property {number} id            0..3, also the index of its colour, its miner picture and its lamp in the run state.
 * @property {string} name          "P1".."P4".
 * @property {Device} device
 * @property {number[]} color       rgba of its lamp light and the ring under its feet.
 * @property {"active"|"lift"|"down"} state  active: playing; lift: standing on the exit lift; down: out of play (hazards and enemies, P2).
 * @property {number} hp            Hearts left (MAX_HP at the start of a shift). `hurt` takes them; at 0 the miner goes down.
 * @property {number} invulnerable  Seconds left in which `hurt` does nothing (the miner counts it down, miner.js).
 */

/** @type {Player[]} */
let list = [];

/**
 * Adds a player in the lowest free slot.
 * @param {{device?: Device, name?: string, color?: number[]}} [opts]  Default device: `{ kind: "any" }`.
 * @returns {Player}
 */
export function add(opts = {}) {
  if (list.length >= MAX_PLAYERS) throw new Error(`the mine has room for ${MAX_PLAYERS} miners and all are taken. Remove one first (players.remove(id)).`);
  const device = opts.device ?? { kind: "any" };
  if (device.kind === "any" && list.some((p) => p.device.kind === "any")) throw new Error("only one player can use { kind: \"any\" } (the project's input actions); give the others { kind: \"keys\", scheme } or { kind: \"pad\", index }.");
  if (device.kind === "keys" && !(device.scheme in KEY_SCHEMES)) throw new Error(`unknown key scheme '${device.scheme}': use ${Object.keys(KEY_SCHEMES).join(", ")}.`);
  if (device.kind === "pad" && !(Number.isInteger(device.index) && device.index >= 0 && device.index < MAX_PLAYERS)) throw new Error(`gamepad index must be 0..${MAX_PLAYERS - 1}, got ${device.index}.`);
  let id = 0;
  while (list.some((p) => p.id === id)) id++;
  const player = { id, name: opts.name ?? `P${id + 1}`, device, color: opts.color ?? [...PLAYER_COLORS[id]], state: /** @type {"active"} */ ("active"), hp: MAX_HP, invulnerable: 0 };
  list.push(player);
  list.sort((a, b) => a.id - b.id);
  events.emit("playerAdded", { player });
  return player;
}

/**
 * Gives a player another device (a miner handed to a controller that is still plugged in). Emits `playerDevice`.
 * @param {number} id
 * @param {Device} device
 */
export function setDevice(id, device) {
  const player = get(id);
  if (!player) throw new Error(`no player ${id}: the players are ${list.map((p) => p.id).join(", ") || "(none)"}.`);
  if (device.kind === "any") throw new Error("setDevice: give { kind: \"keys\", scheme } or { kind: \"pad\", index }; { kind: \"any\" } is only for the first player of a one-player game.");
  if (device.kind === "keys" && !(device.scheme in KEY_SCHEMES)) throw new Error(`unknown key scheme '${device.scheme}': use ${Object.keys(KEY_SCHEMES).join(", ")}.`);
  if (device.kind === "pad" && !(Number.isInteger(device.index) && device.index >= 0 && device.index < MAX_PLAYERS)) throw new Error(`gamepad index must be 0..${MAX_PLAYERS - 1}, got ${device.index}.`);
  const from = player.device;
  player.device = device;
  events.emit("playerDevice", { player, from, to: device });
}

/** Removes a player (no-op when absent). */
export function remove(id) {
  const player = get(id);
  if (!player) return;
  list = list.filter((p) => p.id !== id);
  events.emit("playerRemoved", { player });
}

/** The player with this id, or null. */
export function get(id) {
  return list.find((p) => p.id === id) ?? null;
}

/** Every player, ordered by id. The array is a copy; the players are live records. */
export function all() {
  return [...list];
}

/** How many players there are. */
export function count() {
  return list.length;
}

/** Players still in play: not down. */
export function alive() {
  return list.filter((p) => p.state !== "down");
}

/**
 * Changes a player's state and tells the bus (`playerState`, and `playerDown` for "down").
 * @param {number} id
 * @param {"active"|"lift"|"down"} state
 * @param {string} [cause]  Why, for the `playerDown` event: "drowned", "burned", "caveIn", "beetle", "king"... (default "unknown").
 */
export function setState(id, state, cause = "unknown") {
  const player = get(id);
  if (!player) throw new Error(`no player ${id}: the players are ${list.map((p) => p.id).join(", ") || "(none)"}.`);
  if (!["active", "lift", "down"].includes(state)) throw new Error(`unknown player state '${state}': use active, lift or down.`);
  if (player.state === state) return;
  const from = player.state;
  player.state = state;
  events.emit("playerState", { player, from, to: state });
  if (state === "down") events.emit("playerDown", { player, cause });
}

/** Hearts a revived miner gets back, and the seconds it cannot be hurt afterwards. */
export const REVIVE_HP = 1;
export const REVIVE_GRACE = 2;

/**
 * Gets a downed miner up again with `REVIVE_HP` heart and a short grace. Does nothing for a miner who is not down. Emits
 * `playerState` (down -> active) and `playerRevived`. Returns true when the miner got up.
 * @param {number} id
 * @param {number} [by]  The player id of the friend who did it (-1: nobody in particular).
 */
export function revive(id, by = -1) {
  const player = get(id);
  if (!player || player.state !== "down") return false;
  player.hp = REVIVE_HP;
  player.invulnerable = REVIVE_GRACE;
  setState(id, "active", "revived");
  events.emit("playerRevived", { player, by, hp: player.hp });
  return true;
}

/**
 * Hurts a miner: takes `amount` hearts, tells the bus (`playerHurt`) and puts the miner down at 0 hearts. Does nothing to a
 * miner who is down, on the lift, or still in the grace seconds after a hit. Returns true when the hit landed.
 * @param {number} id
 * @param {number} amount
 * @param {string} cause  "beetle", "king"... (it becomes the `playerDown` cause when this was the last heart).
 */
export function hurt(id, amount, cause) {
  const player = get(id);
  if (!player || player.state !== "active" || player.invulnerable > 0) return false;
  player.hp = Math.max(0, player.hp - amount);
  player.invulnerable = HURT_GRACE;
  events.emit("playerHurt", { player, hp: player.hp, cause });
  if (player.hp <= 0) setState(id, "down", cause);
  return true;
}

/** Makes sure there is at least one player (the title screen's Play does it for a one-player game). */
export function ensureOne() {
  if (list.length === 0) add();
  return list[0];
}

/** Empties the registry (tests, and the title screen when the players are chosen again). */
export function clear() {
  list = [];
}
