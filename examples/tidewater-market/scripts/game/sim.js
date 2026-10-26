// @ts-check
// The simulation of the town (pure, no engine calls): villagers live in houses, walk the roads to work and to the market,
// producers turn goods into goods, carriers move goods between them and the warehouse, the market sells food, and the town
// pays wages and upkeep. Everything advances in fixed steps on the clock's "clock.tick" (scripts/game/clock.js), so x1, x2 and
// x4 give the same town and the same inputs always give the same state (there is no random number in here).
//
// The pieces: roadnet.js (roads, distance fields), walkers.js (movement), people.js (villagers: homes, jobs, hunger, growth,
// the daily schedule), logistics.js (carriers) and this file (the buildings' runtime state, production, money). The README
// section "Economy and simulation" lists every number in data/economy.json `sim` and what it does.
//
// Per-building runtime state (`sim.rt.get(buildingId)`, none for roads):
//   staff     villager ids with a job here        present  how many of them are inside right now
//   inbox     goods waiting for the next cycle    outbox   goods made, waiting for a carrier
//   shelf     (market) goods for sale             residents (house) villager ids
//   cur       recipe id of the running cycle, progress its game seconds so far, stall why nothing runs ("" = running)
import { RoadNet } from "./roadnet.js";
import { Walkers } from "./walkers.js";
import { People } from "./people.js";
import { Logistics } from "./logistics.js";

/** Why a producer is not producing. "" = it is. */
export const STALLS = ["no_staff", "closed", "no_input", "output_full", "season"];

export class Simulation {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.data = state.data;
    this.cfg = state.data.sim;
    /** @type {Map<number, any>} building id -> runtime state */
    this.rt = new Map();
    /** Counts every building placed or removed (caches of "which warehouse is nearest" depend on it). */
    this.layoutVersion = 0;
    this.net = new RoadNet(state);
    this.foodGoods = state.data.goodIds.filter((g) => (state.data.goods[g].nutrition || 0) > 0);
    this.ledger = this.newLedger();
    /** The town could not pay wages and upkeep at the last payday: buildings run at `unpaidEfficiency` until it can. */
    this.broke = false;
    this.season = state.data.seasons[state.clock.date().season];
    this.seasonId = state.clock.date().season;
    this.walkers = new Walkers(this.net, state, {
      onArrive: (w) => this.people.arrived(w),
      onLost: (w, why) => this.people.lost(w, why),
    });
    this.people = new People(this);
    this.logistics = new Logistics(this);
    /** Fixed steps simulated so far. */
    this.ticks = 0;
    const ev = state.events;
    ev.on("building.placed", (e) => this.placed(e.building));
    ev.on("building.removed", (e) => this.removed(e.building));
    ev.on("clock.day", () => this.payday());
    ev.on("clock.tick", (e) => this.step(e.seconds));
    for (const b of state.buildings.values()) this.placed(b);
  }

  newLedger() {
    const zero = () => Object.fromEntries(this.data.goodIds.map((g) => [g, 0]));
    return { produced: zero(), consumed: zero(), eaten: zero(), lost: zero(), sales: 0, wages: 0, upkeep: 0, wagesShort: 0 };
  }

  // ---- the buildings' state ------------------------------------------------------------------------------------------

  placed(b) {
    const def = this.data.buildings[b.type];
    if (def.kind === "road") return;
    this.layoutVersion++;
    this.rt.set(b.id, { id: b.id, type: b.type, staff: [], present: 0, inbox: {}, outbox: {}, inRes: {}, outRes: {}, shelf: {}, shelfRes: {}, residents: [], timer: 0, arrivals: 0, cur: null, progress: 0, stall: "no_staff", cycles: 0 });
    this.people.dirty = true;
  }

  removed(b) {
    const rt = this.rt.get(b.id);
    if (!rt) return;
    this.layoutVersion++;
    this.logistics.buildingRemoved(b);
    this.people.buildingRemoved(b, rt);
    for (const bag of [rt.inbox, rt.outbox, rt.shelf]) for (const [g, n] of Object.entries(bag)) this.ledger.lost[g] += n;
    this.rt.delete(b.id);
    this.people.dirty = true;
  }

  /** The nearest-first list of buildings of a type, in id order. */
  ofType(type) {
    const out = [];
    for (const rt of this.rt.values()) if (rt.type === type) out.push(rt);
    return out.sort((a, b) => a.id - b.id);
  }

  /** What a unit of a good sells for now: the base price times this season's demand. P3 puts its price model here. */
  priceOf(good) {
    const g = this.data.goods[good];
    return Math.max(1, Math.round(g.basePrice * ((this.season.demand && this.season.demand[good]) ?? 1)));
  }

  /** How much of each good the warehouses (and the base storage) can hold. */
  capacity() {
    let cap = this.cfg.baseStorage;
    for (const rt of this.rt.values()) cap += this.data.buildings[rt.type].storage || 0;
    return cap;
  }

  // ---- one fixed step --------------------------------------------------------------------------------------------------

  step(dt) {
    this.ticks++;
    const clock = this.state.clock;
    const seasonId = clock.date().season; // read from the clock, not from the event: clock.setDay moves the date without one
    if (seasonId !== this.seasonId) {
      this.seasonId = seasonId;
      this.season = this.data.seasons[seasonId];
    }
    const f = clock.dayFraction();
    this.people.step(dt, f);
    this.logistics.step(dt, f);
    this.walkers.step(dt);
    this.produce(dt);
  }

  // ---- production --------------------------------------------------------------------------------------------------------

  /** Goods per cycle of the inbox of a producer: inboxCycles cycles of the biggest recipe. */
  inboxCap(rt, good) {
    let most = 0;
    for (const id of this.data.buildings[rt.type].recipes || []) most = Math.max(most, this.data.recipes[id].inputs[good] || 0);
    return most * this.cfg.inboxCycles;
  }

  outboxCap(rt, good) {
    let most = 0;
    for (const id of this.data.buildings[rt.type].recipes || []) most = Math.max(most, this.data.recipes[id].outputs[good] || 0);
    return most * this.cfg.outboxCycles;
  }

  /** The speed multiplier of a recipe this season (0 = it waits). */
  seasonRate(recipeId) {
    const m = this.season.production && this.season.production[recipeId];
    return m === undefined ? 1 : m;
  }

  produce(dt) {
    const rate = this.cfg.productionRate * (this.broke ? this.cfg.unpaidEfficiency : 1);
    for (const rt of this.rt.values()) {
      const def = this.data.buildings[rt.type];
      if (!def.recipes || !def.recipes.length) continue;
      if (rt.present === 0) {
        rt.stall = rt.staff.length ? "closed" : "no_staff";
        continue;
      }
      if (!rt.cur) this.startCycle(rt, def);
      if (!rt.cur) continue;
      const recipe = this.data.recipes[rt.cur];
      const season = this.seasonRate(recipe.id);
      if (season <= 0) {
        rt.stall = "season";
        continue;
      }
      rt.stall = "";
      rt.progress += dt * (rt.present / def.workers) * season * rate;
      if (rt.progress >= recipe.seconds) {
        for (const [g, n] of Object.entries(recipe.outputs)) {
          rt.outbox[g] = (rt.outbox[g] || 0) + n;
          this.ledger.produced[g] += n;
        }
        rt.cycles++;
        rt.cur = null;
        rt.progress = 0;
        this.state.events.emit("production.done", { building: rt.id, recipe: recipe.id, outputs: { ...recipe.outputs } });
      }
    }
  }

  /** Begin the first recipe whose inputs are in the inbox and whose outputs fit in the outbox (this season). */
  startCycle(rt, def) {
    let why = "no_input";
    for (const id of def.recipes) {
      const recipe = this.data.recipes[id];
      if (this.seasonRate(id) <= 0) {
        why = "season";
        continue;
      }
      if (!Object.entries(recipe.inputs).every(([g, n]) => (rt.inbox[g] || 0) >= n)) continue;
      if (!Object.entries(recipe.outputs).every(([g, n]) => (rt.outbox[g] || 0) + n <= this.outboxCap(rt, g))) {
        why = "output_full";
        continue;
      }
      for (const [g, n] of Object.entries(recipe.inputs)) {
        rt.inbox[g] -= n;
        this.ledger.consumed[g] += n;
      }
      rt.cur = id;
      rt.progress = 0;
      rt.stall = "";
      return;
    }
    rt.stall = why;
  }

  // ---- money -------------------------------------------------------------------------------------------------------------

  /** At the start of every day: pay the wages of the employed and the upkeep of the buildings, as far as the coins go. */
  payday() {
    const wages = this.people.employed() * this.cfg.wagePerDay;
    let upkeep = 0;
    for (const rt of this.rt.values()) upkeep += this.data.buildings[rt.type].upkeep || 0;
    const economy = this.state.economy;
    const payWages = Math.min(wages, economy.coins);
    if (payWages > 0) economy.apply({ coins: -payWages }, "wages");
    const payUpkeep = Math.min(upkeep, economy.coins);
    if (payUpkeep > 0) economy.apply({ coins: -payUpkeep }, "upkeep");
    this.ledger.wages += payWages;
    this.ledger.upkeep += payUpkeep;
    this.ledger.wagesShort += wages + upkeep - payWages - payUpkeep;
    this.broke = payWages + payUpkeep < wages + upkeep;
    this.state.events.emit("payday", { wages: payWages, upkeep: payUpkeep, owed: wages + upkeep, broke: this.broke });
  }

  /** Sell goods from a market shelf: coins go to the town. Called by people.js when a villager shops. */
  sale(coins, detail) {
    this.ledger.sales += coins;
    this.state.economy.apply({ coins }, "sales");
    this.state.events.emit("market.sale", detail);
  }

  // ---- reading the state --------------------------------------------------------------------------------------------------

  /** Units of a good anywhere in the town: stock, buildings, the market shelves and carried cargo. */
  inventory(good) {
    let n = this.state.economy.stock[good] || 0;
    for (const rt of this.rt.values()) n += (rt.inbox[good] || 0) + (rt.outbox[good] || 0) + (rt.shelf[good] || 0);
    n += this.logistics.carried(good);
    return n;
  }

  /** A short account of the town for the HUD, the bot and tests. */
  summary() {
    const p = this.people.summary();
    let housing = 0;
    let jobs = 0;
    for (const rt of this.rt.values()) {
      const def = this.data.buildings[rt.type];
      housing += def.housing || 0;
      jobs += def.workers || 0;
    }
    return { population: p.population, housing, employed: p.employed, jobs, unemployed: p.unemployed, hungry: p.hungry, walkers: this.walkers.count, broke: this.broke, ledger: this.ledger };
  }

  /** Feed the simulation's state to a hash function (GameState.hash). */
  feed(feed) {
    const people = this.people;
    feed(people.villagers.size);
    for (const v of people.villagers.values()) {
      feed(v.id);
      feed(v.home);
      feed(v.job);
      if (v.pin) feed(0x5a);
      feed(v.at);
      feed(v.state === "walking" ? 1 : 0);
      feed(Math.round(v.food * 100));
      feed(Math.round(v.hunger * 100));
      const w = this.walkers.list.get(v.id);
      feed(w ? w.path[w.i] : 0);
      feed(v.trip ? v.trip.target : 0);
    }
    const ids = [...this.rt.keys()].sort((a, b) => a - b);
    for (const id of ids) {
      const rt = this.rt.get(id);
      feed(id);
      feed(Math.round(rt.progress * 10));
      feed(rt.cycles);
      for (const bag of [rt.inbox, rt.outbox, rt.shelf]) for (const g of this.data.goodIds) feed(bag[g] || 0);
      feed(rt.residents.length);
      feed(Math.round(rt.timer * 10));
    }
    const l = this.ledger;
    for (const g of this.data.goodIds) {
      feed(l.produced[g]);
      feed(l.consumed[g]);
      feed(l.eaten[g]);
      feed(l.lost[g]);
    }
    for (const n of [l.sales, l.wages, l.upkeep]) {
      feed(n);
      feed(n >> 16);
    }
    feed(this.broke ? 1 : 0);
    feed(this.state.clock.ticks);
  }
}
