// @ts-check
// Placement rules (pure functions of the data, the map and the economy). The view calls checkPlacement every frame for the
// ghost; the state calls it again before it builds, so what the ghost shows is exactly what a click does.
import { DIRS } from "./iso.js";

/**
 * @typedef {{ code: string, cell?: number[], detail?: any }} Reason
 *   code is one of: out_of_bounds, occupied, terrain, no_road, not_near_water, cannot_afford.
 *   The player sees the locale string reason.<code> (locales/en.json), filled with detail.
 */

/** The footprint size at a rotation (odd rotations swap width and height). @returns {[number, number]} */
export function sizeAt(def, rot) {
  const [w, h] = def.size;
  return rot % 2 === 0 ? [w, h] : [h, w];
}

/**
 * The cell (x, y) of the footprint's minimum corner so that the footprint is centred on the cell (c, r) under the cursor.
 * @returns {[number, number]}
 */
export function originFor(def, c, r, rot) {
  const [w, h] = sizeAt(def, rot);
  return [c - Math.floor((w - 1) / 2), r - Math.floor((h - 1) / 2)];
}

/** Every cell of the footprint. @returns {number[][]} */
export function footprintCells(def, x, y, rot) {
  const [w, h] = sizeAt(def, rot);
  const cells = [];
  for (let r = y; r < y + h; r++) for (let c = x; c < x + w; c++) cells.push([c, r]);
  return cells;
}

/**
 * The cells just outside the footprint on the side it faces (rotation 0 faces +c, 1 faces +r, 2 faces -c, 3 faces -r).
 * @returns {number[][]}
 */
export function frontageCells(def, x, y, rot) {
  const [w, h] = sizeAt(def, rot);
  const cells = [];
  if (rot === 0) for (let r = y; r < y + h; r++) cells.push([x + w, r]);
  else if (rot === 1) for (let c = x; c < x + w; c++) cells.push([c, y + h]);
  else if (rot === 2) for (let r = y; r < y + h; r++) cells.push([x - 1, r]);
  else for (let c = x; c < x + w; c++) cells.push([c, y - 1]);
  return cells;
}

/** Is there a road on this cell? */
export function isRoad(state, c, r) {
  const id = state.map.occupantAt(c, r);
  if (!id) return false;
  const b = state.buildings.get(id);
  return !!b && state.data.buildings[b.type].kind === "road";
}

/**
 * Can `type` be built with its footprint's minimum corner at (x, y) and this rotation?
 * @returns {{ ok: boolean, reasons: Reason[], cells: number[][] }} cells = the footprint (also when not ok)
 */
export function checkPlacement(state, type, x, y, rot = 0) {
  const def = state.data.buildings[type];
  const cells = footprintCells(def, x, y, def.kind === "road" ? 0 : rot);
  /** @type {Reason[]} */
  const reasons = [];
  const seen = new Set();
  const note = (reason) => {
    if (!seen.has(reason.code)) {
      seen.add(reason.code);
      reasons.push(reason);
    }
  };
  const { map } = state;
  let touchesWater = false;
  for (const [c, r] of cells) {
    if (!map.inBounds(c, r)) {
      note({ code: "out_of_bounds", cell: [c, r] });
      continue;
    }
    if (map.occupantAt(c, r)) note({ code: "occupied", cell: [c, r] });
    const t = map.terrainAt(c, r);
    if (!def.terrain.includes(t)) note({ code: "terrain", cell: [c, r], detail: { terrain: t, allowed: def.terrain } });
    if (map.touchesWater(c, r)) touchesWater = true;
  }
  if (def.nearWater && !touchesWater && !seen.has("out_of_bounds")) note({ code: "not_near_water" });
  if (def.requireRoad === "frontage" && !seen.has("out_of_bounds")) {
    if (!frontageCells(def, x, y, rot).some(([c, r]) => isRoad(state, c, r))) note({ code: "no_road", detail: { rotation: rot } });
  }
  const pay = state.economy.canAfford(def.cost);
  if (!pay.ok) note({ code: "cannot_afford", detail: { missing: pay.missing } });
  return { ok: reasons.length === 0, reasons, cells };
}

/**
 * The cells of an elbow road from `from` to `to`: along the longer side first, then along the other, both ends included,
 * in the order a road would be laid.
 * @returns {number[][]}
 */
export function roadPath(from, to) {
  const [c0, r0] = from;
  const [c1, r1] = to;
  const cells = [];
  const alongC = (r, a, b) => {
    const step = b >= a ? 1 : -1;
    for (let c = a; c !== b + step; c += step) cells.push([c, r]);
  };
  const alongR = (c, a, b) => {
    const step = b >= a ? 1 : -1;
    for (let r = a; r !== b + step; r += step) cells.push([c, r]);
  };
  if (Math.abs(c1 - c0) >= Math.abs(r1 - r0)) {
    alongC(r0, c0, c1);
    if (r1 !== r0) alongR(c1, r0 + (r1 > r0 ? 1 : -1), r1);
  } else {
    alongR(c0, r0, r1);
    if (c1 !== c0) alongC(r1, c0 + (c1 > c0 ? 1 : -1), c1);
  }
  return cells;
}

/** Which of the four neighbours of a road cell hold a road: a bit mask N = 1 (-c), E = 2 (-r), S = 4 (+c), W = 8 (+r). */
export function roadMask(state, c, r) {
  // N = -c (up-left on screen), E = -r (up-right), S = +c (down-right), W = +r (down-left): see assets/src/make_atlas.py
  const probe = [[-1, 0, 1], [0, -1, 2], [1, 0, 4], [0, 1, 8]];
  let mask = 0;
  for (const [dc, dr, bit] of probe) if (isRoad(state, c + dc, r + dr)) mask |= bit;
  return mask;
}

export { DIRS };
