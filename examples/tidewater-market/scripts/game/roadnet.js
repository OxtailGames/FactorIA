// @ts-check
// The road network as the walkers see it (pure): which cells are road, where each building can be entered, and routes along
// the roads.
//
// Routes are found with a flow field per goal (the engine's nav.flowField over a grid kept by nav.createGrid): one search from
// the goal's access cells over the road cells gives every road cell its distance to the goal, and a route is read off by
// stepping to the neighbour with the smaller distance. Many walkers heading for the same building share one field, so 500
// walkers cost a few searches, not 500 (the numbers are in README.md, "Stress scene"). Each road placed or removed is one
// `grid.setCost`; a field the roads outlived is rebuilt by the engine when it is next asked, and a goal's field is made
// anew when its access cells may have changed (`version`).
//
// A single-pair A* backend (the engine's nav.findTilePath on the same grid, see scripts/game/nav_backend.js) can be plugged
// in with `setFinder` to compare costs; the stress test checks both.
import { footprintCells } from "./rules.js";
import { DIRS } from "./iso.js";
import { nav } from "factoria";

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
    /** The roads as the engine's cost grid: 1 on a road, blocked elsewhere; `road` mirrors it for the callers that read cells. */
    this.grid = nav.createGrid({ width: this.width, height: this.height, cost: new Array(this.width * this.height).fill(Infinity) });
    /** @type {Map<number, { version: number, field: import("factoria").NavFlowField | null }>} goal building id (> 0) or cell (-index - 1) -> field */
    this.fields = new Map();
    /** @type {Map<number, { version: number, cells: number[] }>} */
    this.access = new Map();
    /** @type {Finder | null} */
    this.finder = null;
    /** Searches run so far (the stress report prints it). */
    this.searches = 0;
    for (const b of state.buildings.values()) if (this.isRoadType(b.type)) this.setRoad(b.y * this.width + b.x, 1);
    const ev = state.events;
    ev.on("building.placed", (e) => this.changed(e.building, 1));
    ev.on("building.removed", (e) => this.changed(e.building, 0));
  }

  isRoadType(type) {
    return this.state.data.buildings[type].kind === "road";
  }

  changed(b, value) {
    if (!this.isRoadType(b.type)) return;
    this.setRoad(b.y * this.width + b.x, value);
    this.version++;
  }

  setRoad(index, value) {
    this.road[index] = value;
    const c = index % this.width;
    this.grid.setCost(c, (index - c) / this.width, value ? 1 : Infinity);
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

  /** The flow field to a building (or to a cell with `cellField`), null when the goal has no road cell to enter by. */
  field(b) {
    return this.fieldFor(b.id, () => this.accessCells(b));
  }

  /** The flow field to one road cell. */
  cellField(index) {
    return this.fieldFor(-index - 1, () => (this.road[index] ? [index] : []));
  }

  fieldFor(key, sources) {
    const hit = this.fields.get(key);
    if (hit && hit.version === this.version) return hit.field;
    if (this.fields.size > 600) this.fields.clear();
    const w = this.width;
    const goals = sources().map((i) => ({ col: i % w, row: Math.floor(i / w) }));
    // no goal cell (a building with no road next to it): nothing reaches it
    const field = goals.length ? nav.flowField(this.grid, goals) : null;
    this.searches++;
    this.fields.set(key, { version: this.version, field });
    return field;
  }

  /** Distance (cells) from a road cell to the goal of a field, or -1 when it cannot be reached. */
  fieldDistance(field, index) {
    if (!field) return -1;
    const w = this.width;
    const c = index % w;
    const d = field.distance(c, (index - c) / w);
    return d === Infinity ? -1 : d;
  }

  /** Walk down a field from a cell to the goal. @returns {number[]} cells, the start and an access cell of the goal included */
  descend(field, start) {
    if (!field) return [start];
    const w = this.width;
    const c = start % w;
    return field.pathFrom(c, (start - c) / w).map((cell) => cell.row * w + cell.col);
  }

  /**
   * A route over the roads from the nearest of some start cells to a building. `starts` are road cell indices.
   * @param {number[]} starts @param {{ id: number, type: string, x: number, y: number, rot: number }} goal
   * @returns {number[] | null} cells, or null when there is no way
   */
  routeFrom(starts, goal) {
    if (!starts.length) return null;
    if (this.finder) return this.routeWithFinder(starts, goal);
    const field = this.field(goal);
    let best = -1;
    let bestD = 32767;
    for (const s of starts) {
      const d = this.fieldDistance(field, s);
      if (d >= 0 && d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return best < 0 ? null : this.descend(field, best);
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
    const field = this.cellField(to);
    return this.fieldDistance(field, from) < 0 ? null : this.descend(field, from);
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
    const field = this.field(to);
    let best = -1;
    for (const s of this.accessCells(from)) {
      const d = this.fieldDistance(field, s);
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
