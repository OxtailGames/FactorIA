// @ts-check
// Who is where: the miners standing in the mine right now, as plain records. The hazards, the enemies, the lights and the fog
// all ask "which miners are near this?", and this is the one place that knows how to find them (the entities tagged "miner",
// matched to the players registry by the `playerId` prop). Nothing here changes anything.
import { world } from "factoria";
import * as players from "./players.js";
import { live } from "./mine_map.js";

/**
 * @typedef {object} MinerActor
 * @property {import("./players.js").Player} player
 * @property {any} entity   The miner entity.
 * @property {number} x     World position.
 * @property {number} y
 * @property {number} tx    Tile it stands on.
 * @property {number} ty
 */

/**
 * The miners in play (state "active" or "lift"), or with `includeDown` every miner. Ordered by player id.
 * @param {{includeDown?: boolean}} [opts]
 * @returns {MinerActor[]}
 */
export function miners(opts = {}) {
  const map = live.map;
  /** @type {MinerActor[]} */
  const out = [];
  for (const entity of world.findByTag("miner")) {
    const player = players.get(entity.behaviour ? entity.behaviour.playerId : -1);
    if (!player || (player.state === "down" && !opts.includeDown)) continue;
    const p = entity.position;
    const t = map ? map.tileAt(p.x, p.y) : { tx: 0, ty: 0 };
    out.push({ player, entity, x: p.x, y: p.y, tx: t.tx, ty: t.ty });
  }
  return out.sort((a, b) => a.player.id - b.player.id);
}

/** The miner (in play) nearest to a world point, with its distance, or null when nobody is in play. */
export function nearestMiner(x, y) {
  let best = null, bestD = Infinity;
  for (const m of miners()) {
    const d = Math.hypot(m.x - x, m.y - y);
    if (d < bestD) {
      best = m;
      bestD = d;
    }
  }
  return best ? { miner: best, dist: bestD } : null;
}
