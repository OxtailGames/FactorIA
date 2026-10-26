// @ts-check
// Bot (pure): a player that grows a town by rules, once a day. It is the test helper of the game (later packages ask it for a
// town to test their features on: `growTown({ days: 40 })`) and the way the economy numbers were tuned: if the bot cannot
// grow a town from the start state in a year, the numbers are wrong.
//
// The rules, in priority order (the first one that applies and is affordable is built; at most `maxBuildsPerDay` a day):
//   1. the chain a town needs at all: a warehouse (its carriers move every good), a lumber camp and a sawmill (planks), three
//      houses, a fisher dock, a farm, a market, a bakery, a smokehouse;
//   2. growth: a house when fewer than 3 beds are free and nobody is hungry; a workplace when 3 villagers have no job
//      (a food producer first when food is short); a second warehouse when the stock is nearly full; a mill with 2 farms.
// It keeps `reserveDays` days of wages and upkeep in the bank. Nothing in here is random: the same map gives the same town.
import { Planner } from "./planner.js";
import { createGame } from "./state.js";

export class Bot {
  /**
   * @param {import("./state.js").GameState} state
   * @param {{ maxBuildsPerDay?: number, reserveDays?: number }} [options]
   */
  constructor(state, options = {}) {
    this.state = state;
    this.planner = new Planner(state);
    this.maxBuildsPerDay = options.maxBuildsPerDay ?? 2;
    this.reserveDays = options.reserveDays ?? 3;
    /** What it built: { day, type, x, y, rot }. */
    this.built = [];
    /** Types it could not place (no site on the map). */
    this.stuck = new Set();
    this.off = state.events.on("clock.day", () => this.act());
  }

  stop() {
    this.off();
  }

  count(type) {
    return this.state.list(type).length;
  }

  /** Coins the town keeps for the next days' wages and upkeep. */
  reserve() {
    const sim = this.state.sim;
    let upkeep = 0;
    for (const rt of sim.rt.values()) upkeep += this.state.data.buildings[rt.type].upkeep || 0;
    return Math.ceil((sim.people.employed() * sim.cfg.wagePerDay + upkeep) * this.reserveDays);
  }

  /** Food units on offer in the town (shelves and stock) and what the villagers eat in a day. */
  foodStatus() {
    const sim = this.state.sim;
    const goods = this.state.data.goods;
    let have = 0;
    for (const g of sim.foodGoods) {
      have += (this.state.economy.stock[g] || 0) * goods[g].nutrition;
      for (const rt of sim.rt.values()) have += (rt.shelf[g] || 0) * goods[g].nutrition;
    }
    const need = sim.people.villagers.size * sim.cfg.foodPerDay;
    return { have, need };
  }

  /** The types it wants to build now, most wanted first. */
  wants() {
    const state = this.state;
    const sim = state.sim;
    const sum = sim.summary();
    const n = (t) => this.count(t);
    const out = [];
    // the start planks (10) pay either the warehouse or the market: the warehouse first (nothing moves without carriers), the
    // sawmill then makes the planks of the market
    if (!n("warehouse")) out.push("warehouse");
    if (!n("lumber_camp")) out.push("lumber_camp");
    if (!n("sawmill")) out.push("sawmill");
    if (n("house") < 3) out.push("house");
    if (!n("fisher_dock")) out.push("fisher_dock");
    if (!n("farm")) out.push("farm");
    if (!n("market")) out.push("market");
    if (!n("bakery")) out.push("bakery");
    if (!n("smokehouse")) out.push("smokehouse");
    if (out.length) return out;
    const food = this.foodStatus();
    const free = sum.housing - sum.population;
    const short = sum.hungry > 0 || food.have < food.need * 2;
    const openJobs = sum.jobs - sum.employed;
    if (short && openJobs < 2) {
      // more food: fish first, grain while the bakery has no input, a mill once there are two farms
      if (n("fisher_dock") <= n("farm") + 1) out.push("fisher_dock");
      else out.push("farm");
      if (n("bakery") * 2 < n("farm")) out.push("bakery");
    }
    if (sum.unemployed >= 3 && sum.jobs - sum.employed < 2) out.push(...this.nextWorkplaces());
    if (n("warehouse") * 10 < sum.population) out.push("warehouse"); // carriers: one stock, many errands
    if (free <= (short ? 6 : 3)) out.push("house");
    const cap = sim.capacity();
    let held = 0;
    for (const g of state.data.goodIds) held = Math.max(held, state.economy.stock[g] || 0);
    if (held > cap * 0.8) out.push("warehouse");
    if (n("farm") >= 2 && !n("mill")) out.push("mill");
    return out;
  }

  /** The job buildings a town with people without work is short of, most useful first. */
  nextWorkplaces() {
    const n = (t) => this.count(t);
    const stock = this.state.economy.stock;
    const pop = this.state.sim.people.villagers.size;
    const out = [];
    if (n("warehouse") * 12 < pop) out.push("warehouse"); // carriers: one stock, many errands
    if (n("market") * 20 < pop) out.push("market");
    if (n("smokehouse") < n("fisher_dock")) out.push("smokehouse");
    if (n("bakery") < n("farm")) out.push("bakery");
    if (n("farm") >= 2 && n("mill") < n("farm") / 2) out.push("mill");
    if ((stock.wood || 0) < 40 && n("lumber_camp") < 3) out.push("lumber_camp");
    if ((stock.planks || 0) < 30 && n("sawmill") < n("lumber_camp")) out.push("sawmill");
    out.push(n("farm") <= n("fisher_dock") ? "farm" : "fisher_dock");
    return out;
  }

  /** One day's decisions: build what is wanted and affordable. Returns the types built. */
  act() {
    const state = this.state;
    const built = [];
    let reserve = this.reserve();
    for (const type of this.wants()) {
      if (built.length >= this.maxBuildsPerDay) break;
      if (this.stuck.has(type)) continue;
      const def = state.data.buildings[type];
      const afford = state.economy.canAfford(def.cost);
      const coins = state.economy.coins - (def.cost.coins || 0);
      if (!afford.ok && !("coins" in afford.missing)) {
        // waits for goods (planks from the sawmill): the next want may go ahead, but this one's coins stay in the bank
        reserve += def.cost.coins || 0;
        continue;
      }
      if (!afford.ok || coins < reserve) break; // saving up coins: do not skip to something cheaper
      const res = this.planner.build(type);
      if (res.ok) {
        built.push(type);
        const b = res.building;
        this.built.push({ day: state.clock.day, type, x: b.x, y: b.y, rot: b.rot });
      } else if (res.reason === "no_site") this.stuck.add(type);
    }
    return built;
  }
}

/**
 * Grow a town with the bot and report it.
 * @param {{ seed?: number, testMap?: boolean, days?: number, state?: import("./state.js").GameState, maxBuildsPerDay?: number }} [options]
 *   days = game days to run (a year is 40); state = continue an existing game instead of starting one
 */
export function growTown(options = {}) {
  const state = options.state || createGame({ seed: options.seed, testMap: options.testMap });
  const clock = state.clock;
  clock.setSpeed(0);
  const bot = new Bot(state, { maxBuildsPerDay: options.maxBuildsPerDay });
  const days = options.days ?? 40;
  const ticks = days * clock.ticksPerDay;
  /** @type {any[]} */
  const history = [];
  bot.act(); // day 0
  for (let i = 0; i < ticks; i++) {
    clock.tick(clock.step);
    if (clock.dayTick === 0) history.push(snapshot(state));
  }
  bot.stop();
  return { state, bot, history, summary: snapshot(state) };
}

/** A few numbers about the town, for reports and tests. */
export function snapshot(state) {
  const sum = state.sim.summary();
  const d = state.clock.date();
  return {
    year: d.year,
    season: d.season,
    day: d.day,
    population: sum.population,
    housing: sum.housing,
    employed: sum.employed,
    jobs: sum.jobs,
    hungry: sum.hungry,
    broke: sum.broke,
    coins: state.economy.coins,
    buildings: state.buildings.size,
    hash: state.hash(),
  };
}
