// @ts-check
// The engine's single-pair path finder as a walker route backend: `net.setFinder(navFinder(net))` makes every walker ask
// nav.findTilePath (A*, one start and one goal) on the road grid the net keeps (`net.grid`, a nav.createGrid) instead of
// reading the flow fields of roadnet.js. The game does not use it (500 walkers heading for few buildings are cheaper with
// the fields, see README.md "Walkers"); the stress test runs both so a later package can see where the crossing point is.
import { nav } from "factoria";

/**
 * @param {import("./roadnet.js").RoadNet} net
 * @returns {import("./roadnet.js").Finder}
 */
export function navFinder(net) {
  return (road, width, height, from, to) => {
    const fc = from % width;
    const tc = to % width;
    const p = nav.findTilePath(net.grid, { col: fc, row: (from - fc) / width }, { col: tc, row: (to - tc) / width });
    if (!p.found) return null;
    return p.cells.map((cell) => cell.row * width + cell.col);
  };
}
