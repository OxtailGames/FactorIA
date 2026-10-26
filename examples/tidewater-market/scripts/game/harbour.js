// @ts-check
// Where the town starts (pure): the harbour is a buildable cell on the shore with room around it, near the middle of the map.
// The camera starts there (so water is in view) and the bot (planner.js) lays out the first roads from it.

/**
 * The harbour cell of a map: among the buildable cells that touch water, the one with the most buildable cells in the 9 x 9
 * square around it, minus its distance to the map centre (so a thin spit far away loses to a broad shore near the middle).
 * Ties go to the lowest index, so the answer only depends on the map.
 * @param {import("./map.js").GameMap} map
 * @returns {[number, number]}
 */
export function harbourCell(map) {
  const data = map.data;
  const ok = (c, r) => {
    const t = map.terrainAt(c, r);
    return !!t && data.terrain[t].buildable;
  };
  const cx = (map.width - 1) / 2;
  const cy = (map.height - 1) / 2;
  let best = null;
  let bestScore = -Infinity;
  for (let r = 0; r < map.height; r++) {
    for (let c = 0; c < map.width; c++) {
      if (!ok(c, r) || !map.touchesWater(c, r)) continue;
      let room = 0;
      for (let rr = r - 4; rr <= r + 4; rr++) for (let cc = c - 4; cc <= c + 4; cc++) if (ok(cc, rr)) room++;
      const score = room - Math.hypot(c - cx, r - cy);
      if (score > bestScore + 1e-9) {
        bestScore = score;
        best = [c, r];
      }
    }
  }
  return best || [Math.floor(map.width / 2), Math.floor(map.height / 2)];
}
