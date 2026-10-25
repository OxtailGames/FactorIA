// @ts-check
// Reviving a downed miner. A teammate who is on its feet holds the dig button next to a downed miner for REVIVE_TIME seconds;
// a bar over the downed miner fills meanwhile, and it empties again (faster than it filled) when nobody holds. The miner then
// gets up with one heart and two seconds of grace (players.revive, event `playerRevived`).
//
// A downed miner does NOT bleed out: it lies where it fell until a friend comes or the shift ends. The shift still ends with
// `allDown` when every miner is down, so the pressure is that the last one standing is the only one who can pick the others up.
// Two friends holding at once fill the bar twice as fast. One miner reviving does not dig or swing the pick meanwhile.
import { world } from "factoria";
import * as players from "./players.js";
import { miners } from "./actors.js";

/** Seconds one friend has to hold the button. */
export const REVIVE_TIME = 3;
/** How near (world units, centre to centre) the friend has to be: about one tile and a half. */
export const REVIVE_RANGE = 24;
/** An empty bar refills this many times faster than a held one fills. */
const DECAY = 1.5;

/** @type {Map<number, number>} seconds of holding, by the id of the downed player */
const progress = new Map();
/** Players who were held this frame. */
const held = new Set();
/** @type {Map<number, {back: any, fill: any}>} */
const bars = new Map();

/** 0..1 of the bar of a downed player. */
export function progressOf(id) {
  return Math.min(1, (progress.get(id) ?? 0) / REVIVE_TIME);
}

/** The downed miner nearest to a point and within reach, or null. */
export function targetNear(x, y, exceptId = -1) {
  let best = null, bestD = REVIVE_RANGE;
  for (const m of miners({ includeDown: true })) {
    if (m.player.state !== "down" || m.player.id === exceptId) continue;
    const d = Math.hypot(m.x - x, m.y - y);
    if (d <= bestD) {
      best = m;
      bestD = d;
    }
  }
  return best;
}

/**
 * Called by a miner that holds the dig button: when a downed friend is in reach, adds this frame to its bar and returns true (the
 * miner is reviving, not digging). Returns false when nobody needs picking up.
 * @param {number} reviverId
 * @param {{x: number, y: number}} at  The reviver's position.
 * @param {number} dt
 */
export function hold(reviverId, at, dt) {
  const target = targetNear(at.x, at.y, reviverId);
  if (!target) return false;
  const id = target.player.id;
  held.add(id);
  const t = (progress.get(id) ?? 0) + dt;
  if (t >= REVIVE_TIME) {
    progress.delete(id);
    players.revive(id, reviverId);
  } else {
    progress.set(id, t);
  }
  return true;
}

/** Once a frame (the shift calls it): empties the bars nobody holds and keeps the bars on screen. */
export function update(dt) {
  for (const [id, t] of [...progress]) {
    const owner = players.get(id);
    if (!owner || owner.state !== "down") {
      progress.delete(id);
      continue;
    }
    if (!held.has(id)) {
      const left = t - dt * DECAY;
      if (left <= 0) progress.delete(id);
      else progress.set(id, left);
    }
  }
  held.clear();
  const all = miners({ includeDown: true });
  for (const [id, bar] of [...bars]) {
    if (!progress.has(id)) {
      bar.back.destroy();
      bar.fill.destroy();
      bars.delete(id);
    }
  }
  for (const [id] of progress) {
    const m = all.find((a) => a.player.id === id);
    if (!m) continue;
    let bar = bars.get(id);
    if (!bar) {
      const color = m.player.color;
      bar = {
        back: world.spawn({ components: { Transform: { position: [m.x, m.y + 12, 0] }, Shape2D: { shape: "rectangle", size: [18, 4], color: [0, 0, 0, 0.8], layer: 40 } } }),
        fill: world.spawn({ components: { Transform: { position: [m.x, m.y + 12, 0] }, Shape2D: { shape: "rectangle", size: [1, 2], color: [color[0], color[1], color[2], 1], layer: 41, pivot: [0, 0.5] } } }),
      };
      bars.set(id, bar);
    }
    const w = Math.max(1, Math.round(16 * progressOf(id)));
    bar.back.position = [m.x, m.y + 12, 0];
    bar.fill.position = [m.x - 8, m.y + 12, 0];
    bar.fill.set("Shape2D", { size: [w, 2] });
  }
}

/** Forgets every bar (a shift begins or ends). */
export function reset() {
  progress.clear();
  held.clear();
  for (const bar of bars.values()) {
    if (bar.back.alive) bar.back.destroy();
    if (bar.fill.alive) bar.fill.destroy();
  }
  bars.clear();
}
