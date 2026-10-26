// @ts-check
// Where ships can go (pure): the water cells of the map. A pier has a berth, the water cell next to it from which the open sea
// can be reached; the route of a ship is the list of water cells from the sea to the berth, found by a breadth-first search in
// a fixed neighbour order, so one map and one pier always give the same route. The route starts three cells beyond the map
// edge, so a ship comes in from outside the picture.
import { footprintCells } from "./rules.js";

const STEPS = [[1, 0], [0, 1], [-1, 0], [0, -1]]; // +c, +r, -c, -r: heading 0..3

/** @param {import("./map.js").GameMap} map */
const isWater = (map, c, r) => map.terrainAt(c, r) === "water";

/** The cells just off the map in the direction an edge cell faces (outwards), `n` of them, nearest first. */
function offMap(map, c, r, n) {
  const out = [];
  const dc = c === 0 ? -1 : c === map.width - 1 ? 1 : 0;
  const dr = dc === 0 ? (r === 0 ? -1 : 1) : 0;
  for (let i = 1; i <= n; i++) out.push([c + dc * i, r + dr * i]);
  return out;
}

/**
 * The shortest water route from a cell to the map edge, as cells from the SEA to `from` (the last cell is `from`), or null when
 * the cell is in a lake.
 * @param {import("./map.js").GameMap} map @param {number} c @param {number} r
 * @returns {number[][] | null}
 */
export function seaRoute(map, c, r) {
  if (!isWater(map, c, r)) return null;
  const key = (cc, rr) => rr * map.width + cc;
  const from = new Map([[key(c, r), null]]);
  const queue = [[c, r]];
  for (let head = 0; head < queue.length; head++) {
    const [cc, rr] = queue[head];
    if (cc === 0 || rr === 0 || cc === map.width - 1 || rr === map.height - 1) {
      const cells = [];
      /** @type {any} */
      let at = [cc, rr];
      while (at) {
        cells.push(at);
        at = from.get(key(at[0], at[1]));
      }
      // cells run from the edge cell back to `from`? No: `at` walks from the edge to the start, so cells = edge ... start.
      return [...offMap(map, cc, rr, 3).reverse(), ...cells];
    }
    for (const [dc, dr] of STEPS) {
      const nc = cc + dc;
      const nr = rr + dr;
      if (!map.inBounds(nc, nr) || from.has(key(nc, nr)) || !isWater(map, nc, nr)) continue;
      from.set(key(nc, nr), [cc, rr]);
      queue.push([nc, nr]);
    }
  }
  return null;
}

/**
 * The berth of a pier: the first water cell (footprint cells in order, then +c, +r, -c, -r) next to it that has a route to the
 * sea. Returns { cell, route } or null (a pier on a lake, or with no water next to it).
 * @param {{ data: any, map: import("./map.js").GameMap }} state @param {{ type: string, x: number, y: number, rot: number }} pier
 */
export function berthOf(state, pier) {
  const cells = footprintCells(state.data.buildings[pier.type], pier.x, pier.y, pier.rot);
  for (const [c, r] of cells) {
    for (const [dc, dr] of STEPS) {
      const route = state.map.inBounds(c + dc, r + dr) ? seaRoute(state.map, c + dc, r + dr) : null;
      if (route) return { cell: [c + dc, r + dr], route };
    }
  }
  return null;
}

/** Cells (fractional) and heading (0..3, as the walkers' directions) at distance `t` along a route. */
export function along(route, t) {
  const last = route.length - 1;
  const clamped = Math.max(0, Math.min(last, t));
  const i = Math.min(last - 1, Math.floor(clamped));
  const a = route[i];
  const b = route[i + 1] || a;
  const f = clamped - i;
  const dc = b[0] - a[0];
  const dr = b[1] - a[1];
  const heading = dc > 0 ? 0 : dr > 0 ? 1 : dc < 0 ? 2 : 3;
  return { x: a[0] + dc * f, y: a[1] + dr * f, heading: dc === 0 && dr === 0 ? 0 : heading };
}
