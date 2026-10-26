// @ts-check
// The interface's model (P3, pure: no engine calls, so the tests and the tools can use it anywhere). The panels in ui_hud.js only
// draw what is computed here:
//   formatCompact   9,999,999 -> "10M": numbers in a cramped bar never grow past 5 characters
//   categories      the build menu's tabs, from data/buildings.json
//   Recorder        the town's numbers once a day (money, goods made and used) for the table and the charts
//   goodsRows       the rows of the goods table, sorted by any column
//   Notices         the notifications: a stack of messages that expire, can be clicked to jump to a place and are not repeated
//   overlayField    desirability, market coverage, warehouse coverage and traffic as a value per cell
//   Traffic         counts the walkers per road cell
//   describeBuilding / describeVillager   what the inspector shows
//   canDropWorker   the rule of the drag and drop of a worker onto a workplace
//   SHORTCUTS       the keys, for the help panel and the tests
// It reads the GameState and listens to its events; the only thing it ever changes is itself.
import { footprintCells } from "./rules.js";

// ---- numbers -----------------------------------------------------------------------------------------------------------------

/** 0..9999 as it is, then 12.3k, 123k, 1.2M: at most 5 characters (with a sign 6). */
export function formatCompact(n) {
  const sign = n < 0 ? "-" : "";
  const v = Math.abs(Math.round(n));
  if (v < 10000) return sign + String(v);
  const trim = (x, digits) => x.toFixed(digits).replace(/\.0+$/, "");
  if (v < 100000) return `${sign}${trim(v / 1000, 1)}k`;
  if (v < 1000000) return `${sign}${Math.round(v / 1000)}k`;
  if (v < 100000000) return `${sign}${trim(v / 1000000, 1)}M`;
  return `${sign}${Math.round(v / 1000000)}M`;
}

// ---- the build menu ------------------------------------------------------------------------------------------------------------

/** The categories of the build menu in order of first appearance in data/buildings.json, each with its building ids. */
export function categories(data) {
  /** @type {Array<{ id: string, buildings: string[] }>} */
  const out = [];
  for (const id of data.buildingIds) {
    const cat = data.buildings[id].category;
    let entry = out.find((c) => c.id === cat);
    if (!entry) out.push((entry = { id: cat, buildings: [] }));
    entry.buildings.push(id);
  }
  return out;
}

/** Can a building be turned in place? (not roads, not houses) */
export function rotatable(data, type) {
  const def = data.buildings[type];
  return def.kind === "building" && !def.housing;
}

// ---- the daily record ----------------------------------------------------------------------------------------------------------

/**
 * One sample per game day (taken when the day changes, and one at the start): coins, and the ledger's running totals of what
 * was made and used of each good. The goods table's "per day" columns and the charts are differences of these samples.
 */
export class Recorder {
  /** @param {import("./state.js").GameState} state @param {number} [keepDays] */
  constructor(state, keepDays = 120) {
    this.state = state;
    this.keepDays = keepDays;
    /** @type {Array<{ day: number, coins: number, made: Record<string, number>, used: Record<string, number>, sales: number }>} */
    this.samples = [];
    this.take();
    this.off = state.events.on("clock.day", () => this.take());
  }

  destroy() {
    this.off();
  }

  take() {
    const l = this.state.sim.ledger;
    const made = {};
    const used = {};
    for (const g of this.state.data.goodIds) {
      made[g] = l.produced[g];
      used[g] = l.consumed[g] + l.eaten[g];
    }
    const sample = { day: this.state.clock.day, coins: this.state.economy.coins, made, used, sales: l.sales };
    const last = this.samples[this.samples.length - 1];
    if (last && last.day === sample.day) this.samples[this.samples.length - 1] = sample;
    else this.samples.push(sample);
    if (this.samples.length > this.keepDays) this.samples.splice(0, this.samples.length - this.keepDays);
  }

  /** Game days since a sample, counting the part of today that has passed. */
  elapsed(sample) {
    return this.state.clock.day + this.state.clock.dayFraction() - sample.day;
  }

  /** Goods made and used per day over the last `days` days (less when the game is younger). */
  rates(good, days = 5) {
    const l = this.state.sim.ledger;
    const first = this.samples.find((s) => s.day >= this.state.clock.day - days) || this.samples[0];
    const span = Math.max(this.elapsed(first), 0.25);
    return {
      made: (l.produced[good] - first.made[good]) / span,
      used: (l.consumed[good] + l.eaten[good] - first.used[good]) / span,
    };
  }

  /** The coins at the start of each of the last `n` days (oldest first); earlier days that were never sampled are left out. */
  money(n = 40) {
    return this.samples.slice(-n).map((s) => ({ day: s.day, value: s.coins }));
  }

  /** Units of a good made on each of the last `n` days (oldest first). */
  madePerDay(good, n = 40) {
    const out = [];
    for (let i = 1; i < this.samples.length; i++) {
      out.push({ day: this.samples[i - 1].day, value: this.samples[i].made[good] - this.samples[i - 1].made[good] });
    }
    return out.slice(-n);
  }
}

// ---- the goods table -----------------------------------------------------------------------------------------------------------

export const GOODS_COLUMNS = ["name", "stock", "made", "used", "price"];

/**
 * One row per good: { id, name, stock, made, used, price, base }; sorted by a column ("name" alphabetically, the others by value;
 * ties by the order of data/goods.json so the table never jumps).
 * @param {import("./state.js").GameState} state @param {Recorder} recorder
 * @param {{ column: string, dir: number }} sort  dir 1 ascending, -1 descending
 * @param {(id: string) => string} nameOf
 */
export function goodsRows(state, recorder, sort, nameOf) {
  const rows = state.data.goodIds.map((id, order) => {
    const r = recorder.rates(id);
    return { id, order, name: nameOf(id), stock: Math.floor(state.economy.get(id)), made: r.made, used: r.used, price: state.sim.priceOf(id), base: state.data.goods[id].basePrice };
  });
  const dir = sort.dir < 0 ? -1 : 1;
  rows.sort((a, b) => {
    const x = a[sort.column];
    const y = b[sort.column];
    const c = typeof x === "string" ? x.localeCompare(y) : x - y;
    return c * dir || a.order - b.order;
  });
  return rows;
}

// ---- notifications -------------------------------------------------------------------------------------------------------------

/**
 * @typedef {{ id: number, key: string, args: Record<string, any>, cell: number[] | null, building: number, count: number, ttl: number, age: number, sev: string, live?: (() => Record<string, any> | null) | null }} Notice
 *   key is a locale string under `notice.` (notice.noWorkers ...); cell is where a click takes the camera. `live`, when a notice has
 *   one, gives its arguments as they are NOW (a count that changes while the message is on the stack); it returns null when the
 *   thing the message was about is over, and the message goes.
 */

export class Notices {
  /**
   * Watches the game for things the player should know and keeps a stack of messages (newest first). A message is not repeated
   * while it is on the stack: the same message (key + building) only refreshes the one there and counts it.
   * @param {import("./state.js").GameState} state
   * @param {{ max?: number, seconds?: number }} [options] max = messages kept, seconds = how long one stays (real time)
   */
  constructor(state, options = {}) {
    this.state = state;
    this.max = options.max ?? 5;
    this.seconds = options.seconds ?? 14;
    /** @type {Notice[]} */
    this.items = [];
    this.nextId = 1;
    /** Game day each building was placed (a new building is not told off for having no workers yet). */
    this.born = new Map();
    /** Total messages ever pushed (tests, the achievements of P5). */
    this.pushed = 0;
    /** @type {((n: Notice) => void)[]} */
    this.listeners = [];
    this.sinceLive = 0;
    const ev = state.events;
    this.off = [
      ev.on("building.placed", (e) => this.born.set(e.building.id, state.clock.day)),
      ev.on("building.removed", (e) => {
        this.born.delete(e.building.id);
        this.items = this.items.filter((n) => n.building !== e.building.id);
      }),
      ev.on("clock.day", () => this.scan()),
      ev.on("payday", (e) => e.broke && this.push("broke", {}, null, 0, "bad")),
      ev.on("villager.left", (e) => this.push("left", { reason: e.reason }, null, 0, "warn")),
    ];
    for (const b of state.buildings.values()) this.born.set(b.id, state.clock.day);
  }

  destroy() {
    for (const off of this.off) off();
    this.off = [];
  }

  /** Call `fn` for every message that is new on the stack (not for one that only refreshes). @returns {() => void} stop listening */
  onNew(fn) {
    this.listeners.push(fn);
    return () => (this.listeners = this.listeners.filter((f) => f !== fn));
  }

  /**
   * Add a message (or refresh the same one). `live` gives the arguments as they are now (see Notice): the text of a count
   * ("443 villagers are hungry") must follow the number the top bar shows, not the number of the day the message was pushed.
   * @param {(() => Record<string, any> | null) | null} [live]
   * @returns {Notice}
   */
  push(key, args, cell, building, sev = "warn", live = null) {
    const same = this.items.find((n) => n.key === key && n.building === building && (n.args.good || "") === (args.good || ""));
    if (same) {
      same.count++;
      same.ttl = this.seconds;
      same.args = args;
      same.live = live;
      return same;
    }
    /** @type {Notice} */
    const n = { id: this.nextId++, key, args, cell, building, count: 1, ttl: this.seconds, age: 0, sev, live };
    this.pushed++;
    this.items.unshift(n);
    if (this.items.length > this.max) this.items.length = this.max;
    for (const fn of this.listeners) fn(n);
    return n;
  }

  dismiss(id) {
    this.items = this.items.filter((n) => n.id !== id);
  }

  /** Age the messages by real seconds; the expired ones go. Messages with a `live` take its arguments four times a second. */
  update(dt) {
    for (const n of this.items) {
      n.ttl -= dt;
      n.age += dt;
    }
    this.sinceLive += dt;
    if (this.sinceLive >= 0.25) {
      this.sinceLive = 0;
      this.refreshLive();
    }
    this.items = this.items.filter((n) => n.ttl > 0);
  }

  /** Bring the arguments of the messages that count something up to date; the ones whose cause is over are dropped. */
  refreshLive() {
    for (const n of this.items) {
      if (!n.live) continue;
      const args = n.live();
      if (args) n.args = args;
      else n.ttl = 0;
    }
  }

  /**
   * 0..1: how opaque a message is (it fades in over 0.25 s and out over its last second). With `reducedMotion` there is no
   * fading: a message is fully there for as long as it lasts.
   * @param {{ age: number, ttl: number }} n @param {boolean} [reducedMotion]
   */
  static opacity(n, reducedMotion = false) {
    if (reducedMotion) return n.ttl > 0 ? 1 : 0;
    return Math.max(0, Math.min(1, n.age / 0.25, n.ttl));
  }

  /**
   * Look at the town and say what is wrong: a workplace with nobody working in it, a building with no road, a producer waiting
   * for goods that are not in the stock, hungry villagers, a full warehouse. Called every game day.
   * @param {{ minAgeDays?: number }} [options] minAgeDays: a building younger than this is left alone (default 1 day)
   */
  scan(options = {}) {
    const { state } = this;
    const sim = state.sim;
    const minAge = options.minAgeDays ?? 1;
    const day = state.clock.day;
    for (const b of state.buildings.values()) {
      const def = state.data.buildings[b.type];
      if (def.kind === "road") continue;
      if (day - (this.born.get(b.id) ?? day) < minAge) continue;
      const cell = [b.x + Math.floor((b.w - 1) / 2), b.y + Math.floor((b.h - 1) / 2)];
      const rt = sim.rt.get(b.id);
      if (!rt) continue;
      if (sim.net.accessCells(b).length === 0) {
        this.push("noRoad", { type: b.type }, cell, b.id, "bad");
        continue;
      }
      if (def.workers && rt.staff.length === 0) this.push("noWorkers", { type: b.type }, cell, b.id, "warn");
      else if (rt.stall === "no_input" && def.recipes) {
        const missing = this.missingInput(rt, def);
        if (missing) this.push("noInput", { type: b.type, good: missing }, cell, b.id, "warn");
      }
    }
    const summary = sim.summary();
    if (summary.hungry > 0) {
      // the count follows the villagers who are hungry now; when nobody is, the message goes
      const hungry = () => {
        const count = sim.summary().hungry;
        return count > 0 ? { count } : null;
      };
      this.push("hungry", { count: summary.hungry }, null, 0, "bad", hungry);
    }
    const cap = sim.capacity();
    for (const g of state.data.goodIds) {
      if (state.economy.get(g) >= cap) this.push("storageFull", { good: g }, null, 0, "warn");
    }
  }

  /** The good a stalled producer lacks and the stock does not have either (the first input of its first recipe that is short). */
  missingInput(rt, def) {
    for (const id of def.recipes) {
      for (const g of Object.keys(this.state.data.recipes[id].inputs)) {
        if ((rt.inbox[g] || 0) < this.state.data.recipes[id].inputs[g] && this.state.economy.get(g) < this.state.data.recipes[id].inputs[g]) return g;
      }
    }
    return "";
  }
}

// ---- overlays ------------------------------------------------------------------------------------------------------------------

export const OVERLAYS = ["desirability", "market", "warehouse", "traffic"];
/** How far (in cells, straight line) a market sells and a warehouse's carriers go, for the coverage overlays. */
export const COVERAGE = { market: 9, warehouse: 12 };

/** The cell in the middle of a building. @returns {[number, number]} */
export function centreOf(b) {
  return [b.x + Math.floor((b.w - 1) / 2), b.y + Math.floor((b.h - 1) / 2)];
}

/** Counts how many walkers stood on each cell (display only: one count per clock step; the counts fade by half every game day). */
export class Traffic {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.counts = new Float32Array(state.map.width * state.map.height);
    this.max = 1;
    this.off = [
      state.events.on("clock.tick", () => this.sample()),
      state.events.on("clock.day", () => {
        for (let i = 0; i < this.counts.length; i++) this.counts[i] *= 0.5;
        this.max *= 0.5;
      }),
    ];
  }

  destroy() {
    for (const off of this.off) off();
  }

  sample() {
    const { width, height } = this.state.map;
    for (const w of this.state.sim.walkers.list.values()) {
      const c = Math.round(w.x);
      const r = Math.round(w.y);
      if (c < 0 || r < 0 || c >= width || r >= height) continue;
      const i = r * width + c;
      const n = (this.counts[i] += 1);
      if (n > this.max) this.max = n;
    }
  }
}

/**
 * A value 0..1 per cell for an overlay, and the list of the cells worth drawing.
 *   market, warehouse   1 on the building, fading to 0 at COVERAGE cells (straight line); the best of all the buildings
 *   desirability        how nice a free cell is to live on: water close by +, a market in reach +, noisy workplaces close by -
 *                       (drawn only on free cells near a road, where one would build)
 *   traffic             walkers per cell against the busiest cell
 * @param {import("./state.js").GameState} state @param {string} kind @param {Traffic | null} [traffic]
 * @returns {{ values: Float32Array, cells: number[] }}
 */
export function overlayField(state, kind, traffic = null) {
  const { width, height } = state.map;
  const values = new Float32Array(width * height);
  const cells = [];
  const mark = (i, v) => {
    if (v > 0 && values[i] === 0) cells.push(i);
    if (v > values[i]) values[i] = v;
  };
  if (kind === "market" || kind === "warehouse") {
    const radius = COVERAGE[kind];
    for (const b of state.buildings.values()) {
      if (b.type !== kind) continue;
      const [cc, cr] = centreOf(b);
      for (let r = Math.max(0, cr - radius); r <= Math.min(height - 1, cr + radius); r++) {
        for (let c = Math.max(0, cc - radius); c <= Math.min(width - 1, cc + radius); c++) {
          if (state.map.terrainAt(c, r) === "water") continue;
          const d = Math.hypot(c - cc, r - cr);
          if (d <= radius) mark(r * width + c, 1 - (d / radius) * 0.8);
        }
      }
    }
  } else if (kind === "traffic") {
    if (traffic) {
      for (let i = 0; i < traffic.counts.length; i++) {
        if (traffic.counts[i] > 0.5) mark(i, Math.min(1, traffic.counts[i] / Math.max(4, traffic.max)));
      }
    }
  } else if (kind === "desirability") {
    const markets = [...state.buildings.values()].filter((b) => b.type === "market").map(centreOf);
    const noisy = [...state.buildings.values()].filter((b) => ["quarry", "sawmill", "workshop"].includes(b.type)).map(centreOf);
    const roads = [...state.buildings.values()].filter((b) => state.data.buildings[b.type].kind === "road");
    const seen = new Set();
    for (const road of roads) {
      for (let r = road.y - 3; r <= road.y + 3; r++) {
        for (let c = road.x - 3; c <= road.x + 3; c++) {
          if (!state.map.inBounds(c, r)) continue;
          const i = r * width + c;
          if (seen.has(i)) continue;
          seen.add(i);
          if (state.map.occupantAt(c, r)) continue;
          const t = state.map.terrainAt(c, r);
          if (t !== "grass" && t !== "sand") continue;
          mark(i, desirabilityAt(state, c, r, markets, noisy));
        }
      }
    }
  }
  return { values, cells };
}

/** The desirability of a free cell, 0.05..1. */
export function desirabilityAt(state, c, r, markets, noisy) {
  let v = 0.45;
  for (let dr = -4; dr <= 4 && v < 2; dr++) {
    for (let dc = -4; dc <= 4; dc++) {
      if (state.map.terrainAt(c + dc, r + dr) === "water") {
        v += 0.25;
        dr = 5;
        break;
      }
    }
  }
  for (const [mc, mr] of markets) if (Math.hypot(c - mc, r - mr) <= COVERAGE.market) v += 0.25;
  for (const [nc, nr] of noisy) {
    const d = Math.hypot(c - nc, r - nr);
    if (d <= 5) v -= 0.4 * (1 - d / 5);
  }
  return Math.max(0.05, Math.min(1, v));
}

// ---- the inspector -------------------------------------------------------------------------------------------------------------

/** What the inspector shows about a building: raw facts, the panel words them. null when the building is gone. */
export function describeBuilding(state, id) {
  const b = state.buildings.get(id);
  if (!b) return null;
  const def = state.data.buildings[b.type];
  const rt = state.sim.rt.get(id);
  const people = state.sim.people;
  const info = {
    id, type: b.type, cell: centreOf(b), rot: b.rot, def, kind: def.kind,
    connected: def.kind === "road" ? true : state.sim.net.accessCells(b).length > 0,
    upkeep: def.upkeep || 0, refund: Math.floor((def.cost.coins || 0) * state.data.economy.refund),
    workers: null, residents: null, recipe: null, inbox: {}, outbox: {}, shelf: {}, stall: "", present: 0,
    rotatable: rotatable(state.data, b.type),
  };
  if (!rt) return info;
  info.stall = rt.stall;
  info.present = rt.present;
  if (def.workers) {
    info.workers = { max: def.workers, present: rt.present, staff: rt.staff.map((vid) => ({ id: vid, pinned: !!(people.villagers.get(vid) || {}).pin })) };
  }
  if (def.housing) info.residents = { max: def.housing, list: rt.residents.slice() };
  if (def.recipes && def.recipes.length) {
    const current = rt.cur ? state.data.recipes[rt.cur] : null;
    info.recipe = {
      id: rt.cur, progress: current ? Math.min(1, rt.progress / current.seconds) : 0,
      all: def.recipes.map((rid) => state.data.recipes[rid]), cycles: rt.cycles,
    };
  }
  info.inbox = { ...rt.inbox };
  info.outbox = { ...rt.outbox };
  info.shelf = { ...rt.shelf };
  return info;
}

/** What the inspector shows about a villager, or null when it left. */
export function describeVillager(state, id) {
  const v = state.sim.people.villagers.get(id);
  if (!v) return null;
  const home = state.buildings.get(v.home);
  const job = v.job ? state.buildings.get(v.job) : null;
  const at = state.buildings.get(v.at);
  const cargo = v.trip ? { ...v.trip.cargo } : {};
  return {
    id, home: home ? { id: home.id, type: home.type, cell: centreOf(home) } : null,
    job: job ? { id: job.id, type: job.type, cell: centreOf(job), pinned: !!v.pin } : null,
    at: at ? { id: at.id, type: at.type } : null, walking: v.state === "walking", purpose: v.purpose || "",
    food: v.food, hungry: v.food <= 0, cargo, carrying: Object.values(cargo).some((n) => n > 0),
    carrier: !!v.trip, errand: v.trip ? v.trip.kind : "",
  };
}

/** The walker nearest to a world point, within `radius` world units, or null. @returns {number | null} the villager id */
export function walkerNear(state, wx, wy, radius, cellToWorld) {
  let best = null;
  let bestD = radius;
  const alpha = state.clock.alpha;
  for (const w of state.sim.walkers.list.values()) {
    const [x, y] = cellToWorld(w.px + (w.x - w.px) * alpha, w.py + (w.y - w.py) * alpha);
    const d = Math.hypot(x - wx, y + 14 - wy); // the sprite is drawn standing on its cell: aim at its middle
    if (d < bestD) {
      bestD = d;
      best = w.id;
    }
  }
  return best;
}

// ---- drag and drop of a worker --------------------------------------------------------------------------------------------------

/**
 * May this villager be dropped on this building? { ok, code } with code: gone, no_jobs, same, no_road, full (the codes of
 * People.reassign). Asked while dragging, to colour the target.
 */
export function canDropWorker(state, villagerId, buildingId) {
  return state.sim.people.canReassign(villagerId, buildingId);
}

// ---- keys ----------------------------------------------------------------------------------------------------------------------

/** The shortcuts the help panel lists: { keys, action } where action is the locale string `help.<action>`. */
export const SHORTCUTS = [
  { keys: "B", action: "build" },
  { keys: "E / C", action: "cycle" },
  { keys: "R", action: "rotate" },
  { keys: "Del", action: "delete" },
  { keys: "X", action: "demolish" },
  { keys: "Esc / Q / right-click", action: "cancel" },
  { keys: "Z, Y", action: "undo" },
  { keys: "G", action: "goods" },
  { keys: "T", action: "charts" },
  { keys: "M", action: "overlay" },
  { keys: "N", action: "notice" },
  { keys: "F1", action: "help" },
  { keys: "Space, 1 - 4", action: "speed" },
  { keys: "WASD, arrows, wheel", action: "camera" },
];

/** Cells of a building's footprint (re-exported so panels need no second import). */
export { footprintCells };
