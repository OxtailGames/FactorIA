// @ts-check
// What the game needs to know about a generated floor, read from the ASCII rows `tilemap.generate` returns: which
// glyphs are walls, where the player starts, where the stairs go, and which route is free of traps. Pure functions of
// the rows and the legend (no entities, no clock), so the same floor always gives the same plan.

/** The glyphs that are solid in `legend` (glyph -> tile index or { tile, prefab }) for the given solid tile numbers. */
export function solidGlyphs(legend, solidTiles) {
  const solid = new Set();
  for (const [glyph, entry] of Object.entries(legend)) {
    const tile = typeof entry === "number" ? entry : entry && typeof entry === "object" ? entry.tile : undefined;
    if (typeof tile === "number" && solidTiles.includes(tile)) solid.add(glyph);
  }
  return solid;
}

/**
 * Plans a floor.
 * @param {string[]} rows row 0 is the top row
 * @param {Set<string>} solid glyphs that block walking
 * @param {{ coin: string, trap: string }} markers the glyphs of the coin and trap prefabs
 * @returns {{ width: number, height: number, start: [number, number], stairs: [number, number], coins: [number, number][],
 *   traps: [number, number][], reachableCoins: number, steps: number } | null} null when no floor cell is free of traps
 */
export function planFloor(rows, solid, markers) {
  const height = rows.length;
  const width = height > 0 ? rows[0].length : 0;
  /** @param {number} c @param {number} r */
  const glyph = (c, r) => rows[r][c];
  /** A cell the player can stand on without stepping on a trap. */
  const free = (c, r) => c >= 0 && r >= 0 && c < width && r < height && !solid.has(glyph(c, r)) && glyph(c, r) !== markers.trap;

  /** @type {[number, number][]} */
  const coins = [];
  /** @type {[number, number][]} */
  const traps = [];
  for (let r = 0; r < height; r++) {
    for (let c = 0; c < width; c++) {
      if (glyph(c, r) === markers.coin) coins.push([c, r]);
      if (glyph(c, r) === markers.trap) traps.push([c, r]);
    }
  }

  // Label the trap-free regions in reading order; the biggest one (the first of equals) holds the start and the stairs.
  const label = rows.map(() => new Array(width).fill(-1));
  const sizes = [];
  for (let r = 0; r < height; r++) {
    for (let c = 0; c < width; c++) {
      if (label[r][c] !== -1 || !free(c, r)) continue;
      const id = sizes.length;
      let size = 0;
      const queue = [[c, r]];
      label[r][c] = id;
      for (let i = 0; i < queue.length; i++) {
        const [x, y] = queue[i];
        size++;
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          if (free(x + dx, y + dy) && label[y + dy][x + dx] === -1) {
            label[y + dy][x + dx] = id;
            queue.push([x + dx, y + dy]);
          }
        }
      }
      sizes.push(size);
    }
  }
  if (sizes.length === 0) return null;
  let best = 0;
  for (let i = 1; i < sizes.length; i++) if (sizes[i] > sizes[best]) best = i;

  // The start is the first cell of that region in reading order that holds no coin; the stairs the cell farthest from it
  // by steps (the last one in reading order among equals), also without a coin.
  /** @type {[number, number] | null} */
  let start = null;
  for (let r = 0; r < height && !start; r++) {
    for (let c = 0; c < width && !start; c++) {
      if (label[r][c] === best && glyph(c, r) !== markers.coin) start = [c, r];
    }
  }
  if (!start) {
    for (let r = 0; r < height && !start; r++) for (let c = 0; c < width && !start; c++) if (label[r][c] === best) start = [c, r];
  }
  if (!start) return null;
  const dist = rows.map(() => new Array(width).fill(-1));
  dist[start[1]][start[0]] = 0;
  const queue = [start];
  for (let i = 0; i < queue.length; i++) {
    const [x, y] = queue[i];
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const nx = x + dx;
      const ny = y + dy;
      if (free(nx, ny) && dist[ny][nx] === -1) {
        dist[ny][nx] = dist[y][x] + 1;
        queue.push([nx, ny]);
      }
    }
  }
  /** @type {[number, number]} */
  let stairs = start;
  let steps = 0;
  for (let r = 0; r < height; r++) {
    for (let c = 0; c < width; c++) {
      if (dist[r][c] >= steps && glyph(c, r) !== markers.coin && (c !== start[0] || r !== start[1])) {
        steps = dist[r][c];
        stairs = [c, r];
      }
    }
  }
  const reachableCoins = coins.filter(([c, r]) => dist[r][c] !== -1).length;
  return { width, height, start, stairs, coins, traps, reachableCoins, steps };
}
