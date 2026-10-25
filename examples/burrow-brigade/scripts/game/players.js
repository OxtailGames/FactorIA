// @ts-check
// The players registry: who is in the mine (1 to 4 miners), with which input device and colour, and in which state.
// P1 registers one player on the project's input actions (keyboard or any gamepad). The code that moves a miner reads only
// its player record, so the local co-op package (P3) adds players here, with `{ kind: "keys" }` and `{ kind: "pad" }`
// devices, and nothing in the miner changes.
import * as events from "./events.js";

export const MAX_PLAYERS = 4;

/** Lamp and marker colour of player 0..3 (rgba 0..1). */
export const PLAYER_COLORS = Object.freeze([
  [1.0, 0.82, 0.4, 1],
  [0.45, 0.8, 1.0, 1],
  [0.55, 1.0, 0.5, 1],
  [1.0, 0.55, 0.8, 1],
]);

/** The key schemes a keyboard player can use. P1 uses the project's actions instead (`{ kind: "any" }`). */
export const KEY_SCHEMES = Object.freeze({
  wasd: { left: "A", right: "D", up: "W", down: "S", dig: "Space" },
  arrows: { left: "Left", right: "Right", up: "Up", down: "Down", dig: "Enter" },
  ijkl: { left: "J", right: "L", up: "I", down: "K", dig: "U" },
});

/**
 * Which input drives a player:
 *  - `{ kind: "any" }`: the project's actions (move_left ... dig in factoria.json): the keyboard and every gamepad. One player only.
 *  - `{ kind: "keys", scheme: "wasd" | "arrows" | "ijkl" }`: that block of keys.
 *  - `{ kind: "pad", index: 0..3 }`: that gamepad (left stick or d-pad to move, A or X to dig).
 * @typedef {{kind: "any"} | {kind: "keys", scheme: keyof typeof KEY_SCHEMES} | {kind: "pad", index: number}} Device
 */

/**
 * @typedef {object} Player
 * @property {number} id            0..3, also the index of its colour, its miner picture and its lamp in the run state.
 * @property {string} name          "P1".."P4".
 * @property {Device} device
 * @property {number[]} color       rgba of its lamp light and the ring under its feet.
 * @property {"active"|"lift"|"down"} state  active: playing; lift: standing on the exit lift; down: out of play (hazards and enemies, P2).
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
  const player = { id, name: opts.name ?? `P${id + 1}`, device, color: opts.color ?? [...PLAYER_COLORS[id]], state: /** @type {"active"} */ ("active") };
  list.push(player);
  list.sort((a, b) => a.id - b.id);
  events.emit("playerAdded", { player });
  return player;
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
 */
export function setState(id, state) {
  const player = get(id);
  if (!player) throw new Error(`no player ${id}: the players are ${list.map((p) => p.id).join(", ") || "(none)"}.`);
  if (!["active", "lift", "down"].includes(state)) throw new Error(`unknown player state '${state}': use active, lift or down.`);
  if (player.state === state) return;
  const from = player.state;
  player.state = state;
  events.emit("playerState", { player, from, to: state });
  if (state === "down") events.emit("playerDown", { player });
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
