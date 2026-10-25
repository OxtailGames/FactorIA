// @ts-check
// The seeded mine generator. `generate(seed, stratum, floor)` returns a plain-data mine (no entities, no engine state
// besides its own `rng.create` generator), and `mineHash(mine)` is a 32-bit fingerprint of it: the same arguments give the
// same mine and the same hash on every machine, and a test pins the hash of one seed so a change of the algorithm shows.
//
// The mine is a grid of tile kinds (tiles.js, row 0 at the top) with: a start room holding the entry lift, an exit room
// holding the exit lift, other rooms, one-tile tunnels joining them (some plugged with a rock a pick must dig), ore
// veins, oil cans, and trapped-mole pockets: a floor tile buried behind two solid tiles next to a tunnel.
import { rng } from "factoria";
import { K, ORES, ORE_KIND, kindInfo } from "./tiles.js";

/** Version of the mine data. Raise it when the layout of the object (or the meaning of a kind) changes. */
export const MINE_FORMAT = 1;

/** The depth bands. Stratum n is `STRATA[n]`; a stratum past the end uses the last one. */
export const STRATA = Object.freeze([
  { id: "topsoil", rock: 0.7, hard: 0, ore: { copper: 70, silver: 25, gold: 5, gem: 0 }, tint: [1, 1, 1, 1] },
  { id: "rockLayers", rock: 1.1, hard: 0.7, ore: { copper: 40, silver: 40, gold: 15, gem: 5 }, tint: [0.92, 0.96, 1.04, 1] },
  { id: "deep", rock: 1.5, hard: 1.4, ore: { copper: 15, silver: 35, gold: 35, gem: 15 }, tint: [0.85, 0.88, 1.08, 1] },
]);

/** The stratum record for a number (clamped). */
export function stratumInfo(stratum) {
  return STRATA[Math.max(0, Math.min(STRATA.length - 1, Math.floor(stratum)))];
}

/** Combines the three numbers of a mine into one 32-bit seed. */
function mix(seed, stratum, floor) {
  let h = Math.imul((seed >>> 0) ^ 0x9e3779b9, 0x85ebca6b);
  h = Math.imul(h ^ (h >>> 13) ^ Math.imul(stratum + 1, 0xc2b2ae35), 0x27d4eb2f);
  h = Math.imul(h ^ (h >>> 15) ^ Math.imul(floor + 7, 0x165667b1), 0x85ebca6b);
  return (h ^ (h >>> 16)) >>> 0;
}

const DIRS = [
  [1, 0],
  [-1, 0],
  [0, 1],
  [0, -1],
];

/**
 * @typedef {object} Mine
 * @property {number} format        MINE_FORMAT.
 * @property {number} seed
 * @property {number} stratum
 * @property {number} floor
 * @property {number} width         In tiles.
 * @property {number} height
 * @property {number[]} kinds       width * height tile kinds (tiles.js `K`), row-major, row 0 at the top. The map edits it.
 * @property {{tx:number,ty:number}} start    Tile of the entry lift.
 * @property {{tx:number,ty:number}} exit     Tile of the exit lift.
 * @property {{tx:number,ty:number}[]} spawns Up to four floor tiles around the entry lift, one per player.
 * @property {{tx:number,ty:number}[]} moles  Tiles where a mole is trapped.
 * @property {{x:number,y:number,w:number,h:number}[]} rooms  Room rectangles; rooms[0] is the start room, rooms[1] the exit room.
 * @property {{tx:number,ty:number}[]} plugs   Rock tiles that plug a tunnel.
 * @property {Record<string, number>} oreCounts  Ore tiles of each ore as generated.
 * @property {number} oilCount      Oil cans as generated.
 * @property {boolean} solvable     True when the exit is reachable from the start with the starting pick (digging only dirt and rock).
 * @property {string} hash          mineHash(mine) as generated (8 hex digits); `mineHash(mine)` of a dug mine differs.
 */

/**
 * Builds a mine.
 * @param {number} seed     Any finite number (reduced to 32 bits, like `rng.create`).
 * @param {number} [stratum]  Depth band 0.. (see STRATA): more rock, hard rock and richer ore with depth.
 * @param {number} [floor]    Floor within the stratum, 1.. : a little bigger and richer each floor.
 * @param {{width?: number, height?: number}} [opts]  Size in tiles; the defaults grow with stratum and floor.
 * @returns {Mine}
 */
export function generate(seed, stratum = 0, floor = 1, opts = {}) {
  if (!Number.isFinite(seed)) throw new Error(`generate(seed, stratum, floor): seed must be a finite number, got ${seed}. Example: generate(1234, 0, 1).`);
  stratum = Math.max(0, Math.floor(stratum));
  floor = Math.max(1, Math.floor(floor));
  const S = stratumInfo(stratum);
  const W = Math.max(40, Math.floor(opts.width ?? Math.min(96, 64 + 4 * (floor - 1) + 8 * stratum)));
  const H = Math.max(28, Math.floor(opts.height ?? Math.min(64, 44 + 2 * (floor - 1) + 4 * stratum)));
  const r = rng.create(mix(seed, stratum, floor));

  const kinds = new Array(W * H).fill(K.DIRT);
  const at = (x, y) => kinds[y * W + x];
  const put = (x, y, k) => {
    kinds[y * W + x] = k;
  };
  const inside = (x, y, margin = 1) => x >= margin && y >= margin && x < W - margin && y < H - margin;

  // 1. rock and hard rock blobs inside the dirt
  const blobs = (count, kind, rmin, rmax) => {
    for (let i = 0; i < count; i++) {
      const cx = r.int(2, W - 3), cy = r.int(2, H - 3), rad = r.int(rmin, rmax), slack = r.int(0, 2);
      for (let y = cy - rad; y <= cy + rad; y++)
        for (let x = cx - rad; x <= cx + rad; x++)
          if (inside(x, y) && (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad + slack) put(x, y, kind);
    }
  };
  blobs(Math.round(((W * H) / 220) * S.rock * (1 + 0.05 * (floor - 1))), K.ROCK, 2, 5);
  blobs(Math.round(((W * H) / 380) * S.hard * (1 + 0.1 * (floor - 1))), K.HARD, 2, 3);
  if (stratum === 0 && floor >= 3) blobs(Math.round((W * H) / 700), K.HARD, 2, 3);

  // 2. bedrock border
  for (let x = 0; x < W; x++) {
    put(x, 0, K.BEDROCK);
    put(x, H - 1, K.BEDROCK);
  }
  for (let y = 0; y < H; y++) {
    put(0, y, K.BEDROCK);
    put(W - 1, y, K.BEDROCK);
  }

  // 3. rooms: the start room on the left, the exit room on the right, then the others anywhere that fits
  /** @type {{x:number,y:number,w:number,h:number}[]} */
  const rooms = [];
  const fits = (rc, gap) => rooms.every((o) => rc.x + rc.w + gap <= o.x || o.x + o.w + gap <= rc.x || rc.y + rc.h + gap <= o.y || o.y + o.h + gap <= rc.y);
  const place = (xmin, xmax, attempts) => {
    for (let i = 0; i < attempts; i++) {
      const w = r.int(5, 10), h = r.int(4, 7);
      const x = r.int(xmin, Math.max(xmin, Math.min(xmax, W - w - 2))), y = r.int(2, H - h - 2);
      const rc = { x, y, w, h };
      if (x + w <= W - 2 && fits(rc, 2)) return rc;
    }
    return null;
  };
  rooms.push(place(2, Math.floor(W / 5), 80) ?? { x: 3, y: 3, w: 6, h: 5 });
  rooms.push(place(Math.floor(W * 0.7), W, 120) ?? { x: W - 10, y: H - 9, w: 6, h: 5 });
  const wanted = r.int(7, 10) + Math.min(3, stratum + floor - 1);
  for (let i = 0; i < wanted * 6 && rooms.length < wanted; i++) {
    const rc = place(2, W, 6);
    if (rc) rooms.push(rc);
  }
  for (const rc of rooms) {
    for (let y = rc.y; y < rc.y + rc.h; y++) for (let x = rc.x; x < rc.x + rc.w; x++) put(x, y, K.FLOOR);
    for (const [cx, cy] of [[rc.x, rc.y], [rc.x + rc.w - 1, rc.y], [rc.x, rc.y + rc.h - 1], [rc.x + rc.w - 1, rc.y + rc.h - 1]])
      if (r.chance(0.5)) put(cx, cy, K.DIRT);
  }
  const center = (rc) => ({ x: rc.x + Math.floor(rc.w / 2), y: rc.y + Math.floor(rc.h / 2) });
  const inRoom = (x, y) => rooms.some((rc) => x >= rc.x - 1 && y >= rc.y - 1 && x <= rc.x + rc.w && y <= rc.y + rc.h);

  // 4. tunnels: a minimum spanning tree of the room centres (Prim), plus two extra loops
  const edges = [];
  const linked = new Set([0]);
  while (linked.size < rooms.length) {
    let best = null;
    for (const a of linked)
      for (let b = 0; b < rooms.length; b++) {
        if (linked.has(b)) continue;
        const ca = center(rooms[a]), cb = center(rooms[b]);
        const d = Math.abs(ca.x - cb.x) + Math.abs(ca.y - cb.y);
        if (!best || d < best.d) best = { a, b, d };
      }
    if (!best) break;
    linked.add(best.b);
    edges.push([best.a, best.b]);
  }
  for (let i = 0; i < 2; i++) {
    const a = r.int(0, rooms.length - 1), b = r.int(0, rooms.length - 1);
    if (a !== b && !edges.some(([p, q]) => (p === a && q === b) || (p === b && q === a))) edges.push([a, b]);
  }
  /** @type {{tx:number,ty:number}[]} */
  const plugs = [];
  for (const [a, b] of edges) {
    const ca = center(rooms[a]), cb = center(rooms[b]);
    const horizontalFirst = r.chance(0.5);
    const wide = r.chance(0.25);
    const plug = r.chance(0.35);
    // an L-shaped path of tiles from one room centre to the other: one leg along an axis, then the other
    /** @type {number[][]} */
    const path = [[ca.x, ca.y]];
    let cx = ca.x, cy = ca.y;
    const walkX = () => {
      while (cx !== cb.x) path.push([(cx += Math.sign(cb.x - cx)), cy]);
    };
    const walkY = () => {
      while (cy !== cb.y) path.push([cx, (cy += Math.sign(cb.y - cy))]);
    };
    if (horizontalFirst) {
      walkX();
      walkY();
    } else {
      walkY();
      walkX();
    }
    const carve = (x, y) => {
      if (inside(x, y)) put(x, y, K.FLOOR);
    };
    for (const [x, y] of path) {
      carve(x, y);
      if (wide) {
        carve(x + 1, y);
        carve(x, y + 1);
        carve(x + 1, y + 1);
      }
    }
    // a one-tile tunnel may be plugged with a rock in the middle of its open stretch: the pick has to dig it
    if (plug && !wide) {
      const open = path.filter(([x, y]) => !inRoom(x, y));
      if (open.length >= 3) {
        const [px, py] = open[Math.floor(open.length / 2)];
        put(px, py, K.ROCK);
        plugs.push({ tx: px, ty: py });
      }
    }
  }

  // 5. the lifts and the miners' spawn tiles
  const c0 = center(rooms[0]), c1 = center(rooms[1]);
  put(c0.x, c0.y, K.LIFT_START);
  put(c1.x, c1.y, K.LIFT_EXIT);
  const spawns = [[-1, 0], [1, 0], [0, 1], [0, -1]]
    .map(([dx, dy]) => ({ tx: c0.x + dx, ty: c0.y + dy }))
    .filter((p) => at(p.tx, p.ty) === K.FLOOR);

  // 6. ore veins: random walks that turn the tiles they cross into ore
  const weights = ORES.map((o) => Math.max(0, S.ore[o] + (o === "gold" || o === "gem" ? 2 * (floor - 1) : 0)));
  const wsum = weights.reduce((a, b) => a + b, 0);
  const hostOf = {
    copper: [K.DIRT],
    silver: [K.ROCK, K.DIRT],
    gold: [K.HARD, K.ROCK],
    gem: [K.HARD, K.ROCK],
  };
  const vein = (ore, sx, sy, len) => {
    let x = sx, y = sy;
    for (let i = 0; i < len; i++) {
      if (inside(x, y) && hostOf[ore].includes(at(x, y))) put(x, y, ORE_KIND[ore]);
      const [dx, dy] = DIRS[r.int(0, 3)];
      x += dx;
      y += dy;
    }
  };
  // two copper veins always start right against the start room, so the first thing in the lamp light is ore
  for (let i = 0; i < 2; i++) {
    const rc = rooms[0];
    const side = r.int(0, 3);
    const x = side < 2 ? (side === 0 ? rc.x - 1 : rc.x + rc.w) : r.int(rc.x, rc.x + rc.w - 1);
    const y = side < 2 ? r.int(rc.y, rc.y + rc.h - 1) : (side === 2 ? rc.y - 1 : rc.y + rc.h);
    vein("copper", x, y, r.int(3, 5));
  }
  const veinCount = Math.round((W * H) / 150);
  for (let i = 0; i < veinCount; i++) {
    let pick = r.float() * wsum, ore = ORES[0];
    for (let j = 0; j < ORES.length; j++) {
      if (pick < weights[j]) { ore = ORES[j]; break; }
      pick -= weights[j];
    }
    vein(ore, r.int(1, W - 2), r.int(1, H - 2), r.int(3, 8));
  }

  // 7. oil cans on the floor of rooms (never the lift rooms when another room exists)
  const canRooms = rooms.length > 2 ? rooms.slice(2) : rooms;
  const cans = r.int(2, 3) + (W >= 80 ? 1 : 0);
  let oilCount = 0;
  for (let i = 0; i < cans * 8 && oilCount < cans; i++) {
    const rc = canRooms[r.int(0, canRooms.length - 1)];
    const x = r.int(rc.x, rc.x + rc.w - 1), y = r.int(rc.y, rc.y + rc.h - 1);
    if (at(x, y) === K.FLOOR) {
      put(x, y, K.OIL);
      oilCount++;
    }
  }

  // 8. trapped moles: a floor tile three steps from a tunnel tile, two solid tiles between, solid all around
  /** @type {{tx:number,ty:number}[]} */
  const moles = [];
  const wantedMoles = r.int(2, 3);
  const solid = (x, y) => inside(x, y) && kindInfo(at(x, y)).solid && at(x, y) !== K.BEDROCK;
  for (let i = 0; i < 400 && moles.length < wantedMoles; i++) {
    const tx = r.int(2, W - 3), ty = r.int(2, H - 3), [dx, dy] = DIRS[r.int(0, 3)];
    if (at(tx, ty) !== K.FLOOR) continue;
    if (rooms.slice(0, 2).some((rc) => tx >= rc.x - 2 && ty >= rc.y - 2 && tx <= rc.x + rc.w + 1 && ty <= rc.y + rc.h + 1)) continue;
    const qx = tx + 3 * dx, qy = ty + 3 * dy;
    let ok = inside(qx, qy, 2) && solid(tx + dx, ty + dy) && solid(tx + 2 * dx, ty + 2 * dy);
    for (let ox = -1; ok && ox <= 1; ox++) for (let oy = -1; ok && oy <= 1; oy++) if (!solid(qx + ox, qy + oy)) ok = false;
    if (!ok) continue;
    put(tx + dx, ty + dy, K.DIRT);
    put(tx + 2 * dx, ty + 2 * dy, K.ROCK);
    put(qx, qy, K.FLOOR);
    moles.push({ tx: qx, ty: qy });
  }

  // 9. bookkeeping
  const oreCounts = Object.fromEntries(ORES.map((o) => [o, 0]));
  for (const k of kinds) {
    const ore = kindInfo(k).ore;
    if (ore) oreCounts[ore]++;
  }
  /** @type {Mine} */
  const mine = {
    format: MINE_FORMAT, seed, stratum, floor, width: W, height: H, kinds,
    start: { tx: c0.x, ty: c0.y }, exit: { tx: c1.x, ty: c1.y }, spawns, moles, rooms,
    plugs: plugs.filter((p) => at(p.tx, p.ty) === K.ROCK), // a later tunnel may have dug through an earlier plug
    oreCounts, oilCount,
    solvable: false, hash: "",
  };
  mine.solvable = exitReachable(mine, 0);
  mine.hash = mineHash(mine);
  return mine;
}

/**
 * True when a miner with a pick of this tier can get from the start lift to the exit lift, digging what the pick can dig.
 * @param {Mine} mine
 * @param {number} tier
 */
export function exitReachable(mine, tier) {
  const { width: W, height: H, kinds } = mine;
  const seen = new Uint8Array(W * H);
  const stack = [mine.start.ty * W + mine.start.tx];
  seen[stack[0]] = 1;
  while (stack.length) {
    const i = /** @type {number} */ (stack.pop());
    if (i === mine.exit.ty * W + mine.exit.tx) return true;
    const x = i % W, y = (i - x) / W;
    for (const [dx, dy] of DIRS) {
      const nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
      const j = ny * W + nx;
      if (seen[j]) continue;
      const info = kindInfo(kinds[j]);
      if (info.solid && info.tier > tier) continue;
      seen[j] = 1;
      stack.push(j);
    }
  }
  return false;
}

/**
 * A 32-bit FNV-1a fingerprint of a mine (its size, seed, stratum, floor, every tile kind, the lifts, the spawn tiles and the
 * moles), as 8 lowercase hex digits. It changes when a tile is dug, so it also fingerprints a save.
 * @param {Mine} mine
 */
export function mineHash(mine) {
  let h = 0x811c9dc5;
  const feed = (n) => {
    n = Math.floor(n) | 0;
    for (let i = 0; i < 4; i++) {
      h ^= (n >>> (i * 8)) & 255;
      h = Math.imul(h, 0x01000193);
    }
  };
  feed(mine.format);
  feed(mine.seed);
  feed(mine.stratum);
  feed(mine.floor);
  feed(mine.width);
  feed(mine.height);
  for (const k of mine.kinds) feed(k);
  for (const p of [mine.start, mine.exit, ...mine.spawns, ...mine.moles]) {
    feed(p.tx);
    feed(p.ty);
  }
  return (h >>> 0).toString(16).padStart(8, "0");
}
