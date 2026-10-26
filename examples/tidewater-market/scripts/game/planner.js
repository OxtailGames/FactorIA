// @ts-check
// Planner (pure): where a town grows. It knows nothing about money or what the town needs (bot.js decides that); it answers
// two questions: "which roads come next" and "where does a building of this type go". The town starts at the harbour
// (harbour.js) and grows along a lattice of streets through it, one every `STREET_SPACING` cells, so buildings have road
// frontage on streets and a house always has a road to it. The lattice goes round rock and trees by the lines that are free.
//
//   const planner = new Planner(state);
//   planner.build("market")   // lays roads when there is no site, then places it: { ok, building } | { ok: false, reason }
//
// Everything is a pure function of the map and what is built, so the same map gives the same town (no random numbers).
import { harbourCell } from "./harbour.js";
import { checkPlacement, footprintCells, frontageCells, sizeAt } from "./rules.js";

/** Cells between two parallel streets: room for two rows of 2-cell buildings. */
export const STREET_SPACING = 5;
/** Streets reach this many cells (Manhattan distance) from the harbour. */
const REACH = 34;
/** What a street cell off the lattice costs against 1 on it: streets keep to the lattice unless something is in the way. */
const DETOUR = 4;
/** The largest (width - 1) / 2 + (height - 1) / 2 of any building: how far a site's centre can be from its origin cell. */
const MAX_HALF_SIZES = 3;

export class Planner {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.harbour = harbourCell(state.map);
    /** @type {number[][]} road cells in the order they are laid; each one touches the harbour or an earlier cell */
    this.plan = this.makePlan();
    /** Keys (r * width + c) of the plan cells: buildings keep off them, roads go there. */
    this.planKeys = new Set(this.plan.map(([c, r]) => r * state.map.width + c));
    /** Every cell key (r * width + c), nearest to the harbour first (ties by index): the order sites are searched in. */
    this.order = Array.from({ length: state.map.width * state.map.height }, (_, i) => i);
    const w = state.map.width;
    const dist = (i) => Math.abs((i % w) - this.harbour[0]) + Math.abs(Math.floor(i / w) - this.harbour[1]);
    this.order.sort((a, b) => dist(a) - dist(b) || a - b);
    /** Plan cells a road cannot be laid on (keys r * width + c). */
    this.blocked = new Set();
  }

  roadable(c, r) {
    const { map, data } = this.state;
    const t = map.terrainAt(c, r);
    return !!t && data.buildings.road.terrain.includes(t);
  }

  /**
   * The street lattice: every cell on a line of columns or rows `STREET_SPACING` apart through the harbour that can take a road
   * and is reachable from the harbour over such cells, nearest first.
   */
  makePlan() {
    const { map } = this.state;
    const [hc, hr] = this.harbour;
    const w = map.width;
    const onLattice = (c, r) => (c - hc) % STREET_SPACING === 0 || (r - hr) % STREET_SPACING === 0;
    // Dijkstra over the cells a road may take: a lattice cell costs 1, any other cell DETOUR, so a street leaves the lattice
    // only to get round rock or trees. Buckets by cost keep it deterministic (cells in the order they were reached).
    const dist = new Map([[hr * w + hc, 0]]);
    const parent = new Map();
    /** @type {number[][][]} */
    const buckets = [[[hc, hr]]];
    /** @type {number[][]} lattice cells in the order they are settled */
    const settled = [];
    const done = new Set();
    for (let d = 0; d < buckets.length; d++) {
      for (const [c, r] of buckets[d] || []) {
        const key = r * w + c;
        if (done.has(key) || dist.get(key) !== d) continue;
        done.add(key);
        if (onLattice(c, r)) settled.push([c, r]);
        for (const [dc, dr] of [[1, 0], [0, 1], [-1, 0], [0, -1]]) {
          const nc = c + dc;
          const nr = r + dr;
          if (!map.inBounds(nc, nr) || !this.roadable(nc, nr)) continue;
          if (Math.abs(nc - hc) + Math.abs(nr - hr) > REACH) continue;
          const nd = d + (onLattice(nc, nr) ? 1 : DETOUR);
          const nkey = nr * w + nc;
          if (dist.has(nkey) && dist.get(nkey) <= nd) continue;
          dist.set(nkey, nd);
          parent.set(nkey, key);
          (buckets[nd] = buckets[nd] || []).push([nc, nr]);
        }
      }
    }
    /** @type {number[][]} */
    const plan = [];
    const inPlan = new Set();
    for (const [c, r] of settled) {
      // the detour cells that lead to it first, then the cell itself
      const chain = [];
      for (let key = r * w + c; key !== undefined && !inPlan.has(key); key = parent.get(key)) chain.push(key);
      for (const key of chain.reverse()) {
        inPlan.add(key);
        plan.push([key % w, Math.floor(key / w)]);
      }
    }
    return plan;
  }

  /** Keys (r * width + c) of the road cells that join the harbour cell over roads (the harbour cell itself when it is a road). */
  connected() {
    const { map } = this.state;
    const [hc, hr] = this.harbour;
    const seen = new Set();
    if (!this.state.isRoad(hc, hr)) return seen;
    seen.add(hr * map.width + hc);
    const stack = [[hc, hr]];
    while (stack.length) {
      const [c, r] = /** @type {number[]} */ (stack.pop());
      for (const [dc, dr] of [[1, 0], [0, 1], [-1, 0], [0, -1]]) {
        const key = (r + dr) * map.width + c + dc;
        if (!map.inBounds(c + dc, r + dr) || seen.has(key) || !this.state.isRoad(c + dc, r + dr)) continue;
        seen.add(key);
        stack.push([c + dc, r + dr]);
      }
    }
    return seen;
  }

  /**
   * Lay up to `n` more cells of the plan, nearest first, each one touching a road that already joins the harbour (a building in
   * the way is walked round; the plan has more than one way to most cells). Returns how many roads were built; 0 when the plan
   * is used up or the town cannot afford the next one.
   */
  layRoads(n) {
    const state = this.state;
    const w = state.map.width;
    const joined = this.connected();
    const [hc, hr] = this.harbour;
    let built = 0;
    for (let pass = 0; pass < n; pass++) {
      let laidOne = false;
      for (const [c, r] of this.plan) {
        if (state.isRoad(c, r) || state.map.occupantAt(c, r) || this.blocked.has(r * w + c)) continue;
        const atHarbour = c === hc && r === hr;
        const touches = [[1, 0], [0, 1], [-1, 0], [0, -1]].some(([dc, dr]) => joined.has((r + dr) * w + c + dc));
        if (!atHarbour && !touches) continue;
        const res = state.placeRoads([[c, r]]);
        if (!res.ok) {
          if (res.skipped.length && res.skipped[0].reasons.some((x) => x.code === "cannot_afford")) return built; // try again with money
          this.blocked.add(r * w + c);
          continue;
        }
        joined.add(r * w + c);
        built++;
        laidOne = true;
        break;
      }
      if (!laidOne) break;
    }
    return built;
  }

  /**
   * The roads that join the harbour (a road cut off from it leads nowhere) and the cells within 2 of them (a footprint touching
   * a road starts there). Kept until the roads change, so a run of sites() calls does the walk once.
   * @returns {{ joined: Set<number>, near: Uint8Array }}
   */
  reach() {
    const version = this.state.sim.net.version;
    if (this.cached && this.cached.version === version) return this.cached;
    const { map } = this.state;
    const w = map.width;
    const near = new Uint8Array(w * map.height);
    const joined = this.connected();
    for (const key of joined) {
      const c = key % w;
      const r = (key - c) / w;
      for (let dr = -2; dr <= 2; dr++) for (let dc = -2; dc <= 2; dc++) if (map.inBounds(c + dc, r + dr)) near[(r + dr) * w + c + dc] = 1;
    }
    this.cached = { version, joined, near };
    return this.cached;
  }

  /**
   * Free places for a building of a type next to the roads, best first: { x, y, rot, score }. A site faces a road when it can
   * (the frontage is a road); the nearer to the harbour the better. Money is not looked at.
   */
  sites(type, limit = 6) {
    const state = this.state;
    const { map } = state;
    const def = state.data.buildings[type];
    const w0 = map.width;
    const h0 = map.height;
    const { joined, near } = this.reach();
    const [hc, hr] = this.harbour;
    /** @type {{ x: number, y: number, rot: number, score: number }[]} the best `limit` sites so far, best first */
    const out = [];
    const better = (a, b) => a.score - b.score || a.y - b.y || a.x - b.x || a.rot - b.rot;
    // cells nearest the harbour first; a site cannot score better than its origin's distance less the half sizes, so the
    // search stops as soon as `limit` sites are known and the next cell cannot beat the worst of them
    for (const key of this.order) {
      const x = key % w0;
      const y = (key - x) / w0;
      if (out.length >= limit && Math.abs(x - hc) + Math.abs(y - hr) - MAX_HALF_SIZES > out[limit - 1].score) break;
      if (!near[key]) continue;
      // the origin cell is in every footprint: an occupied or street cell rules out all four turns at once
      if (this.planKeys.has(key) || map.occupantAt(x, y) || state.isRoad(x, y)) continue;
      for (let rot = 0; rot < 4; rot++) {
        if (def.size[0] === def.size[1] && def.size[0] === 1 && rot > 0) break;
        // the streets still to come stay free: a building on a street cell would cut the lattice
        if (footprintCells(def, x, y, rot).some(([c, r]) => this.planKeys.has(r * w0 + c))) continue;
        const verdict = checkPlacement(state, type, x, y, rot);
        if (verdict.reasons.some((q) => q.code !== "cannot_afford")) continue;
        const front = frontageCells(def, x, y, rot).some(([c, r]) => joined.has(r * w0 + c));
        const touches = front || this.touchesRoad(def, x, y, rot, joined);
        if (!touches) continue;
        const [w, h] = sizeAt(def, rot);
        const dist = Math.abs(x + (w - 1) / 2 - hc) + Math.abs(y + (h - 1) / 2 - hr);
        out.push({ x, y, rot, score: dist + (front ? 0 : 3) });
        out.sort(better);
        if (out.length > limit) out.length = limit;
      }
    }
    return out;
  }

  touchesRoad(def, x, y, rot, joined) {
    const own = footprintCells(def, x, y, rot);
    const set = new Set(own.map(([c, r]) => r * this.state.map.width + c));
    for (const [c, r] of own) {
      for (const [dc, dr] of [[1, 0], [0, 1], [-1, 0], [0, -1]]) {
        const key = (r + dr) * this.state.map.width + c + dc;
        if (!set.has(key) && joined.has(key)) return true;
      }
    }
    return false;
  }

  /**
   * Build up to `n` buildings of a type, best sites first, one search for a whole batch (a site taken by an earlier building of
   * the batch just fails and the next one is tried). For laying out a whole town at once (stress_town.js); the bot builds one
   * at a time with build(). Returns how many were built.
   */
  buildMany(type, n) {
    let done = 0;
    for (let round = 0; round < n + 80 && done < n; round++) {
      const before = done;
      for (const s of this.sites(type, Math.min(n - done, 40) * 2)) {
        if (done >= n) break;
        // an earlier building of the batch may have taken the site: look first, a refused place() tells the player (action.rejected)
        const verdict = checkPlacement(this.state, type, s.x, s.y, s.rot);
        if (verdict.reasons.length) {
          if (verdict.reasons.some((q) => q.code === "cannot_afford")) return done;
          continue;
        }
        const res = this.state.place(type, s.x, s.y, s.rot);
        if (res.ok) done++;
        else if (res.reasons.some((q) => q.code === "cannot_afford")) return done;
      }
      if (done === before && this.layRoads(4) === 0) break;
    }
    return done;
  }

  /**
   * Build a building at the best site, laying more of the street plan first when there is none.
   * @returns {{ ok: true, building: any } | { ok: false, reason: string }}
   */
  build(type) {
    for (let attempt = 0; attempt < 6; attempt++) {
      const sites = this.sites(type);
      if (sites.length) {
        for (const s of sites.slice(0, 6)) {
          const res = this.state.place(type, s.x, s.y, s.rot);
          if (res.ok) return { ok: true, building: res.building };
          if (res.reasons.some((q) => q.code === "cannot_afford")) return { ok: false, reason: "cannot_afford" };
        }
      }
      if (this.layRoads(4) === 0) return { ok: false, reason: this.state.economy.coins < 2 ? "cannot_afford" : "no_site" };
    }
    return { ok: false, reason: "no_site_yet" }; // more streets next time
  }
}
