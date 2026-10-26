// @ts-check
// The engine's path finder as a walker route backend: `net.setFinder(navFinder(net))` makes every walker ask
// nav.findTilePath (A*, one start and one goal) instead of reading the distance fields of roadnet.js. The game does not use it
// (500 walkers heading for few buildings are cheaper with the fields, see README.md "Walkers"); the stress test runs both and
// prints the cost of each, so a later package can see where the crossing point is.
import { nav } from "factoria";

/**
 * @param {import("./roadnet.js").RoadNet} net
 * @returns {import("./roadnet.js").Finder}
 */
export function navFinder(net) {
  let version = -1;
  /** @type {number[]} */
  let cost = [];
  return (road, width, height, from, to) => {
    if (version !== net.version || cost.length !== road.length) {
      // the cost grid is rebuilt once per change of the roads, not per query: 1 on a road, blocked elsewhere
      cost = Array.from(road, (v) => (v ? 1 : Infinity));
      version = net.version;
    }
    const fc = from % width;
    const tc = to % width;
    const p = nav.findTilePath({ width, height, cost }, { col: fc, row: (from - fc) / width }, { col: tc, row: (to - tc) / width });
    if (!p.found) return null;
    return p.cells.map((cell) => cell.row * width + cell.col);
  };
}
