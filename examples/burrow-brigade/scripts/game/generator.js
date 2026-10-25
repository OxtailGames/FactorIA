// @ts-check
// The seeded mine generator. `generate(seed, stratum, floor)` returns a plain-data mine (no entities, no engine state
// besides its own `rng.create` generator), and `mineHash(mine)` is a 32-bit fingerprint of it: the same arguments give the
// same mine and the same hash on every machine, and a test pins the hash of one seed so a change of the algorithm shows.
//
// The mine is a grid of tile kinds (tiles.js, row 0 at the top) with: a start room holding the entry lift, an exit room
// holding the exit lift, other rooms, one-tile tunnels joining them (some plugged with a rock a pick must dig), ore
// veins, oil cans, and trapped-mole pockets: a floor tile buried behind two solid tiles next to a tunnel. P2 adds, after
// all that (so a seed keeps its rooms and tunnels), what makes each stratum its own: sealed pockets of water or magma that
// spread into tunnels once dug open, cracked floor that brings the roof down, glowing crystal walls, magma pools, and the
// places where beetles, goblin thieves and the Mole King start (`mine.hazards`, `mine.enemies`, `mine.boss`).
import { rng } from "factoria";
import { K, ORES, ORE_KIND, kindInfo } from "./tiles.js";

/** Version of the mine data. Raise it when the layout of the object (or the meaning of a kind) changes. */
export const MINE_FORMAT = 2;

/**
 * The depth bands. Stratum n is `STRATA[n]`; a stratum past the end uses the last one. Every band has `floors` floors (the
 * last floor of the last band is the boss floor). The pairs are [base, extra per floor after the first]: the count of a
 * floor is floor(base + extra * (floor - 1)).
 *  - `rock`, `hard`, `ore`: the share of rock and hard rock and the weights of the ores.
 *  - `ambient`: the scene's ambient light colour (how dark the unlit mine is).
 *  - `music`: the looping track of the band (music.js).
 *  - `hazards`: sealed `flood` and `magma` pockets, `caveIn` cracked tiles, open magma `pools`.
 *  - `crystals`: glowing crystal wall tiles (they are the Crystal Caves' light).
 *  - `enemies`: how many `beetle` and `thief` start in the mine (the King is on the boss floor only).
 */
export const STRATA = Object.freeze([
  {
    id: "topsoil", name: "strata.topsoil", floors: 3, rock: 0.7, hard: 0, ore: { copper: 70, silver: 25, gold: 5, gem: 0 },
    ambient: [0.16, 0.14, 0.12, 1], music: "assets/music/music_topsoil.wav",
    hazards: { flood: [1, 0.5], caveIn: [0, 1], magma: [0, 0], pools: [0, 0] }, crystals: [0, 0],
    enemies: { beetle: [2, 1], thief: [0, 0.5] },
  },
  {
    id: "crystalCaves", name: "strata.crystalCaves", floors: 3, rock: 1.1, hard: 0.7, ore: { copper: 40, silver: 40, gold: 15, gem: 5 },
    ambient: [0.12, 0.13, 0.2, 1], music: "assets/music/music_crystal.wav",
    hazards: { flood: [2, 0.5], caveIn: [2, 0.5], magma: [0, 0], pools: [0, 0] }, crystals: [10, 3],
    enemies: { beetle: [2, 1], thief: [1, 0.5] },
  },
  {
    id: "magmaDeep", name: "strata.magmaDeep", floors: 3, rock: 1.5, hard: 1.4, ore: { copper: 15, silver: 35, gold: 35, gem: 15 },
    ambient: [0.2, 0.11, 0.1, 1], music: "assets/music/music_magma.wav",
    hazards: { flood: [1, 0.5], caveIn: [2, 0.5], magma: [2, 0.5], pools: [2, 1] }, crystals: [0, 0],
    enemies: { beetle: [3, 0.5], thief: [1, 0.5] },
  },
]);

/** How many floors the whole descent has (every stratum's floors added up). */
export const TOTAL_FLOORS = STRATA.reduce((n, st) => n + st.floors, 0);

/** True for the last floor of the last stratum: the Mole King's floor. */
export function isBossFloor(stratum, floor) {
  const last = STRATA.length - 1;
  return Math.max(0, Math.floor(stratum)) >= last && floor >= STRATA[last].floors;
}

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
 * @property {Hazard[]} hazards      The hazards the stratum put in (see Hazard).
 * @property {{kind: "beetle"|"thief"|"king", tx:number, ty:number}[]} enemies  Where each enemy starts (a floor tile).
 * @property {boolean} boss         True on the Mole King's floor (the exit lift is jammed until it falls).
 * @property {boolean} solvable     True when the exit is reachable from the start with the starting pick (digging only dirt and rock).
 * @property {string} hash          mineHash(mine) as generated (8 hex digits); `mineHash(mine)` of a dug mine differs.
 */

/**
 * @typedef {object} Hazard
 * @property {"flood"|"magma"|"caveIn"} kind
 * @property {number} tx         flood and magma: a tile of the pocket; caveIn: the cracked tile.
 * @property {number} ty
 * @property {{tx:number,ty:number}[]} [tiles]  flood and magma: the tiles of the sealed pocket (water or magma when generated).
 * @property {{tx:number,ty:number}} [door]     flood and magma pockets: the wall tile between the nearest tunnel and the pocket.
 * @property {number} [volume]  flood and magma: how many more floor tiles it can spread over once opened (0 for a pool).
 * @property {boolean} [pool]   magma only: an open pool in a room, which never spreads.
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
  const boss = isBossFloor(stratum, floor);
  const place = (xmin, xmax, attempts, wmin = 5, wmax = 10, hmin = 4, hmax = 7) => {
    for (let i = 0; i < attempts; i++) {
      const w = r.int(wmin, wmax), h = r.int(hmin, hmax);
      const x = r.int(xmin, Math.max(xmin, Math.min(xmax, W - w - 2))), y = r.int(2, H - h - 2);
      const rc = { x, y, w, h };
      if (x + w <= W - 2 && fits(rc, 2)) return rc;
    }
    return null;
  };
  rooms.push(place(2, Math.floor(W / 5), 80) ?? { x: 3, y: 3, w: 6, h: 5 });
  // the boss floor's exit room is an arena: big enough to dodge the King's slam
  rooms.push((boss ? place(Math.floor(W * 0.7), W, 200, 9, 11, 7, 8) : null) ?? place(Math.floor(W * 0.7), W, 120) ?? { x: W - 10, y: H - 9, w: 6, h: 5 });
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

  // 9. the stratum's own features (P2). They come after the base layout above, so a seed keeps its rooms and tunnels.
  const scaled = (spec) => Math.max(0, Math.floor(spec[0] + spec[1] * (floor - 1)));
  const solidPlain = (x, y) => inside(x, y, 2) && (at(x, y) === K.DIRT || at(x, y) === K.ROCK || at(x, y) === K.HARD);
  const nearLift = (x, y, d) => [c0, c1].some((c) => Math.abs(c.x - x) + Math.abs(c.y - y) < d);
  const inExitRoom = (x, y) => x >= rooms[1].x - 1 && y >= rooms[1].y - 1 && x <= rooms[1].x + rooms[1].w && y <= rooms[1].y + rooms[1].h;
  const stillSolvable = () => exitReachable(/** @type {any} */ ({ width: W, height: H, kinds, start: { tx: c0.x, ty: c0.y }, exit: { tx: c1.x, ty: c1.y } }), 0, { avoid: [K.WATER, K.MAGMA, K.SHAKY] });
  /** @type {Hazard[]} */
  const hazards = [];

  // a sealed pocket of water or magma two tiles behind a tunnel wall: dig the wall and the fluid can spread into the floor
  const pocket = (/** @type {"flood"|"magma"} */ type, volume) => {
    const kind = type === "flood" ? K.WATER : K.MAGMA;
    for (let i = 0; i < 80; i++) {
      const fx = r.int(3, W - 4), fy = r.int(3, H - 4), [dx, dy] = DIRS[r.int(0, 3)];
      if (at(fx, fy) !== K.FLOOR || nearLift(fx, fy, 8)) continue;
      const px = -dy, py = dx;
      let ok = true;
      for (let a = 1; a <= 4 && ok; a++) for (let b = -1; b <= 2 && ok; b++) if (!solidPlain(fx + a * dx + b * px, fy + a * dy + b * py)) ok = false;
      if (!ok) continue;
      const tiles = [];
      for (const a of [2, 3]) for (const b of [0, 1]) tiles.push({ tx: fx + a * dx + b * px, ty: fy + a * dy + b * py });
      const before = tiles.map((t) => at(t.tx, t.ty));
      for (const t of tiles) put(t.tx, t.ty, kind);
      if (!stillSolvable()) {
        tiles.forEach((t, j) => put(t.tx, t.ty, before[j]));
        continue;
      }
      hazards.push({ kind: type, tx: tiles[0].tx, ty: tiles[0].ty, tiles, door: { tx: fx + dx, ty: fy + dy }, volume });
      return;
    }
  };
  // an open pool of magma in a room, off the row and column the tunnels run along
  const pool = () => {
    for (let i = 0; i < 40 && rooms.length > 2; i++) {
      const rc = rooms[r.int(2, rooms.length - 1)];
      const cx = rc.x + Math.floor(rc.w / 2), cy = rc.y + Math.floor(rc.h / 2);
      const x = r.int(rc.x, rc.x + rc.w - 2), y = r.int(rc.y, rc.y + rc.h - 2);
      const tiles = [[x, y], [x + 1, y], [x, y + 1], [x + 1, y + 1]];
      if (tiles.some(([tx, ty]) => tx === cx || ty === cy || at(tx, ty) !== K.FLOOR)) continue;
      for (const [tx, ty] of tiles) put(tx, ty, K.MAGMA);
      if (!stillSolvable()) {
        for (const [tx, ty] of tiles) put(tx, ty, K.FLOOR);
        continue;
      }
      hazards.push({ kind: "magma", tx: x, ty: y, tiles: tiles.map(([tx, ty]) => ({ tx, ty })), volume: 0, pool: true });
      return;
    }
  };
  // a cracked floor tile somewhere in the open, away from the lifts and from the other cracks
  const crack = () => {
    for (let i = 0; i < 80; i++) {
      const x = r.int(3, W - 4), y = r.int(3, H - 4);
      if (at(x, y) !== K.FLOOR || nearLift(x, y, 7) || (boss && inExitRoom(x, y))) continue;
      if (hazards.some((h) => h.kind === "caveIn" && Math.abs(h.tx - x) + Math.abs(h.ty - y) < 6)) continue;
      put(x, y, K.SHAKY);
      if (!stillSolvable()) {
        put(x, y, K.FLOOR);
        continue;
      }
      hazards.push({ kind: "caveIn", tx: x, ty: y });
      return;
    }
  };
  for (let i = scaled(S.hazards.flood); i > 0; i--) pocket("flood", 10 + 2 * stratum + r.int(0, 4));
  for (let i = scaled(S.hazards.magma); i > 0; i--) pocket("magma", 7 + r.int(0, 3));
  for (let i = scaled(S.hazards.pools); i > 0; i--) pool();
  for (let i = scaled(S.hazards.caveIn); i > 0; i--) crack();

  // crystal walls: plain wall tiles with floor next to them, away from the mole pockets
  for (let n = scaled(S.crystals), tries = 0; n > 0 && tries < 600; tries++) {
    const x = r.int(2, W - 3), y = r.int(2, H - 3);
    if (!solidPlain(x, y) || !DIRS.some(([dx, dy]) => at(x + dx, y + dy) === K.FLOOR)) continue;
    if (moles.some((m) => Math.abs(m.tx - x) + Math.abs(m.ty - y) <= 3)) continue;
    put(x, y, K.CRYSTAL);
    n--;
  }

  // 10. enemies: beetles and thieves on floor tiles of the rooms away from the start, the King next to the exit lift
  /** @type {{kind: "beetle"|"thief"|"king", tx:number, ty:number}[]} */
  const enemies = [];
  const spot = (minFromStart, rs) => {
    for (let i = 0; i < 80; i++) {
      const rc = rs[r.int(0, rs.length - 1)];
      const x = r.int(rc.x, rc.x + rc.w - 1), y = r.int(rc.y, rc.y + rc.h - 1);
      if (at(x, y) === K.FLOOR && Math.abs(x - c0.x) + Math.abs(y - c0.y) >= minFromStart && !enemies.some((e) => e.tx === x && e.ty === y)) return { tx: x, ty: y };
    }
    return null;
  };
  const enemyRooms = rooms.length > 2 ? rooms.slice(2) : rooms;
  if (boss) {
    const rc = rooms[1];
    let k = null;
    for (const [dx, dy] of [[-3, 0], [-3, 1], [-3, -1], [3, 0], [0, 3], [0, -3], [-2, 0]]) if (!k && at(c1.x + dx, c1.y + dy) === K.FLOOR) k = { tx: c1.x + dx, ty: c1.y + dy };
    if (!k) k = spot(0, [rc]) ?? { tx: c1.x, ty: c1.y };
    enemies.push({ kind: "king", ...k });
  }
  for (let i = boss ? 2 : scaled(S.enemies.beetle); i > 0; i--) {
    const e = spot(12, enemyRooms);
    if (e) enemies.push({ kind: "beetle", ...e });
  }
  for (let i = scaled(S.enemies.thief); i > 0; i--) {
    const e = spot(22, enemyRooms);
    if (e) enemies.push({ kind: "thief", ...e });
  }

  // 11. bookkeeping
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
    oreCounts, oilCount, hazards, enemies, boss,
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
 * @param {{avoid?: number[]}} [opts]  Tile kinds that count as walls (the fluids and cracked floor, to prove the way out never needs them).
 */
export function exitReachable(mine, tier, opts = {}) {
  const { width: W, height: H, kinds } = mine;
  const avoid = new Set(opts.avoid ?? []);
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
      if (avoid.has(kinds[j])) continue;
      seen[j] = 1;
      stack.push(j);
    }
  }
  return false;
}

/**
 * A 32-bit FNV-1a fingerprint of a mine (its size, seed, stratum, floor, every tile kind, the lifts, the spawn tiles, the
 * moles and the enemies), as 8 lowercase hex digits. It changes when a tile is dug, so it also fingerprints a save.
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
  for (const e of mine.enemies ?? []) {
    feed(e.kind === "beetle" ? 1 : e.kind === "thief" ? 2 : 3);
    feed(e.tx);
    feed(e.ty);
  }
  return (h >>> 0).toString(16).padStart(8, "0");
}
