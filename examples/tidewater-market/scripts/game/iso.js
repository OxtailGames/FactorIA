// @ts-check
// Isometric grid maths (pure: no engine calls, so tests and tools can use it anywhere).
//
// A cell is (c, r). On screen +c runs down-right and +r runs down-left, so the cell (0, 0) is the top corner of the map.
// World space is the engine's: +Y up, one unit per design pixel at zoom 1. A tile is a 100 x 50 diamond:
//   x = (c - r) * 50        y = -(c + r) * 25
// (c, r) is the CENTRE of the cell; the cell covers c +- 0.5 and r +- 0.5.

export const TILE_W = 100;
export const TILE_H = 50;
const HX = TILE_W / 2;
const HY = TILE_H / 2;

/** World position of a point (u, v) in cell units; integers are cell centres. @returns {[number, number]} */
export function cornerToWorld(u, v) {
  return [(u - v) * HX, -(u + v) * HY];
}

/** World position of the centre of a cell. @returns {[number, number]} */
export function cellToWorld(c, r) {
  return cornerToWorld(c, r);
}

/** The point (u, v) in cell units under a world position. @returns {[number, number]} */
export function worldToCorner(x, y) {
  const a = x / HX; // u - v
  const b = -y / HY; // u + v
  return [(a + b) / 2, (b - a) / 2];
}

/**
 * The cell under a world position (a diamond is exactly the set of points that round to its centre in (u, v)).
 * @returns {[number, number]}
 */
export function worldToCell(x, y) {
  const [u, v] = worldToCorner(x, y);
  return [Math.round(u), Math.round(v)];
}

/** The world point where a building sprite sits: the bottom vertex of the footprint (c0..c0+w-1, r0..r0+h-1). */
export function footprintFront(c0, r0, w, h) {
  return cornerToWorld(c0 + w - 0.5, r0 + h - 0.5);
}

/** The world rectangle a width x height map covers (the tile diamonds included). */
export function mapBounds(width, height) {
  const left = cornerToWorld(-0.5, height - 0.5)[0];
  const right = cornerToWorld(width - 0.5, -0.5)[0];
  const top = cornerToWorld(-0.5, -0.5)[1];
  const bottom = cornerToWorld(width - 0.5, height - 0.5)[1];
  return { minX: left, maxX: right, minY: bottom, maxY: top };
}

/** Direction of a rotation: 0 = +c (down-right), 1 = +r (down-left), 2 = -c (up-left), 3 = -r (up-right). */
export const DIRS = [
  [1, 0],
  [0, 1],
  [-1, 0],
  [0, -1],
];

/** The four neighbours that share an edge. */
export function neighbours(c, r) {
  return DIRS.map(([dc, dr]) => [c + dc, r + dr]);
}
