// @ts-check
// The road network as the walkers see it (pure): which cells are road, where each building can be entered, and routes along
// the roads.
//
// Routes are found with a distance FIELD per goal: one breadth-first search from the goal's access cells over the road
// cells gives every road cell its distance to the goal, and a route is read off by stepping to the neighbour with the smaller
// distance. Many walkers heading for the same building share one field, so 500 walkers cost a few searches, not 500
// (docs/ARCHITECTURE-like numbers are in README.md, "Walkers"). A field stays valid until the roads change (`version`).
//
// A single-pair A* backend (the engine's nav.findTilePath, see scripts/game/nav_backend.js) can be plugged in with
// `setFinder` to compare costs; the stress scene measures both.
import { footprintCells } from "./rules.js";
import { DIRS } from "./iso.js";

/** @typedef {(road: Uint8Array, width: number, height: number, from: number, to: number) => number[] | null} Finder */

export class RoadNet {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.width = state.map.width;
    this.height = state.map.height;
    /** 1 on a road cell (index r * width + c). */
    this.road = new Uint8Array(this.width * this.height);
    /** Counts every change of the road cells; a cached field is valid only for the version it was made at. */
    this.version = 0;
    /** @type {Map<number, { version: number, dist: Int16Array }>} goal building id (> 0) or cell (-index - 1) -> field */
    this.fields = new Map();
    /** @type {Map<number, { version: number, cells: number[] }>} */
    this.access = new Map();
    this.queue = new Int32Array(this.width * this.height);
    /** @type {Finder | null} */
    this.finder = null;
    /** Searches run so far (the stress report prints it). */
    this.searches = 0;
    for (const b of state.buildings.values()) if (this.isRoadType(b.type)) this.road[b.y * this.width + b.x] = 1;
    const ev = state.events;
    ev.on("building.placed", (e) => this.changed(e.building, 1));
    ev.on("building.removed", (e) => this.changed(e.building, 0));
  }

  isRoadType(type) {
    return this.state.data.buildings[type].kind === "road";
  }

  changed(b, value) {
    if (!this.isRoadType(b.type)) return;
    this.road[b.y * this.width + b.x] = value;
    this.version++;
  }

  index(c, r) {
    return r * this.width + c;
  }

  /** Use a single-pair path finder instead of the fields (null goes back to the fields). @param {Finder | null} finder */
  setFinder(finder) {
    this.finder = finder;
  }

  /** The road cells next to a building's footprint (edge neighbours), ascending, where a walker can enter or leave it. @returns {number[]} */
  accessCells(b) {
    const hit = this.access.get(b.id);
    if (hit && hit.version === this.version) return hit.cells;
    const def = this.state.data.buildings[b.type];
    const own = new Set();
    const cells = footprintCells(def, b.x, b.y, b.rot);
    for (const [c, r] of cells) own.add(this.index(c, r));
    const out = new Set();
    for (const [c, r] of cells) {
      for (const [dc, dr] of DIRS) {
        const nc = c + dc;
        const nr = r + dr;
        if (nc < 0 || nr < 0 || nc >= this.width || nr >= this.height) continue;
        const i = this.index(nc, nr);
        if (this.road[i] && !own.has(i)) out.add(i);
      }
    }
    const list = [...out].sort((a, b2) => a - b2);
    this.access.set(b.id, { version: this.version, cells: list });
    return list;
  }

  /** The distance field to a building (or to a cell with `cellField`): -1 where the goal cannot be reached. @returns {Int16Array} */
  field(b) {
    return this.fieldFor(b.id, () => this.accessCells(b));
  }

  /** The distance field to one road cell. */
  cellField(index) {
    return this.fieldFor(-index - 1, () => (this.road[index] ? [index] : []));
  }

  fieldFor(key, sources) {
    const hit = this.fields.get(key);
    if (hit && hit.version === this.version) return hit.dist;
    if (this.fields.size > 600) this.fields.clear();
    const dist = new Int16Array(this.width * this.height).fill(-1);
    const q = this.queue;
    let head = 0;
    let tail = 0;
    for (const i of sources()) {
      dist[i] = 0;
      q[tail++] = i;
    }
    const w = this.width;
    const h = this.height;
    while (head < tail) {
      const i = q[head++];
      const c = i % w;
      const r = (i - c) / w;
      const d = dist[i] + 1;
      if (c + 1 < w && this.road[i + 1] && dist[i + 1] < 0) { dist[i + 1] = d; q[tail++] = i + 1; }
      if (r + 1 < h && this.road[i + w] && dist[i + w] < 0) { dist[i + w] = d; q[tail++] = i + w; }
      if (c > 0 && this.road[i - 1] && dist[i - 1] < 0) { dist[i - 1] = d; q[tail++] = i - 1; }
      if (r > 0 && this.road[i - w] && dist[i - w] < 0) { dist[i - w] = d; q[tail++] = i - w; }
    }
    this.searches++;
    this.fields.set(key, { version: this.version, dist });
    return dist;
  }

  /** Walk down a field from a cell to the goal. @returns {number[]} cells, the start and an access cell of the goal included */
  descend(dist, start) {
    const path = [start];
    const w = this.width;
    let cur = start;
    let guard = this.width * this.height;
    while (dist[cur] > 0 && guard-- > 0) {
      const want = dist[cur] - 1;
      const c = cur % w;
      const r = (cur - c) / w;
      let next = -1;
      if (c + 1 < w && dist[cur + 1] === want) next = cur + 1;
      else if (r + 1 < this.height && dist[cur + w] === want) next = cur + w;
      else if (c > 0 && dist[cur - 1] === want) next = cur - 1;
      else if (r > 0 && dist[cur - w] === want) next = cur - w;
      if (next < 0) return path; // cannot happen on a field made by fieldFor
      path.push(next);
      cur = next;
    }
    return path;
  }

  /**
   * A route over the roads from the nearest of some start cells to a building. `starts` are road cell indices.
   * @param {number[]} starts @param {{ id: number, type: string, x: number, y: number, rot: number }} goal
   * @returns {number[] | null} cells, or null when there is no way
   */
  routeFrom(starts, goal) {
    if (!starts.length) return null;
    if (this.finder) return this.routeWithFinder(starts, goal);
    const dist = this.field(goal);
    let best = -1;
    let bestD = 32767;
    for (const s of starts) {
      const d = dist[s];
      if (d >= 0 && d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return best < 0 ? null : this.descend(dist, best);
  }

  /**
   * The route from one building's door to another's. Both directions cost the same, so `viaFrom` finds it with the distance
   * field of `from` instead of the one of `to`: a town has few workplaces and many houses, and the walk home reuses the
   * field the walk to work already made.
   */
  routeBuildings(from, to, viaFrom = false) {
    if (!viaFrom || this.finder) return this.routeFrom(this.accessCells(from), to);
    const back = this.routeFrom(this.accessCells(to), from);
    return back ? back.reverse() : null;
  }

  /** The route from one road cell to a road cell. */
  routeCells(from, to) {
    if (!this.road[from] || !this.road[to]) return null;
    if (this.finder) return this.finder(this.road, this.width, this.height, from, to);
    const dist = this.cellField(to);
    return dist[from] < 0 ? null : this.descend(dist, from);
  }

  routeWithFinder(starts, goal) {
    const goals = this.accessCells(goal);
    if (!goals.length) return null;
    const from = starts[0];
    const fc = from % this.width;
    const fr = (from - fc) / this.width;
    let best = goals[0];
    let bestD = Infinity;
    for (const g of goals) {
      const gc = g % this.width;
      const gr = (g - gc) / this.width;
      const d = Math.abs(gc - fc) + Math.abs(gr - fr);
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    this.searches++;
    return this.finder(this.road, this.width, this.height, from, best);
  }

  /** Road distance (cells) between two buildings' doors, or -1. */
  distance(from, to) {
    const dist = this.field(to);
    let best = -1;
    for (const s of this.accessCells(from)) {
      const d = dist[s];
      if (d >= 0 && (best < 0 || d < best)) best = d;
    }
    return best;
  }

  /** The nearest road cell to a cell within `radius` cells (Manhattan), lowest index first on a tie, or -1. */
  nearestRoad(index, radius) {
    const w = this.width;
    const c0 = index % w;
    const r0 = (index - c0) / w;
    let best = -1;
    let bestD = Infinity;
    for (let r = Math.max(0, r0 - radius); r <= Math.min(this.height - 1, r0 + radius); r++) {
      for (let c = Math.max(0, c0 - radius); c <= Math.min(w - 1, c0 + radius); c++) {
        const i = r * w + c;
        if (!this.road[i]) continue;
        const d = Math.abs(c - c0) + Math.abs(r - r0);
        if (d <= radius && d < bestD) {
          bestD = d;
          best = i;
        }
      }
    }
    return best;
  }
}
