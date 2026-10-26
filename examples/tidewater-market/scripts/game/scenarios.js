// @ts-check
// Scenarios: a map, a start state and goals (data/scenarios.json), and the tracker that watches the goals while the town grows.
//
//   scenarioIds()                         ids in menu order: first_harbour, river_mills, winter_trade, sandbox
//   newScenarioGame(id, data)             { state, def } a fresh game of the scenario (its own map, money, goods and day)
//   new GoalTracker(state, id, def, saved?)   .attach() listens to the clock; .progress() lists the goals with their value;
//                                         "goal.done" {id, goal, day} and "scenario.won" {id, day} come on state.events
//
// Goal kinds (a scenario lists 2 to 4; the sandbox none): population (villagers at least target), coins (coins at least target),
// produced_in_season (units of `good` made within ONE season at least target, counted from the start of the season: the count
// starts again at each new season). A goal done stays done. The scenario is won when all its goals are done.
import scenariosJson from "../../data/scenarios.json";
import { createGame } from "./state.js";
import { didYouMean, rawTables } from "./data.js";

export const GOAL_KINDS = ["population", "coins", "produced_in_season"];
/** A scenario with no goals: the sandbox. */
export const SANDBOX = "sandbox";

/** The scenario table (a function so a test may read it without importing the JSON). */
export function scenarioTable() {
  return scenariosJson.scenarios;
}

/** Scenario ids in the order of the menu (the "order" field). */
export function scenarioIds() {
  const table = scenarioTable();
  return Object.keys(table).sort((a, b) => table[a].order - table[b].order);
}

/**
 * Check data/scenarios.json against the other tables. Returns the problems (empty = fine); each has a pointer, a message and a hint.
 * @param {any} json the file's content
 * @param {ReturnType<typeof import("./data.js").getData>} data
 * @returns {Array<{ pointer: string, message: string, hint: string }>}
 */
export function validateScenarios(json, data) {
  const out = [];
  const add = (pointer, message, hint) => out.push({ pointer, message, hint });
  const isObject = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
  if (!isObject(json) || json.format !== "tidewater.scenarios/1") add("/format", `format must be "tidewater.scenarios/1"`, "data/scenarios.json starts with this format tag");
  const table = isObject(json) && isObject(json.scenarios) ? json.scenarios : {};
  if (!table[SANDBOX]) add("/scenarios/sandbox", "there is no sandbox scenario", `add "sandbox" with an empty goals list`);
  const orders = new Set();
  const days = data.economy.calendar.seasons.length * data.economy.calendar.daysPerSeason;
  for (const [id, sc] of Object.entries(table)) {
    const p = `/scenarios/${id}`;
    if (!/^[a-z][a-z0-9_]*$/.test(id)) add(p, `the id '${id}' must be lower case letters, digits and underscores`, "other packages key their data by these ids");
    if (!isObject(sc)) {
      add(p, "a scenario is an object", "give it order, map, start and goals");
      continue;
    }
    if (!Number.isInteger(sc.order) || orders.has(sc.order)) add(`${p}/order`, `order must be a whole number nobody else uses (got ${JSON.stringify(sc.order)})`, "the menu lists scenarios by it");
    orders.add(sc.order);
    for (const key of [`scenario.${id}.name`, `scenario.${id}.blurb`]) {
      if (typeof key.split(".").reduce((o, k) => (o ? o[k] : undefined), /** @type {any} */ (rawTables.locale)) !== "string") add(`${p}`, `the locale string '${key}' is missing`, "add it to locales/en.json");
    }
    if (!isObject(sc.map) || (sc.map.seed !== undefined && !Number.isInteger(sc.map.seed))) add(`${p}/map`, "map needs a whole-number seed (and may override the settings of data/map.json)", `e.g. "map": { "seed": 20261026 }`);
    else {
      for (const key of Object.keys(sc.map)) if (key !== "seed" && !(key in data.map)) add(`${p}/map/${key}`, `'${key}' is not a map setting`, `the settings are: ${Object.keys(data.map).join(", ")}${didYouMean(key, Object.keys(data.map)) ? `; did you mean '${didYouMean(key, Object.keys(data.map))}'?` : ""}`);
    }
    const start = isObject(sc.start) ? sc.start : {};
    if (start.coins !== undefined && !(Number.isFinite(start.coins) && start.coins >= 0)) add(`${p}/start/coins`, "coins must be a number, 0 or more", "money the town starts with");
    for (const [g, n] of Object.entries(start.stock || {})) {
      if (!data.goods[g]) add(`${p}/start/stock/${g}`, `unknown good '${g}'`, `the goods are: ${data.goodIds.join(", ")}`);
      else if (!(Number.isFinite(n) && n >= 0)) add(`${p}/start/stock/${g}`, "an amount is a number, 0 or more", "units in stock at the start");
    }
    if (start.day !== undefined && !(Number.isInteger(start.day) && start.day >= 0 && start.day < days)) add(`${p}/start/day`, `day must be a whole number from 0 to ${days - 1} (the first year)`, "the day the game starts on");
    const goals = Array.isArray(sc.goals) ? sc.goals : null;
    if (!goals) add(`${p}/goals`, "goals must be a list", "an empty list is a sandbox");
    else {
      if (id !== SANDBOX && (goals.length < 2 || goals.length > 4)) add(`${p}/goals`, `a scenario has 2 to 4 goals (this one has ${goals.length})`, "the sandbox is the only one without goals");
      if (id === SANDBOX && goals.length) add(`${p}/goals`, "the sandbox has no goals", "leave the list empty");
      const seen = new Set();
      goals.forEach((g, i) => {
        const gp = `${p}/goals/${i}`;
        if (typeof g.id !== "string" || seen.has(g.id)) add(`${gp}/id`, `a goal needs an id nobody else in the scenario uses (got ${JSON.stringify(g.id)})`, "the save stores progress by it");
        seen.add(g.id);
        if (!GOAL_KINDS.includes(g.kind)) add(`${gp}/kind`, `unknown goal kind '${g.kind}'`, `the kinds are: ${GOAL_KINDS.join(", ")}${didYouMean(String(g.kind), GOAL_KINDS) ? `; did you mean '${didYouMean(String(g.kind), GOAL_KINDS)}'?` : ""}`);
        if (!(Number.isFinite(g.target) && g.target > 0)) add(`${gp}/target`, "target must be a number above 0", "the amount to reach");
        if (g.kind === "produced_in_season" && !data.goods[g.good]) add(`${gp}/good`, `unknown good '${g.good}'`, `the goods are: ${data.goodIds.join(", ")}`);
      });
    }
  }
  return out;
}

/**
 * A fresh game of a scenario. The scenario's map settings and start state replace the defaults of the data tables for this game only.
 * @param {string} id
 * @param {ReturnType<typeof import("./data.js").getData>} data
 */
export function newScenarioGame(id, data) {
  const def = scenarioTable()[id];
  if (!def) throw new Error(`unknown scenario '${id}'; the scenarios are: ${scenarioIds().join(", ")}`);
  const { seed, ...settings } = def.map;
  const start = def.start || {};
  const scenarioData = {
    ...data,
    map: { ...data.map, ...settings },
    economy: {
      ...data.economy,
      start: { coins: start.coins ?? data.economy.start.coins, stock: { ...data.economy.start.stock, ...(start.stock || {}) } },
    },
  };
  const state = createGame({ data: scenarioData, seed: seed ?? data.map.defaultSeed });
  if (start.day) state.clock.setDay(start.day);
  state.sim.seasonId = state.clock.date().season;
  state.sim.season = state.data.seasons[state.sim.seasonId];
  return { state, def };
}

/**
 * Watches the goals of one scenario. It only READS the game (nothing it does changes the simulation or the state hash).
 * Progress is saved with the game: { goals: { <goal id>: <day it was done> }, won, wonDay, base: { <good>: produced at the start of the season } }.
 */
export class GoalTracker {
  /**
   * @param {import("./state.js").GameState} state
   * @param {string} id scenario id
   * @param {any} [def] the scenario definition (default: from the table)
   * @param {any} [saved] progress of a loaded game
   */
  constructor(state, id, def, saved) {
    this.state = state;
    this.id = id;
    this.def = def || scenarioTable()[id] || { goals: [] };
    this.goals = this.def.goals || [];
    this.done = { ...(saved && saved.goals) };
    this.won = !!(saved && saved.won);
    this.wonDay = saved && Number.isInteger(saved.wonDay) ? saved.wonDay : null;
    this.base = saved && saved.base ? { ...saved.base } : { ...state.sim.ledger.produced };
    /** @type {Array<() => void>} */
    this.off = [];
  }

  attach() {
    const ev = this.state.events;
    this.off.push(
      ev.on("clock.day", () => this.check()),
      // the new season's count starts from what has been made so far
      ev.on("clock.season", () => (this.base = { ...this.state.sim.ledger.produced })),
    );
    return this;
  }

  detach() {
    for (const off of this.off) off();
    this.off = [];
  }

  /** The current value of a goal (what the panel shows against the target). */
  value(goal) {
    const s = this.state;
    switch (goal.kind) {
      case "population":
        return s.sim.people.villagers.size;
      case "coins":
        return s.economy.coins;
      case "produced_in_season":
        return Math.max(0, Math.floor((s.sim.ledger.produced[goal.good] || 0) - (this.base[goal.good] || 0)));
      default:
        return 0;
    }
  }

  /** Mark the goals that are reached; announce each once, and the win. Returns the ids newly done. */
  check() {
    const newly = [];
    for (const goal of this.goals) {
      if (goal.id in this.done) continue;
      if (this.value(goal) >= goal.target) {
        this.done[goal.id] = this.state.clock.day;
        newly.push(goal.id);
        this.state.events.emit("goal.done", { scenario: this.id, id: goal.id, goal, day: this.state.clock.day });
      }
    }
    if (this.goals.length && !this.won && this.goals.every((g) => g.id in this.done)) {
      this.won = true;
      this.wonDay = this.state.clock.day;
      this.state.events.emit("scenario.won", { scenario: this.id, day: this.wonDay });
    }
    return newly;
  }

  /** For the goal panel: each goal with its value, target and whether it is done. */
  progress() {
    return this.goals.map((goal) => ({ goal, value: this.value(goal), done: goal.id in this.done }));
  }

  /** Number of goals done and the total. */
  counts() {
    return { done: this.goals.filter((g) => g.id in this.done).length, total: this.goals.length };
  }

  /** The progress as saved (savegame.js "progress"). */
  toSave() {
    return { goals: { ...this.done }, won: this.won, wonDay: this.wonDay, base: { ...this.base } };
  }

  /** Extra top-level fields of a save (serializeGame's `extra`). */
  saveFields() {
    return { scenario: this.id, progress: this.toSave() };
  }

  /** Extra fields of the slot meta (the slot screen shows "2 of 3 goals"). */
  metaFields() {
    const { done, total } = this.counts();
    return { goalsDone: done, goalsTotal: total, won: this.won };
  }
}
