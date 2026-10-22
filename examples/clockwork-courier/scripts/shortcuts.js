// @ts-check
// The shortcuts of the town: spots a bold courier crosses instead of taking the safe line. A zone is a circle on the ground
// plane (world metres); scripts/services.js sends `shortcut_found` the first time per attempt the courier is inside one, and
// the achievements "Cutting Corners" and "Know the Town" count them. The levels themselves are not touched: the zones were
// read off the expert routes of tests/helpers/routes.js and the main routes stay at least 2.5 m away from every one of them.
// rooftops_3 and market_3 have no spatial shortcut (their expert line only skips the optional-parcel detour), so they list none.
//
//   ZONES[levelId]   [{ id, x, z, radius }]
//   inside(levelId, position)   the zone the position is in, or null
//   all(), total()   every shortcut id of the game, and how many there are

/** @typedef {{ id: string, x: number, z: number, radius: number }} Zone */

/** @type {Record<string, Zone[]>} */
export const ZONES = {
  rooftops_1: [{ id: "rooftops_1.gap", x: 0, z: -25.15, radius: 1.3 }],
  rooftops_2: [{ id: "rooftops_2.gap", x: 0, z: -34.7, radius: 1.3 }],
  market_1: [
    { id: "market_1.first", x: 0, z: -31, radius: 1.3 },
    { id: "market_1.second", x: 0, z: -59.6, radius: 1.3 },
  ],
  market_2: [
    { id: "market_2.first", x: 0, z: -31, radius: 1.3 },
    { id: "market_2.second", x: 0, z: -63.6, radius: 1.3 },
  ],
};

/** @param {string} levelId @param {{ x: number, z: number }} p @returns {Zone | null} */
export function inside(levelId, p) {
  for (const z of ZONES[levelId] ?? []) if (Math.hypot(p.x - z.x, p.z - z.z) <= z.radius) return z;
  return null;
}

/** Every shortcut id of the game. */
export function all() {
  return Object.values(ZONES).flatMap((zs) => zs.map((z) => z.id));
}

export function total() {
  return all().length;
}
