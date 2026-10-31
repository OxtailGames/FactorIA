// @ts-check
// Map generation from a seed (pure). The same seed gives the same map and the same hash on every machine: the noise is
// built from integer hashing (Math.imul and shifts) and + - * / floor only, so no sin, cos, pow or random() whose last
// bit could differ between platforms.

/** 32-bit integer hash of (seed, x, y, salt) mapped to [0, 1). */
export function hash01(seed, x, y, salt = 0) {
  let h = (seed | 0) ^ Math.imul(x | 0, 0x27d4eb2d) ^ Math.imul(y | 0, 0x165667b1) ^ Math.imul(salt | 0, 0x9e3779b1);
  h = Math.imul(h ^ (h >>> 15), 0x85ebca6b);
  h = Math.imul(h ^ (h >>> 13), 0xc2b2ae35);
  h ^= h >>> 16;
  return (h >>> 0) / 4294967296;
}

const smooth = (t) => t * t * (3 - 2 * t);

/** Smooth value noise in [0, 1): hashed lattice values every `scale` cells, blended with a smoothstep. */
export function valueNoise(seed, x, y, scale, salt = 0) {
  const fx = x / scale;
  const fy = y / scale;
  const x0 = Math.floor(fx);
  const y0 = Math.floor(fy);
  const tx = smooth(fx - x0);
  const ty = smooth(fy - y0);
  const a = hash01(seed, x0, y0, salt);
  const b = hash01(seed, x0 + 1, y0, salt);
  const c = hash01(seed, x0, y0 + 1, salt);
  const d = hash01(seed, x0 + 1, y0 + 1, salt);
  return a + (b - a) * tx + (c - a) * ty + (a - b - c + d) * tx * ty;
}

/** Two octaves of value noise, normalised to [0, 1). */
export function fbm(seed, x, y, scale, salt = 0) {
  return (valueNoise(seed, x, y, scale, salt) * 2 + valueNoise(seed, x, y, scale / 2, salt + 101)) / 3;
}

/**
 * @typedef {{ size: number[], scale: number, falloff: number, moistureScale: number,
 *             thresholds: { water: number, sand: number, rock: number, forest: number }, rockScale: number }} MapSettings
 * @typedef {{ width: number, height: number, seed: number, terrain: Uint8Array }} RawMap
 */

/**
 * Generate the terrain of a map. `ids` are the terrain ids in the order of data/terrain.json (the stored index is the
 * position in that list). A 5 x 5 patch of grass is always left in the middle so that every seed has a place to start.
 * @param {number} seed
 * @param {MapSettings} settings
 * @param {string[]} ids
 * @returns {RawMap}
 */
export function generateMap(seed, settings, ids) {
  const [width, height] = settings.size;
  const T = Object.fromEntries(ids.map((id, i) => [id, i]));
  const terrain = new Uint8Array(width * height);
  const t = settings.thresholds;
  const cx = (width - 1) / 2;
  const cy = (height - 1) / 2;
  for (let r = 0; r < height; r++) {
    for (let c = 0; c < width; c++) {
      const dx = (c - cx) / (width / 2);
      const dy = (r - cy) / (height / 2);
      const elevation = fbm(seed, c, r, settings.scale) - settings.falloff * (dx * dx + dy * dy);
      let id;
      if (elevation < t.water) id = "water";
      else if (elevation < t.sand) id = "sand";
      else if (fbm(seed, c, r, settings.rockScale, 13) > t.rock) id = "rock";
      else id = fbm(seed, c, r, settings.moistureScale, 7) > t.forest ? "forest" : "grass";
      terrain[r * width + c] = T[id];
    }
  }
  const mc = Math.floor(width / 2);
  const mr = Math.floor(height / 2);
  for (let r = mr - 2; r <= mr + 2; r++) for (let c = mc - 2; c <= mc + 2; c++) terrain[r * width + c] = T.grass;
  return { width, height, seed, terrain };
}

/**
 * A map from rows of characters (data/test_map.json). `chars` maps a character to its terrain index.
 * @param {string[]} rows @param {Record<string, number>} chars
 * @returns {RawMap}
 */
export function mapFromRows(rows, chars) {
  const height = rows.length;
  const width = rows[0].length;
  const terrain = new Uint8Array(width * height);
  for (let r = 0; r < height; r++) for (let c = 0; c < width; c++) terrain[r * width + c] = chars[rows[r][c]];
  return { width, height, seed: 0, terrain };
}

/** FNV-1a over the size and the terrain bytes, as 8 hex digits: the fingerprint tests and bug reports compare. */
export function hashTerrain(map) {
  let h = 0x811c9dc5;
  const feed = (byte) => {
    h ^= byte & 255;
    h = Math.imul(h, 0x01000193);
  };
  feed(map.width);
  feed(map.width >> 8);
  feed(map.height);
  feed(map.height >> 8);
  for (let i = 0; i < map.terrain.length; i++) feed(map.terrain[i]);
  return (h >>> 0).toString(16).padStart(8, "0");
}

/** The map as text, one character per cell, for logs and tuning. */
export function mapToText(map, chars) {
  const out = [];
  for (let r = 0; r < map.height; r++) {
    let line = "";
    for (let c = 0; c < map.width; c++) line += chars[map.terrain[r * map.width + c]];
    out.push(line);
  }
  return out.join("\n");
}
