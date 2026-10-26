// @ts-check
// The save format (pure, no engine calls): a GameState <-> a plain JSON object. This file is the ONLY place that knows the layout of a
// save, and its version. The slots, the autosave and the cloud copies (save_store.js, cloud_sync.js) only move the object around.
//
//   const save = serializeGame(state);                 // -> { format: "tidewater.save", version: 2, ... }
//   const res = loadGame(JSON.parse(text), data);      // -> { ok: true, state, save } | { ok: false, error: SaveProblem }
//
// FORMAT VERSION 2 (README, "Saves and scenarios (P4)", says how to bump the version):
//   scenario   the id of the scenario the game belongs to ("sandbox" for none); progress  its goals: { goals: { id: day done }, won, wonDay, base }
//   map        width, height, seed, the terrain as run lengths [kind, count, kind, count, ...] (kind = index in data/terrain.json, cells
//              row by row) and the map hash. The save carries its own map, so a change of the map generator never breaks an old save.
//   clock      day, dayTick, speed, pending, ticks             economy  coins and stock
//   buildings  in the order the game keeps them; nextId. A building is { id, type, x, y, rot, w, h }; a run of roads laid in a line
//              (consecutive ids, neighbouring cells) is one array [firstId, x, y, dir, length]: dir 0 goes right, 1 goes down
//   sim        the town's life: runtime state of each building (rt), villagers (with a carrier's trip), walkers on the road, the
//              ledger, timers. A walker is saved where it stands, so a loaded game continues EXACTLY as the saved one would have:
//              the same state hash after any number of days (tests/save.test.js).
// VERSION 1 (the first commit of the format, fixtures tests/fixtures/*_v1.json) had no progress, one digit per terrain cell and
// every road as an object; MIGRATIONS[1] turns it into version 2.
// Fields a package adds (serializeGame's `extra`) are top-level and kept as they are; readSave does not look at fields it does not know.
// What is not saved: the undo and redo history (a loaded game starts with an empty one), the camera, the current tool.
import { createGame } from "./state.js";
import { didYouMean } from "./data.js";

export const FORMAT = "tidewater.save";
/** The version this file writes. Bump it when the layout changes and add the step to MIGRATIONS (README explains). */
export const VERSION = 2;

/**
 * @typedef {{ code: string, message: string, hint: string, pointer: string, detail?: any }} SaveProblem
 *   code: not_a_save | bad_json | unknown_format | future_version | too_old | invalid | map_mismatch | corrupt; pointer: JSON pointer into the save
 */

/** A problem found while reading a save (thrown inside this file, returned as { ok: false, error } to callers). */
class SaveError extends Error {
  /** @param {string} code @param {string} pointer @param {string} message @param {string} hint @param {any} [detail] */
  constructor(code, pointer, message, hint, detail) {
    super(message);
    this.problem = { code, message, hint, pointer, detail };
  }
}

const fail = (code, pointer, message, hint, detail) => {
  throw new SaveError(code, pointer, message, hint, detail);
};

// ---- writing --------------------------------------------------------------------------------------------------------------

const clone = (v) => JSON.parse(JSON.stringify(v));

/**
 * The save of a game state. Plain JSON data (numbers, strings, arrays, objects), nothing shared with the live game.
 * @param {import("./state.js").GameState} state
 * @param {Record<string, any>} [extra] more top-level fields (a package adds its own here, see the README)
 */
export function serializeGame(state, extra = {}) {
  const sim = state.sim;
  const clock = state.clock;
  const map = state.map;
  const save = {
    ...clone(extra),
    format: FORMAT,
    version: VERSION,
    scenario: extra.scenario || "sandbox",
    progress: extra.progress || emptyProgress(sim.ledger.produced),
    map: { width: map.width, height: map.height, seed: map.seed, terrain: runLengths(map.terrain), hash: map.hash() },
    clock: { day: clock.day, dayTick: clock.dayTick, speed: clock.speed, pending: clock.pending, ticks: clock.ticks },
    economy: { coins: state.economy.coins, stock: { ...state.economy.stock } },
    nextId: state.nextId,
    buildings: packBuildings([...state.buildings.values()]),
    sim: serializeSim(state),
  };
  return save;
}

/** The progress of a game with no goals (a sandbox, or a version 1 save brought up to date). */
function emptyProgress(produced) {
  return { goals: {}, won: false, wonDay: null, base: { ...produced } };
}

/** [kind, count, kind, count, ...] for a list of small numbers. */
function runLengths(cells) {
  const out = [];
  for (let i = 0; i < cells.length; i++) {
    if (out.length && out[out.length - 2] === cells[i]) out[out.length - 1]++;
    else out.push(cells[i], 1);
  }
  return out;
}

/** Roads laid in a line become one [firstId, x, y, dir, length]; everything else stays an object. The order of the list is kept. */
function packBuildings(list) {
  const out = [];
  let run = null; // the run being extended: [id, x, y, dir, length] (an element of `out`)
  for (const b of list) {
    if (b.type !== "road") {
      out.push({ id: b.id, type: b.type, x: b.x, y: b.y, rot: b.rot, w: b.w, h: b.h });
      run = null;
      continue;
    }
    if (run && b.id === run[0] + run[4]) {
      const dir = run[4] === 1 ? (b.x === run[1] + 1 && b.y === run[2] ? 0 : b.x === run[1] && b.y === run[2] + 1 ? 1 : -1) : run[3];
      const nextX = run[1] + (dir === 0 ? run[4] : 0);
      const nextY = run[2] + (dir === 1 ? run[4] : 0);
      if (dir >= 0 && b.x === nextX && b.y === nextY) {
        run[3] = dir;
        run[4]++;
        continue;
      }
    }
    run = [b.id, b.x, b.y, 0, 1];
    out.push(run);
  }
  return out;
}

function serializeSim(state) {
  const sim = state.sim;
  const people = sim.people;
  return {
    ticks: sim.ticks,
    broke: sim.broke,
    ledger: clone(sim.ledger),
    logistics: { timer: sim.logistics.timer, errands: sim.logistics.errands },
    walkerStats: { rerouted: sim.walkers.rerouted, gaveUp: sim.walkers.gaveUp },
    people: {
      nextId: people.nextId,
      lostCount: people.lostCount,
      dirty: people.dirty,
      // the job list is stale when the roads changed after it was made (it is made again on the next step)
      roadsStale: people.seenRoads !== sim.net.version,
    },
    // in the order the game keeps them: the simulation walks these lists in order, so the order is part of the state
    rt: [...sim.rt.values()].map((rt) => {
      const { id, type, present, ...rest } = rt;
      void type;
      return { id, present, ...clone(rest) };
    }),
    villagers: [...people.villagers.values()].map((v) => clone(v)),
    walkers: [...sim.walkers.list.values()].map((w) => ({ ...clone(w), stale: w.version !== sim.net.version })),
  };
}

// ---- reading --------------------------------------------------------------------------------------------------------------

/**
 * Migration steps: MIGRATIONS[n] turns a save of version n into version n + 1. Empty while there is only version 1.
 * @type {Record<number, (save: any) => any>}
 */
export const MIGRATIONS = {
  // 1 -> 2: scenario progress (a version 1 game had no goals), terrain as run lengths, roads packed in runs
  1(save) {
    if (!save.map || typeof save.map.terrain !== "string") fail("invalid", "/map/terrain", "a version 1 save keeps the terrain as one text of digits", "the file is damaged");
    const cells = Array.from(save.map.terrain, (ch) => ch.charCodeAt(0) - 48);
    if (cells.some((k) => !(k >= 0 && k <= 9))) fail("invalid", "/map/terrain", "the terrain must be digits", "the file is damaged");
    const produced = save.sim && save.sim.ledger && save.sim.ledger.produced ? save.sim.ledger.produced : {};
    return {
      ...save,
      version: 2,
      scenario: typeof save.scenario === "string" ? save.scenario : "sandbox",
      progress: emptyProgress(produced),
      map: { ...save.map, terrain: runLengths(cells) },
      buildings: packBuildings(Array.isArray(save.buildings) ? save.buildings.filter((b) => b && typeof b === "object") : []),
    };
  },
};

/**
 * Parse (when given text), check the version, migrate to the current version and check the shape. Never throws.
 * @param {any} input the text of a save, or its parsed object
 * @returns {{ ok: true, save: any, migratedFrom: number | null } | { ok: false, error: SaveProblem }}
 */
export function readSave(input) {
  try {
    let save = input;
    if (typeof input === "string") {
      try {
        save = JSON.parse(input);
      } catch (e) {
        fail("bad_json", "", `the save is not valid JSON (${e && e.message})`, "the file is damaged; load another slot or the autosave");
      }
    }
    if (save === null || typeof save !== "object" || Array.isArray(save)) fail("not_a_save", "", "the save is not a JSON object", "a save is an object with \"format\" and \"version\"");
    if (save.format !== FORMAT) fail("unknown_format", "/format", `this is not a Tidewater Market save (format ${JSON.stringify(save.format)})`, `a save has "format": "${FORMAT}"`);
    if (!Number.isInteger(save.version) || save.version < 1) fail("invalid", "/version", `the version must be a whole number from 1 (got ${JSON.stringify(save.version)})`, "the file is damaged");
    if (save.version > VERSION) {
      fail("future_version", "/version", `this save is version ${save.version}, made by a newer game; this game reads up to version ${VERSION}`, "update the game to open it");
    }
    let migratedFrom = null;
    while (save.version < VERSION) {
      const step = MIGRATIONS[save.version];
      if (!step) fail("too_old", "/version", `no way to bring a version ${save.version} save up to version ${VERSION}`, "this save is too old for this game");
      migratedFrom = migratedFrom ?? save.version;
      save = step(clone(save));
    }
    checkShape(save);
    return { ok: true, save, migratedFrom };
  } catch (e) {
    return { ok: false, error: problemOf(e) };
  }
}

function problemOf(e) {
  if (e instanceof SaveError) return e.problem;
  return { code: "corrupt", pointer: "", message: `the save could not be read (${e && e.message})`, hint: "the file is damaged; load another slot or the autosave" };
}

const isObject = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
const isInt = (v) => Number.isInteger(v);
const isNum = (v) => typeof v === "number" && Number.isFinite(v);
const sumOfCounts = (runs) => runs.reduce((n, v, i) => (i % 2 ? n + v : n), 0);

/** Throw a SaveError for the first thing that is not shaped like a save (types and ranges; references are checked while restoring). */
function checkShape(s) {
  const need = (ok, pointer, message, hint = "the file is damaged; load another slot or the autosave") => {
    if (!ok) fail("invalid", pointer, message, hint);
  };
  need(typeof s.scenario === "string", "/scenario", "scenario must be a text");
  need(isObject(s.map) && isInt(s.map.width) && isInt(s.map.height) && s.map.width >= 4 && s.map.height >= 4 && s.map.width <= 256 && s.map.height <= 256, "/map", "map needs a width and a height (whole numbers from 4 to 256)");
  need(Array.isArray(s.map.terrain) && s.map.terrain.length % 2 === 0 && s.map.terrain.every((n) => isInt(n) && n >= 0), "/map/terrain", "terrain must be a list of [kind, count] pairs");
  need(sumOfCounts(s.map.terrain) === s.map.width * s.map.height, "/map/terrain", `the terrain runs must add up to ${s.map.width * s.map.height} cells (width x height)`);
  need(isObject(s.progress) && isObject(s.progress.goals) && isObject(s.progress.base), "/progress", "progress needs goals and base");
  need(isObject(s.clock) && ["day", "dayTick", "speed", "ticks"].every((k) => isInt(s.clock[k]) && s.clock[k] >= 0) && isNum(s.clock.pending), "/clock", "clock needs day, dayTick, speed, ticks (whole numbers) and pending (a number)");
  need(isObject(s.economy) && isNum(s.economy.coins) && isObject(s.economy.stock), "/economy", "economy needs coins and stock");
  for (const [g, n] of Object.entries(s.economy.stock)) need(isNum(n) && n >= 0, `/economy/stock/${g}`, `stock of ${g} must be a number, 0 or more`);
  need(isInt(s.nextId) && s.nextId >= 1, "/nextId", "nextId must be a whole number from 1");
  need(Array.isArray(s.buildings), "/buildings", "buildings must be a list");
  s.buildings.forEach((b, i) => {
    if (Array.isArray(b)) need(b.length === 5 && b.every(isInt) && b[0] >= 1 && (b[3] === 0 || b[3] === 1) && b[4] >= 1, `/buildings/${i}`, "a run of roads is [firstId, x, y, dir, length] (dir 0 or 1, length 1 or more)");
    else need(isObject(b) && isInt(b.id) && b.id >= 1 && typeof b.type === "string" && isInt(b.x) && isInt(b.y) && isInt(b.rot) && isInt(b.w) && isInt(b.h), `/buildings/${i}`, "a building needs id, type, x, y, rot, w, h");
  });
  need(isObject(s.sim) && isObject(s.sim.ledger) && Array.isArray(s.sim.rt) && Array.isArray(s.sim.villagers) && Array.isArray(s.sim.walkers) && isObject(s.sim.people) && isObject(s.sim.logistics), "/sim", "sim needs ledger, rt, villagers, walkers, people and logistics");
}

// ---- restoring --------------------------------------------------------------------------------------------------------------

/**
 * Build a game state from a save (read it with readSave first, or use loadGame). The live game is never touched: a save that fails to
 * restore leaves nothing behind.
 * @param {any} save a current-version save that passed readSave
 * @param {ReturnType<typeof import("./data.js").getData>} data the data tables (a scenario may hand its own copy)
 * @returns {{ ok: true, state: import("./state.js").GameState } | { ok: false, error: SaveProblem }}
 */
export function restoreGame(save, data) {
  try {
    return { ok: true, state: restore(save, data) };
  } catch (e) {
    return { ok: false, error: problemOf(e) };
  }
}

/** readSave + restoreGame in one call. @returns {{ ok: true, state: import("./state.js").GameState, save: any, migratedFrom: number | null } | { ok: false, error: SaveProblem }} */
export function loadGame(input, data) {
  const read = readSave(input);
  if (!read.ok) return read;
  const res = restoreGame(read.save, data);
  return res.ok ? { ok: true, state: res.state, save: read.save, migratedFrom: read.migratedFrom } : res;
}

function restore(s, data) {
  // 1. the map. The runs become rows of terrain characters, which createGame turns into a map like any other.
  const ids = data.terrainIds;
  const chars = ids.map((id) => data.terrain[id].char);
  let text = "";
  for (let i = 0; i < s.map.terrain.length; i += 2) {
    const kind = s.map.terrain[i];
    if (kind >= ids.length) fail("invalid", `/map/terrain/${i}`, `terrain kind ${kind}, but there are only ${ids.length} kinds of terrain (${ids.join(", ")})`, "the file is damaged");
    text += chars[kind].repeat(s.map.terrain[i + 1]);
  }
  const rows = [];
  for (let r = 0; r < s.map.height; r++) rows.push(text.slice(r * s.map.width, (r + 1) * s.map.width));
  const state = createGame({ data, rows });
  state.map.seed = isInt(s.map.seed) ? s.map.seed : 0;
  if (typeof s.map.hash === "string" && state.map.hash() !== s.map.hash) {
    fail("map_mismatch", "/map/hash", `the map does not match its hash (saved ${s.map.hash}, read ${state.map.hash()})`, "the file is damaged");
  }

  // 2. clock and money (set directly: loading is not a game event)
  const clock = state.clock;
  clock.day = s.clock.day;
  clock.dayTick = s.clock.dayTick;
  clock.speed = Math.min(s.clock.speed, 3);
  clock.pending = s.clock.pending;
  clock.ticks = s.clock.ticks;
  if (clock.dayTick >= clock.ticksPerDay) fail("invalid", "/clock/dayTick", `dayTick ${clock.dayTick} is past the end of a day (${clock.ticksPerDay} steps)`, "the file is damaged");
  state.economy.coins = s.economy.coins;
  for (const [g, n] of Object.entries(s.economy.stock)) {
    if (!data.goods[g]) fail("invalid", `/economy/stock/${g}`, `unknown good '${g}'`, `the goods are: ${data.goodIds.join(", ")}`);
    state.economy.stock[g] = n;
  }

  // 3. the buildings, in the order the game kept them. restoreBuilding fills the map and tells the simulation (it makes the rt entries).
  let highest = 0;
  const put = (b, i) => {
    const def = data.buildings[b.type];
    if (!def) {
      const near = didYouMean(b.type, data.buildingIds);
      fail("invalid", `/buildings/${i}/type`, `unknown building '${b.type}'${near ? `; did you mean '${near}'?` : ""}`, `the buildings are: ${data.buildingIds.join(", ")}`);
    }
    if (state.buildings.has(b.id)) fail("invalid", `/buildings/${i}`, `two buildings have the id ${b.id}`, "the file is damaged");
    if (b.x < 0 || b.y < 0 || b.x + b.w > state.map.width || b.y + b.h > state.map.height) fail("invalid", `/buildings/${i}`, `${b.type} ${b.id} stands outside the map`, "the file is damaged");
    for (let r = b.y; r < b.y + b.h; r++) {
      for (let c = b.x; c < b.x + b.w; c++) {
        if (state.map.occupantAt(c, r)) fail("invalid", `/buildings/${i}`, `${b.type} ${b.id} overlaps building ${state.map.occupantAt(c, r)} at (${c}, ${r})`, "the file is damaged");
      }
    }
    highest = Math.max(highest, b.id);
    state.restoreBuilding({ id: b.id, type: b.type, x: b.x, y: b.y, rot: b.rot, w: b.w, h: b.h }, "load");
  };
  s.buildings.forEach((b, i) => {
    if (!Array.isArray(b)) return put(b, i);
    const [id, x, y, dir, length] = b; // a run of roads
    for (let k = 0; k < length; k++) put({ id: id + k, type: "road", x: x + (dir === 0 ? k : 0), y: y + (dir === 1 ? k : 0), rot: 0, w: 1, h: 1 }, i);
  });
  state.nextId = Math.max(s.nextId, highest + 1);

  // 4. the town's life
  restoreSim(state, s.sim);
  return state;
}

function restoreSim(state, s) {
  const sim = state.sim;
  const people = sim.people;
  const ids = new Set(state.buildings.keys());
  const ref = (id, pointer, what) => {
    if (id !== 0 && !ids.has(id)) fail("invalid", pointer, `${what} refers to building ${id}, which is not in the save`, "the file is damaged");
  };

  // the rt entries in the saved order (the simulation walks them in order)
  const fresh = sim.rt;
  sim.rt = new Map();
  s.rt.forEach((saved, i) => {
    const rt = fresh.get(saved.id);
    if (!rt) fail("invalid", `/sim/rt/${i}/id`, `runtime state for building ${saved.id}, which is not a building with state`, "the file is damaged");
    Object.assign(rt, saved);
    sim.rt.set(rt.id, rt);
  });
  for (const [id, rt] of fresh) if (!sim.rt.has(id)) sim.rt.set(id, rt); // a building the save has no state for starts fresh

  people.villagers = new Map();
  s.villagers.forEach((v, i) => {
    if (!isInt(v.id) || people.villagers.has(v.id)) fail("invalid", `/sim/villagers/${i}/id`, `villager id ${JSON.stringify(v.id)} is missing or used twice`, "the file is damaged");
    ref(v.home, `/sim/villagers/${i}/home`, `villager ${v.id}'s home`);
    ref(v.job, `/sim/villagers/${i}/job`, `villager ${v.id}'s job`);
    ref(v.at, `/sim/villagers/${i}/at`, `villager ${v.id}`);
    people.villagers.set(v.id, v);
  });
  people.nextId = s.people.nextId;
  people.lostCount = s.people.lostCount;
  people.dirty = !!s.people.dirty;
  people.seenRoads = s.people.roadsStale ? -1 : sim.net.version;
  for (const rt of sim.rt.values()) for (const v of rt.staff || []) if (!people.villagers.has(v)) fail("invalid", `/sim/rt`, `building ${rt.id} has a staff member (${v}) who is not a villager`, "the file is damaged");

  sim.walkers.list = new Map();
  s.walkers.forEach((w, i) => {
    if (!people.villagers.has(w.id)) fail("invalid", `/sim/walkers/${i}/id`, `walker ${w.id} is not a villager`, "the file is damaged");
    if (!Array.isArray(w.path) || !w.path.length || !w.path.every((n) => isInt(n) && n >= 0 && n < state.map.width * state.map.height)) fail("invalid", `/sim/walkers/${i}/path`, `walker ${w.id} has no valid path`, "the file is damaged");
    const { stale, ...walker } = w;
    walker.version = stale ? sim.net.version - 1 : sim.net.version;
    sim.walkers.list.set(walker.id, walker);
  });
  sim.walkers.rerouted = s.walkerStats ? s.walkerStats.rerouted : 0;
  sim.walkers.gaveUp = s.walkerStats ? s.walkerStats.gaveUp : 0;

  sim.ticks = s.ticks;
  sim.broke = !!s.broke;
  sim.ledger = s.ledger;
  sim.logistics.timer = s.logistics.timer;
  sim.logistics.errands = s.logistics.errands;
  sim.seasonId = state.clock.date().season;
  sim.season = state.data.seasons[sim.seasonId];
}
