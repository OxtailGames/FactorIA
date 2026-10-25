// @ts-check
// Tile pathfinding on the live mine. FactorIA has no 2D or tile pathfinding (its `nav` is a 3D NavMesh), so the game keeps its
// own: an A* over the tiles of a MineMap that follows digging. A `NavGrid` listens to `map.onChange`, so its `version` goes up
// every time a tile changes and every cached path knows it is stale; a tunnel dug a second ago is walkable in the next search.
//
//   const nav = navFor(map);                          // one shared NavGrid per map
//   const r = nav.findPath({tx, ty}, {tx, ty}, opts); // {ok, path: [{tx,ty}...], cost, digs: [{tx,ty}...]}
//   const follower = new PathFollower(nav);           // walks a path: follower.goTo(...), follower.direction(pos)
//
// Contract of `findPath(from, to, opts)`:
//   - 4 neighbours, every step costs 1. The path includes the start and the goal tile.
//   - A solid tile blocks, unless `opts.dig = { tier, cost }` is given: then a tile the pick can dig (MineMap.canDig) is
//     walkable at cost `digTime * cost` (default cost 4) and is listed in `digs`, in path order. Bedrock never is.
//   - The danger kinds (water, magma, cracked floor: `isDangerKind` in tiles.js) cost `opts.dangerCost` extra. Default
//     Infinity = a wall. A finite number lets the search cross them when there is no other way.
//   - The goal tile is always allowed (so a path can end on the thing being chased, whatever it stands on).
//   - `opts.maxNodes` (default 20000) bounds the search; a search that runs out of nodes returns {ok: false, reason: "far"}.
//   - No path: {ok: false, path: [], reason: "blocked" | "far" | "off-map"}.
import { kindInfo, isDangerKind } from "./tiles.js";

/** A tiny binary min-heap of [priority, node] pairs. */
class Heap {
  constructor() {
    /** @type {number[]} */ this.p = [];
    /** @type {number[]} */ this.v = [];
  }
  get size() {
    return this.v.length;
  }
  push(priority, value) {
    let i = this.v.length;
    this.p.push(priority);
    this.v.push(value);
    while (i > 0) {
      const parent = (i - 1) >> 1;
      if (this.p[parent] <= this.p[i]) break;
      [this.p[parent], this.p[i]] = [this.p[i], this.p[parent]];
      [this.v[parent], this.v[i]] = [this.v[i], this.v[parent]];
      i = parent;
    }
  }
  pop() {
    const top = this.v[0];
    const lastP = /** @type {number} */ (this.p.pop()), lastV = /** @type {number} */ (this.v.pop());
    const n = this.v.length;
    if (n > 0) {
      this.p[0] = lastP;
      this.v[0] = lastV;
      let i = 0;
      for (;;) {
        const l = 2 * i + 1, r = l + 1;
        let m = i;
        if (l < n && this.p[l] < this.p[m]) m = l;
        if (r < n && this.p[r] < this.p[m]) m = r;
        if (m === i) break;
        [this.p[m], this.p[i]] = [this.p[i], this.p[m]];
        [this.v[m], this.v[i]] = [this.v[i], this.v[m]];
        i = m;
      }
    }
    return top;
  }
}

const STEPS = [[1, 0], [-1, 0], [0, 1], [0, -1]];

export class NavGrid {
  /** @param {import("./mine_map.js").MineMap} map */
  constructor(map) {
    this.map = map;
    /** Goes up by one every time a tile of the map changes (dig, collapse, flood...). */
    this.version = 0;
    this.off = map.onChange(() => {
      this.version++;
    });
  }

  /** Stops listening to the map. */
  dispose() {
    this.off();
  }

  /**
   * Shortest path between two tiles (see the contract at the top of this file).
   * @param {{tx:number,ty:number}} from
   * @param {{tx:number,ty:number}} to
   * @param {{dig?: {tier: number, cost?: number}, dangerCost?: number, maxNodes?: number}} [opts]
   * @returns {{ok: true, path: {tx:number,ty:number}[], cost: number, digs: {tx:number,ty:number}[]} | {ok: false, path: never[], reason: string}}
   */
  findPath(from, to, opts = {}) {
    const map = this.map;
    const W = map.width, H = map.height;
    if (!map.inBounds(from.tx, from.ty) || !map.inBounds(to.tx, to.ty)) return { ok: false, path: [], reason: "off-map" };
    const dangerCost = opts.dangerCost ?? Infinity;
    const digCost = opts.dig ? (opts.dig.cost ?? 4) : 0;
    const maxNodes = opts.maxNodes ?? 20000;
    const goal = to.ty * W + to.tx, start = from.ty * W + from.tx;
    /** Extra cost of entering a tile, or Infinity when it cannot be entered. */
    const enter = (tx, ty) => {
      const kind = map.kindAt(tx, ty);
      const info = kindInfo(kind);
      if (info.solid) {
        if (!opts.dig || !map.canDig(tx, ty, opts.dig.tier).ok) return Infinity;
        return info.digTime * digCost;
      }
      return isDangerKind(kind) ? dangerCost : 0;
    };
    const g = new Float32Array(W * H).fill(Infinity);
    const parent = new Int32Array(W * H).fill(-1);
    const done = new Uint8Array(W * H);
    const heap = new Heap();
    g[start] = 0;
    heap.push(Math.abs(from.tx - to.tx) + Math.abs(from.ty - to.ty), start);
    let expanded = 0;
    while (heap.size > 0) {
      const cur = heap.pop();
      if (done[cur]) continue;
      done[cur] = 1;
      if (cur === goal) break;
      if (++expanded > maxNodes) return { ok: false, path: [], reason: "far" };
      const cx = cur % W, cy = (cur - cx) / W;
      for (const [dx, dy] of STEPS) {
        const nx = cx + dx, ny = cy + dy;
        if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
        const n = ny * W + nx;
        if (done[n]) continue;
        const extra = n === goal ? 0 : enter(nx, ny);
        if (extra === Infinity) continue;
        const cost = g[cur] + 1 + extra;
        if (cost < g[n]) {
          g[n] = cost;
          parent[n] = cur;
          heap.push(cost + Math.abs(nx - to.tx) + Math.abs(ny - to.ty), n);
        }
      }
    }
    if (!done[goal]) return { ok: false, path: [], reason: "blocked" };
    /** @type {{tx:number,ty:number}[]} */
    const path = [];
    for (let i = goal; i !== -1; i = parent[i]) path.push({ tx: i % W, ty: Math.floor(i / W) });
    path.reverse();
    const digs = path.filter((p) => map.isSolid(p.tx, p.ty));
    return { ok: true, path, cost: g[goal], digs };
  }

  /**
   * Tiles within `radius` steps of a tile that can be walked to without crossing a danger kind or a solid tile (a flood fill).
   * Enemies use it to pick somewhere to wander or flee to.
   * @param {{tx:number,ty:number}} from
   * @param {number} radius
   * @returns {{tx:number,ty:number,d:number}[]}
   */
  reachable(from, radius) {
    const map = this.map;
    /** @type {Map<number, number>} */
    const seen = new Map([[from.ty * map.width + from.tx, 0]]);
    const out = [{ tx: from.tx, ty: from.ty, d: 0 }];
    for (let i = 0; i < out.length; i++) {
      const c = out[i];
      if (c.d >= radius) continue;
      for (const [dx, dy] of STEPS) {
        const nx = c.tx + dx, ny = c.ty + dy;
        const key = ny * map.width + nx;
        if (seen.has(key) || !map.inBounds(nx, ny) || map.isSolid(nx, ny) || isDangerKind(map.kindAt(nx, ny))) continue;
        seen.set(key, c.d + 1);
        out.push({ tx: nx, ty: ny, d: c.d + 1 });
      }
    }
    return out;
  }
}

/** @type {WeakMap<object, NavGrid>} */
const grids = new WeakMap();

/**
 * The NavGrid of a map: one per map, shared by everything that asks (enemies, the bot), created on the first call.
 * @param {import("./mine_map.js").MineMap} map
 */
export function navFor(map) {
  let nav = grids.get(map);
  if (!nav) {
    nav = new NavGrid(map);
    grids.set(map, nav);
  }
  return nav;
}

/** True when there is a straight line of walkable tiles between two tiles (no solid tile on the way; the ends do not count). */
export function lineOfSight(map, a, b) {
  let x = a.tx, y = a.ty;
  const dx = Math.abs(b.tx - x), dy = Math.abs(b.ty - y);
  const sx = x < b.tx ? 1 : -1, sy = y < b.ty ? 1 : -1;
  let err = dx - dy;
  for (let guard = 0; guard < 400; guard++) {
    if (x === b.tx && y === b.ty) return true;
    if ((x !== a.tx || y !== a.ty) && map.isSolid(x, y)) return false;
    const e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      x += sx;
    }
    if (e2 < dx) {
      err += dx;
      y += sy;
    }
  }
  return true;
}

/**
 * Walks a path: ask for a goal, then ask every frame which way to go. It searches again when the goal moved to another tile or
 * the map changed since the path was found (digging, a collapse, a flood), but never more often than `every` seconds.
 */
export class PathFollower {
  /**
   * @param {NavGrid} nav
   * @param {{dig?: {tier: number, cost?: number}, dangerCost?: number}} [opts]  The `findPath` options every search uses.
   */
  constructor(nav, opts = {}) {
    this.nav = nav;
    this.opts = opts;
    /** @type {{tx:number,ty:number}[]} */
    this.path = [];
    this.index = 0;
    this.version = -1;
    this.goal = { tx: -1, ty: -1 };
    this.ok = false;
    /** Seconds since the last search. */
    this.age = 99;
    /** Tiles of the path a pick still has to dig (empty when the path is open). */
    this.digs = /** @type {{tx:number,ty:number}[]} */ ([]);
  }

  /**
   * Sets the goal; searches the first time, when the goal moved to another tile, the map changed, or there was no path. Returns true while there is a path.
   * @param {{tx:number,ty:number}} from  The tile the walker stands on.
   * @param {{tx:number,ty:number}} goal
   * @param {number} dt
   * @param {number} [every]  Fewest seconds between two searches for the same goal, and twice that for a goal that keeps moving (default 0.3).
   */
  goTo(from, goal, dt, every = 0.3) {
    this.age += dt;
    const sameGoal = goal.tx === this.goal.tx && goal.ty === this.goal.ty;
    const stale = this.version !== this.nav.version;
    const first = this.goal.tx < 0;
    // a new goal is searched at once the first time, then at most twice per `every` (a goal that moves every frame, a chased miner, must not search every frame)
    if (first || (!sameGoal && this.age >= every / 2) || (stale && this.age >= every) || (!this.ok && this.age >= every)) {
      const r = this.nav.findPath(from, goal, this.opts);
      this.age = 0;
      this.version = this.nav.version;
      this.goal = { tx: goal.tx, ty: goal.ty };
      this.ok = r.ok;
      this.path = r.ok ? r.path : [];
      this.digs = r.ok ? r.digs : [];
      this.index = r.ok && r.path.length > 1 ? 1 : 0;
    }
    return this.ok;
  }

  /** Forgets the path (the walker was teleported, or lost its goal). */
  clear() {
    this.path = [];
    this.ok = false;
    this.goal = { tx: -1, ty: -1 };
    this.index = 0;
  }

  /** The tile the walker is heading for next, or null when there is no path or it is finished. */
  get next() {
    return this.ok && this.index < this.path.length ? this.path[this.index] : null;
  }

  /**
   * The unit vector toward the next waypoint (the centre of the next tile of the path) from a world position, moving on to
   * the next waypoint when the walker is within `reach` units of the current one. `done` is true when the path is finished.
   * @param {{x:number,y:number}} pos
   * @param {number} [reach]
   * @returns {{x:number, y:number, done: boolean, tile: {tx:number,ty:number}|null}}
   */
  direction(pos, reach = 2.5) {
    const map = this.nav.map;
    while (this.index < this.path.length) {
      const t = this.path[this.index];
      const c = map.tileCenter(t.tx, t.ty);
      const dx = c.x - pos.x, dy = c.y - pos.y;
      const d = Math.hypot(dx, dy);
      if (d <= reach) {
        this.index++;
        continue;
      }
      return { x: dx / d, y: dy / d, done: false, tile: t };
    }
    return { x: 0, y: 0, done: true, tile: null };
  }
}

/** World distance of a point to the centre of a tile. */
export function distToTile(map, pos, tile) {
  const c = map.tileCenter(tile.tx, tile.ty);
  return Math.hypot(c.x - pos.x, c.y - pos.y);
}
