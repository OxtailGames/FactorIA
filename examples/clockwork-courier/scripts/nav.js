// @ts-check
// Path finding without a navmesh (the engine has none: ENGINE_FEEDBACK "no path finding"). A NavGrid is a lazy height-field
// grid laid over the physics world: a cell is asked about only when the search reaches it, and answers with
//   1. the height of the ground under it (a ray straight down from `ceilY`), and
//   2. whether a sphere the size of the walker fits there (physics.overlapSphere, ignoring triggers and characters).
// Two neighbours connect when both are free and the ground height differs by at most `step`, so ledges, gaps and walls
// are never crossed, and stairs and ramps are. findPath() is A* over that grid. Used by the guard dogs (scripts/dog.js)
// and by tap-to-move (scripts/tap_move.js).
//
//   const nav = new NavGrid({ ceilY: 3 });
//   const r = nav.findPath([x0, z0], [x1, z1]);   // { path: [[x, z, y], ...], complete: boolean } or null
//
// One grid remembers what it learned: build a new one when the level changes under it (a gate opens, a crate moves).
import { physics } from "factoria";

export class NavGrid {
  /**
   * @param {{ cell?: number, ceilY: number, depth?: number, step?: number, radius?: number, clearance?: number, minNormalY?: number }} o
   *   cell       size of a cell in metres (0.5)
   *   ceilY      height the downward rays start from: anything above it (a roof overhead) is ignored
   *   depth      how far below ceilY a ground still counts (a deeper drop is "no ground": the street far below a roof)
   *   step       highest height difference between neighbours that can be walked (0.4)
   *   radius     radius of the walker (0.3); clearance: height of the sphere's centre above the ground (0.45)
   *   minNormalY a ground steeper than this normal.y (0.72, about 44 degrees) is a wall
   */
  constructor(o) {
    this.cell = o.cell ?? 0.5;
    this.ceilY = o.ceilY;
    this.depth = o.depth ?? 6;
    this.step = o.step ?? 0.4;
    this.radius = o.radius ?? 0.3;
    this.clearance = o.clearance ?? 0.45;
    this.minNormalY = o.minNormalY ?? 0.72;
    /** @type {Map<number, { h: number, ok: boolean }>} */
    this.cells = new Map();
    /** Cells asked so far (a measure of the work done). */
    this.queries = 0;
  }

  key(ix, iz) {
    return (ix + 32768) * 65536 + (iz + 32768);
  }

  toCell(x, z) {
    return [Math.floor(x / this.cell), Math.floor(z / this.cell)];
  }

  center(ix, iz) {
    return [(ix + 0.5) * this.cell, (iz + 0.5) * this.cell];
  }

  /** The cell's ground height and whether it can be stood on. Cached. */
  at(ix, iz) {
    const k = this.key(ix, iz);
    let c = this.cells.get(k);
    if (c) return c;
    this.queries++;
    const [cx, cz] = this.center(ix, iz);
    c = { h: NaN, ok: false };
    // The ray may first hit a character (courier, dog): look again from below that hit.
    let y = this.ceilY;
    let hit = null;
    for (let i = 0; i < 4; i++) {
      hit = physics.raycast3d([cx, y, cz], [0, -1, 0], this.depth + (this.ceilY - y));
      if (!hit) break;
      if (hit.entity.hasTag("courier") || hit.entity.hasTag("dog") || hit.entity.hasTag("nonnav")) {
        y = hit.point.y - 0.02;
        hit = null;
        continue;
      }
      break;
    }
    if (hit && hit.normal.y >= this.minNormalY) {
      c.h = hit.point.y;
      // Is there room for the walker? Everything but triggers, characters and the ground itself counts.
      const around = physics.overlapSphere([cx, c.h + this.clearance, cz], this.radius);
      c.ok = true;
      for (const e of around) {
        if (e.id === hit.entity.id || e.hasTag("courier") || e.hasTag("dog") || e.hasTag("nonnav")) continue;
        const col = e.get("Collider3D");
        if (col && col.isTrigger) continue;
        c.ok = false;
        break;
      }
    }
    this.cells.set(k, c);
    return c;
  }

  /** True when the world position stands on a free cell. */
  free(x, z) {
    const [ix, iz] = this.toCell(x, z);
    return this.at(ix, iz).ok;
  }

  /** Can the walker go from cell a to the (touching) cell b? */
  connects(ax, az, bx, bz) {
    const a = this.at(ax, az);
    const b = this.at(bx, bz);
    if (!a.ok || !b.ok || Math.abs(a.h - b.h) > this.step) return false;
    if (ax !== bx && az !== bz) {
      // Diagonal: both cells beside it must be free too (no cutting a corner).
      const p = this.at(bx, az);
      const q = this.at(ax, bz);
      if (!p.ok || !q.ok || Math.abs(p.h - a.h) > this.step || Math.abs(q.h - a.h) > this.step) return false;
    }
    return true;
  }

  /** The nearest free cell to a world position within `radius` cells (the target of a tap may sit on a wall). */
  nearestFree(x, z, radius = 3) {
    const [cx, cz] = this.toCell(x, z);
    let best = null;
    let bestD = Infinity;
    for (let dz = -radius; dz <= radius; dz++) {
      for (let dx = -radius; dx <= radius; dx++) {
        const c = this.at(cx + dx, cz + dz);
        if (!c.ok) continue;
        const d = dx * dx + dz * dz;
        if (d < bestD) {
          bestD = d;
          best = [cx + dx, cz + dz];
        }
      }
    }
    return best;
  }

  /** Is the straight line between two world points walkable (every cell on it free, no step too high)? */
  lineClear(ax, az, bx, bz) {
    const len = Math.hypot(bx - ax, bz - az);
    const n = Math.max(1, Math.ceil(len / (this.cell * 0.5)));
    let prev = null;
    for (let i = 0; i <= n; i++) {
      const t = i / n;
      const [ix, iz] = this.toCell(ax + (bx - ax) * t, az + (bz - az) * t);
      const c = this.at(ix, iz);
      if (!c.ok) return false;
      if (prev && Math.abs(prev.h - c.h) > this.step) return false;
      prev = c;
    }
    return true;
  }

  /**
   * A* from `from` to `to` (world [x, z]). The start may be anywhere (the nearest free cell is used), the goal too.
   * @returns {{ path: number[][], complete: boolean, nodes: number } | null} the waypoints [x, z, groundY] from the
   *   first cell to the goal; `complete` false means the goal cannot be reached and the path leads to the closest cell
   *   found. null when even the start is on no ground.
   */
  findPath(from, to, opts = {}) {
    const maxNodes = opts.maxNodes ?? 1800;
    const s = this.nearestFree(from[0], from[1], 2);
    if (!s) return null;
    const g = this.nearestFree(to[0], to[1], 3) ?? this.toCell(to[0], to[1]);
    const [sx, sz] = s;
    const [gx, gz] = g;
    const heap = new MinHeap();
    /** @type {Map<number, { g: number, parent: number, ix: number, iz: number, closed: boolean }>} */
    const nodes = new Map();
    const h = (ix, iz) => {
      const dx = Math.abs(ix - gx);
      const dz = Math.abs(iz - gz);
      return (dx + dz) + (Math.SQRT2 - 2) * Math.min(dx, dz);
    };
    const sk = this.key(sx, sz);
    nodes.set(sk, { g: 0, parent: -1, ix: sx, iz: sz, closed: false });
    heap.push(sk, h(sx, sz));
    let bestKey = sk;
    let bestH = h(sx, sz);
    let expanded = 0;
    let goalKey = -1;
    while (heap.size > 0 && expanded < maxNodes) {
      const k = heap.pop();
      const n = nodes.get(k);
      if (!n || n.closed) continue;
      n.closed = true;
      expanded++;
      if (n.ix === gx && n.iz === gz) {
        goalKey = k;
        break;
      }
      const hn = h(n.ix, n.iz);
      if (hn < bestH) {
        bestH = hn;
        bestKey = k;
      }
      for (let dz = -1; dz <= 1; dz++) {
        for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dz === 0) continue;
          const nx = n.ix + dx;
          const nz = n.iz + dz;
          if (!this.connects(n.ix, n.iz, nx, nz)) continue;
          const nk = this.key(nx, nz);
          const cost = n.g + (dx !== 0 && dz !== 0 ? Math.SQRT2 : 1);
          const old = nodes.get(nk);
          if (old && (old.closed || old.g <= cost)) continue;
          nodes.set(nk, { g: cost, parent: k, ix: nx, iz: nz, closed: false });
          heap.push(nk, cost + h(nx, nz));
        }
      }
    }
    const endKey = goalKey >= 0 ? goalKey : bestKey;
    const cells = [];
    for (let k = endKey; k !== -1; k = nodes.get(k).parent) cells.push(nodes.get(k));
    cells.reverse();
    let path = cells.map((n) => {
      const [cx, cz] = this.center(n.ix, n.iz);
      return [cx, cz, this.at(n.ix, n.iz).h];
    });
    if (goalKey >= 0 && this.free(to[0], to[1])) path[path.length - 1] = [to[0], to[1], this.at(...this.toCell(to[0], to[1])).h];
    path = this.smooth(path);
    return { path, complete: goalKey >= 0, nodes: expanded };
  }

  /** Drops waypoints that a straight walk can skip. */
  smooth(path) {
    if (path.length <= 2) return path;
    const out = [path[0]];
    let i = 0;
    while (i < path.length - 1) {
      let j = path.length - 1;
      while (j > i + 1 && !this.lineClear(path[i][0], path[i][1], path[j][0], path[j][1])) j--;
      out.push(path[j]);
      i = j;
    }
    return out;
  }
}

/** A binary min-heap of (key, priority). */
class MinHeap {
  constructor() {
    this.keys = [];
    this.pri = [];
  }

  get size() {
    return this.keys.length;
  }

  push(key, p) {
    const k = this.keys;
    const q = this.pri;
    let i = k.length;
    k.push(key);
    q.push(p);
    while (i > 0) {
      const par = (i - 1) >> 1;
      if (q[par] <= q[i]) break;
      [k[par], k[i]] = [k[i], k[par]];
      [q[par], q[i]] = [q[i], q[par]];
      i = par;
    }
  }

  pop() {
    const k = this.keys;
    const q = this.pri;
    const top = k[0];
    const lastK = k.pop();
    const lastQ = q.pop();
    if (k.length > 0) {
      k[0] = lastK;
      q[0] = lastQ;
      let i = 0;
      for (;;) {
        const l = 2 * i + 1;
        const r = l + 1;
        let m = i;
        if (l < k.length && q[l] < q[m]) m = l;
        if (r < k.length && q[r] < q[m]) m = r;
        if (m === i) break;
        [k[m], k[i]] = [k[i], k[m]];
        [q[m], q[i]] = [q[i], q[m]];
        i = m;
      }
    }
    return top;
  }
}
