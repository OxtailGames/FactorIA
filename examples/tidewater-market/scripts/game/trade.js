// @ts-check
// Ships, orders, reputation, event cards, the story of a scenario and the progress behind the achievements (P5). Pure: it only
// uses the GameState (map, clock, economy, buildings, event bus), so tests and the bot run it with no engine.
//
// `state.trade` exists on every GameState but is OFF until `trade.start(scenarioId)` (the game screen does it; the bot and the
// older tests never do, so their towns are unchanged). Everything it keeps is in plain fields that `snapshot()` copies to a
// JSON object and `restore(snapshot)` reads back (README, "Ships and events (P5)"):
//
//   ships      the ships in the bay: { id, cls, name, berth, route, t, pt, state, order, wait, deadline }
//   reputation 0..100, unlocks better ships
//   queue/card the event cards waiting and the one on screen ({ stage: "choose" | "result" })
//   rng        the state of three Rng streams (ships, events, outcomes)
//   stats      counters (orders filled, missed, ...) and the achievements unlocked
//
// It reacts to the clock ("clock.day" once a day, "clock.tick" for the sailing), "building.removed" (a pier torn down sends its
// ship away) and "payday" (a broke day resets the debt-free count), and it announces everything on the bus as "trade.*":
// ship.docked, ship.left, order.filled, order.missed, reputation, class.unlocked, card, choice, card.closed, story.finished,
// achievement. Money and goods only ever move through `economy.apply(delta, cause)` (causes "trade" and "event").
import { getTradeData } from "./trade_data.js";
import { Rng, streamSeed } from "./rng.js";
import { berthOf, along } from "./sea.js";

export const SNAPSHOT_VERSION = 1;

/** Round to the nearest 5 coins, at least 5. */
const round5 = (n) => Math.max(5, Math.round(n / 5) * 5);

export class Trade {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.events = state.events;
    this.enabled = false;
    this.scenario = "";
    this.reset();
    this.events.on("clock.day", (e) => this.enabled && this.onDay(e.date));
    this.events.on("clock.tick", (e) => this.enabled && this.onTick(e.seconds));
    this.events.on("building.removed", (e) => this.enabled && this.onRemoved(e.building));
    this.events.on("building.placed", (e) => this.enabled && this.onPlaced(e.building));
    this.events.on("payday", (e) => this.enabled && e.broke && (this.stats.lastBrokeDay = this.state.clock.day));
  }

  /** Back to an empty trade (keeps `enabled` and `scenario`). */
  reset() {
    this.reputation = 0;
    /** @type {any[]} */
    this.ships = [];
    this.nextShipId = 1;
    /** Game day the next ship is sent on; Infinity until the first pier stands. */
    this.nextShipDay = Infinity;
    /** @type {Array<{ kind: string, id: string }>} */
    this.queue = [];
    /** @type {null | { kind: string, id: string, stage: string, choice?: string, outcome?: number | null }} */
    this.card = null;
    /** @type {string[]} */
    this.history = [];
    this.storyIndex = 0;
    this.storyDone = false;
    this.startDay = 0;
    this.stats = { ordersFilled: 0, ordersMissed: 0, shipsDocked: 0, shipsLeft: 0, eventsResolved: 0, coinsEarned: 0, lastBrokeDay: -1 };
    /** @type {string[]} */
    this.unlocked = [];
    /** @type {string[]} ship classes announced to the player */
    this.classesSeen = [];
    this.rngShips = new Rng(1);
    this.rngEvents = new Rng(2);
    this.rngOutcomes = new Rng(3);
  }

  /**
   * Turn the trade on for a scenario (an id of data/scenarios.json; one with no story, or an unknown one, plays without).
   * Starts every stream from the map seed, so one seed and the same choices give the same ships and events.
   * @param {string} scenario
   */
  start(scenario) {
    this.reset();
    this.enabled = true;
    this.scenario = scenario;
    this.data = getTradeData();
    this.cards = this.data.story.scenarios[scenario] || [];
    const seed = this.state.map.seed || 0;
    this.rngShips = new Rng(streamSeed(seed, "ships"));
    this.rngEvents = new Rng(streamSeed(seed, "events"));
    this.rngOutcomes = new Rng(streamSeed(seed, "outcomes"));
    this.startDay = this.state.clock.day;
    this.stats.lastBrokeDay = this.startDay;
    this.reputation = this.data.ships.reputation.start;
    this.noteClasses();
    if (this.state.list("pier").length) this.nextShipDay = this.startDay + this.data.ships.schedule.firstShipDays;
  }

  /** Switch off (the game screen was left). Ships and cards stay as they are. */
  stop() {
    this.enabled = false;
  }

  // ---- the clock ---------------------------------------------------------------------------------------------------

  /** @param {{ day: number, season: string, dayOfSeason: number }} date */
  onDay(date) {
    const sched = this.data.ships.schedule;
    // 1. orders past their deadline
    for (const ship of this.ships) {
      if (ship.state === "docked" && date.day >= ship.deadline) this.miss(ship);
    }
    // 2. a new ship
    if (date.day >= this.nextShipDay) {
      if (this.spawnShip(date.day)) {
        const [lo, hi] = sched.gapDays;
        this.nextShipDay = date.day + this.rngShips.int(lo, hi);
      } else this.nextShipDay = date.day + sched.retryDays;
    }
    // 3. the story card of the day (it goes first), then an event card, drawn once per season
    this.checkStory();
    if (date.dayOfSeason === this.data.events.eventDay) this.drawEvent(date);
    this.checkAchievements();
  }

  onTick(seconds) {
    const speed = this.data.ships.sailSpeed;
    for (const ship of this.ships.slice()) {
      ship.pt = ship.t;
      const length = ship.route.length - 1;
      if (ship.state === "arriving") {
        ship.t += speed * seconds;
        if (ship.t >= length) {
          ship.t = length;
          this.dock(ship);
        }
      } else if (ship.state === "leaving") {
        ship.t -= speed * seconds;
        if (ship.t <= 0) {
          this.ships.splice(this.ships.indexOf(ship), 1);
          this.stats.shipsLeft++;
          this.events.emit("trade.ship.left", { ship, outcome: ship.outcome });
        }
      }
    }
  }

  onPlaced(building) {
    if (building.type === "pier" && !this.firstPierSeen()) {
      this.nextShipDay = Math.min(this.nextShipDay, this.state.clock.day + this.data.ships.schedule.firstShipDays);
    }
  }

  /** True once a pier has been built before (a ship has been sent, or one is booked). */
  firstPierSeen() {
    return this.nextShipDay !== Infinity;
  }

  onRemoved(building) {
    if (building.type !== "pier") return;
    for (const ship of this.ships) {
      if (ship.berth === building.id && ship.state !== "leaving") {
        ship.state = "leaving";
        ship.outcome = "cancelled";
      }
    }
  }

  // ---- ships and orders --------------------------------------------------------------------------------------------

  /** Classes the town can be visited by at the current reputation. */
  availableClasses() {
    const classes = this.data.ships.classes;
    return Object.keys(classes).filter((id) => classes[id].minReputation <= this.reputation);
  }

  noteClasses() {
    for (const id of this.availableClasses()) {
      if (!this.classesSeen.includes(id)) {
        this.classesSeen.push(id);
        if (this.classesSeen.length > 1) this.events.emit("trade.class.unlocked", { cls: id });
      }
    }
  }

  /** Send a ship to a free pier. Returns false (and draws nothing) when there is no pier with a berth free. */
  spawnShip(day) {
    const taken = new Set(this.ships.map((s) => s.berth));
    let berth = null;
    let pier = null;
    for (const p of this.state.list("pier")) {
      if (taken.has(p.id)) continue;
      berth = berthOf(this.state, p);
      if (berth) {
        pier = p;
        break;
      }
    }
    if (!pier || !berth) return false;
    const cfg = this.data.ships;
    const rng = this.rngShips;
    const ids = this.availableClasses();
    const cls = rng.weighted(ids, ids.map((id) => cfg.classes[id].weight)) || ids[0];
    const def = cfg.classes[cls];
    const name = rng.int(0, cfg.nameCount - 1);
    // the order: some goods of the class's wish list, each with an amount
    const pool = Object.keys(def.wants);
    const kinds = Math.min(rng.int(def.goods[0], def.goods[1]), pool.length);
    const goods = {};
    let value = 0;
    for (let i = 0; i < kinds; i++) {
      const good = pool.splice(Math.floor(rng.float() * pool.length), 1)[0];
      const [lo, hi] = def.wants[good];
      goods[good] = rng.int(lo, hi);
      value += goods[good] * this.state.data.goods[good].basePrice;
    }
    const wait = rng.int(cfg.schedule.orderDays[0], cfg.schedule.orderDays[1]);
    const ship = {
      id: this.nextShipId++,
      cls,
      name,
      berth: pier.id,
      route: berth.route,
      t: 0,
      pt: 0,
      state: "arriving",
      order: { goods, reward: round5(value * def.premium) },
      wait,
      deadline: null,
      outcome: null,
      sentDay: day,
    };
    this.ships.push(ship);
    this.events.emit("trade.ship.sent", { ship });
    return true;
  }

  dock(ship) {
    ship.state = "docked";
    ship.deadline = this.state.clock.day + ship.wait;
    this.stats.shipsDocked++;
    this.events.emit("trade.ship.docked", { ship });
    this.checkAchievements();
  }

  /** Days left before the ship gives up (docked ships only). */
  daysLeft(ship) {
    return ship.state === "docked" ? Math.max(0, ship.deadline - this.state.clock.day) : ship.wait;
  }

  /** Can the order of a docked ship be filled from the stock now? @returns {{ ok: boolean, code?: string, missing?: Record<string, number> }} */
  canFill(shipId) {
    const ship = this.ships.find((s) => s.id === shipId);
    if (!ship || ship.state !== "docked") return { ok: false, code: "not_docked" };
    const need = {};
    for (const [g, n] of Object.entries(ship.order.goods)) need[g] = -n;
    const check = this.state.economy.canApply(need);
    return check.ok ? { ok: true } : { ok: false, code: "missing_goods", missing: check.missing };
  }

  /** Hand over the goods and take the reward: the ship leaves. @returns {{ ok: boolean, code?: string, reward?: number, missing?: Record<string, number> }} */
  fillOrder(shipId) {
    const verdict = this.canFill(shipId);
    if (!verdict.ok) return verdict;
    const ship = this.ships.find((s) => s.id === shipId);
    const delta = { coins: ship.order.reward };
    for (const [g, n] of Object.entries(ship.order.goods)) delta[g] = -n;
    this.state.economy.apply(delta, "trade");
    const cfg = this.data.ships.reputation;
    const early = this.state.clock.day <= ship.deadline - Math.ceil(ship.wait / 2);
    this.stats.ordersFilled++;
    this.stats.coinsEarned += ship.order.reward;
    ship.state = "leaving";
    ship.outcome = "filled";
    this.events.emit("trade.order.filled", { ship, reward: ship.order.reward, early });
    this.addReputation(cfg.filled + (early ? cfg.earlyBonus : 0));
    this.checkStory();
    this.checkAchievements();
    return { ok: true, reward: ship.order.reward };
  }

  miss(ship) {
    ship.state = "leaving";
    ship.outcome = "missed";
    this.stats.ordersMissed++;
    this.events.emit("trade.order.missed", { ship });
    this.addReputation(this.data.ships.reputation.missed);
  }

  addReputation(delta) {
    if (!delta) return;
    const max = this.data.ships.reputation.max;
    const before = this.reputation;
    this.reputation = Math.max(0, Math.min(max, this.reputation + delta));
    this.events.emit("trade.reputation", { value: this.reputation, delta: this.reputation - before });
    this.noteClasses();
    this.checkAchievements();
  }

  /** Where a ship is, for drawing: { x, y, heading } in fractional cells; `alpha` (0..1) is the clock's share of the next step. */
  position(ship, alpha = 1) {
    const dir = ship.state === "leaving" ? -1 : 1;
    const t = ship.pt + (ship.t - ship.pt) * alpha;
    const p = along(ship.route, t);
    // a ship leaving looks where it is going: backwards along its route
    const heading = ship.state === "leaving" ? (p.heading + 2) % 4 : p.heading;
    return { x: p.x, y: p.y, heading: dir < 0 ? heading : p.heading };
  }

  // ---- conditions --------------------------------------------------------------------------------------------------

  /** Does every key of a `when` / `requires` object hold now? */
  meets(when) {
    const s = this.state;
    for (const [k, v] of Object.entries(when || {})) {
      let ok = true;
      switch (k) {
        case "day": ok = s.clock.day >= v; break;
        case "season": ok = s.clock.date().season === v; break;
        case "pier": ok = s.list("pier").length >= v; break;
        case "ordersFilled":
        case "shipsFilled": ok = this.stats.ordersFilled >= v; break;
        case "reputation": ok = this.reputation >= v; break;
        case "population": ok = s.sim.summary().population >= v; break;
        case "coins": ok = s.economy.coins >= v; break;
        case "built": ok = Object.entries(v).every(([type, n]) => s.list(type).length >= n); break;
        default: ok = false;
      }
      if (!ok) return false;
    }
    return true;
  }

  // ---- cards -------------------------------------------------------------------------------------------------------

  /** Pick this season's event by weight (one draw of the events stream, always) and queue its card. */
  drawEvent(date) {
    const defs = this.data.events.events;
    const ids = Object.keys(defs);
    const weights = ids.map((id) => {
      const w = (defs[id].weights || {})[date.season] || 0;
      if (!w || this.history.includes(id) || !this.meets(defs[id].requires)) return 0;
      return w;
    });
    const pick = this.rngEvents.weighted(ids, weights);
    if (!pick) return null;
    this.history.push(pick);
    this.history = this.history.slice(-this.data.events.history);
    if (this.queue.length + (this.card ? 1 : 0) >= 3) return null; // the player is far behind: skip this one
    this.enqueue({ kind: "event", id: pick });
    return pick;
  }

  /** The next story card of the scenario when its `when` holds and none is waiting or open. */
  checkStory() {
    if (this.storyDone || this.storyIndex >= this.cards.length) return;
    const card = this.cards[this.storyIndex];
    if (this.queue.some((q) => q.kind === "story") || (this.card && this.card.kind === "story")) return;
    if (this.meets(card.when)) this.enqueue({ kind: "story", id: card.id });
  }

  enqueue(ref) {
    this.queue.push(ref);
    this.openNext();
  }

  openNext() {
    if (this.card || !this.queue.length) return;
    const ref = this.queue.shift();
    this.card = { ...ref, stage: "choose" };
    this.events.emit("trade.card", { card: this.card });
  }

  /** The definition and the locale key prefix of a card ({ kind, id }). */
  cardDef(ref) {
    if (ref.kind === "story") return { def: this.cards.find((c) => c.id === ref.id), base: `story.${this.scenario}.${ref.id}` };
    return { def: this.data.events.events[ref.id], base: `event.${ref.id}` };
  }

  /** Can the choice be picked now? A plain choice needs the money and goods it costs; a gamble can always be picked. */
  canChoose(choice) {
    if (choice.outcomes) return { ok: true };
    const delta = (choice.effects && choice.effects.delta) || {};
    return this.state.economy.canApply(delta);
  }

  /** Answer the open card. @returns {{ ok: boolean, code?: string, missing?: any, outcome?: number | null }} */
  choose(choiceId) {
    const card = this.card;
    if (!card || card.stage !== "choose") return { ok: false, code: "no_card" };
    const { def } = this.cardDef(card);
    const choice = def.choices.find((c) => c.id === choiceId);
    if (!choice) return { ok: false, code: "unknown_choice" };
    const can = this.canChoose(choice);
    if (!can.ok) return { ok: false, code: "cannot_afford", missing: can.missing };
    let outcome = null;
    let effects = choice.effects;
    if (choice.outcomes) {
      outcome = this.rngOutcomes.weighted(choice.outcomes.map((_, i) => i), choice.outcomes.map((o) => o.weight));
      effects = choice.outcomes[outcome].effects;
    }
    const applied = this.applyEffects(effects, !!choice.outcomes);
    card.stage = "result";
    card.applied = applied;
    card.choice = choiceId;
    card.outcome = outcome;
    this.stats.eventsResolved++;
    if (card.kind === "story") {
      this.storyIndex++;
      if (this.storyIndex >= this.cards.length) {
        this.storyDone = true;
        this.events.emit("trade.story.finished", { scenario: this.scenario });
        this.unlock(`story_${this.scenario}`);
      }
    }
    this.events.emit("trade.choice", { card, choice: choiceId, outcome });
    this.checkAchievements();
    return { ok: true, outcome };
  }

  /** What an answered card did, as { delta (what the economy really moved), reputation, shipDelay }; null before the answer. */
  resultEffects(card) {
    if (!card || card.stage !== "result") return null;
    const { def } = this.cardDef(card);
    const choice = def.choices.find((c) => c.id === card.choice);
    const effects = (choice.outcomes ? choice.outcomes[card.outcome].effects : choice.effects) || {};
    return { delta: card.applied || {}, reputation: effects.reputation || 0, shipDelay: effects.shipDelay || 0 };
  }

  /** Close the result of the answered card; the next waiting card opens. */
  dismiss() {
    if (!this.card || this.card.stage !== "result") return false;
    const closed = this.card;
    this.card = null;
    this.events.emit("trade.card.closed", { card: closed });
    this.openNext();
    this.checkStory();
    return true;
  }

  /**
   * Apply { delta, reputation, shipDelay }. `clamp`: take at most what the town has of each good it loses (a gamble that costs
   * 12 fish takes 5 when there are 5).
   */
  applyEffects(effects, clamp) {
    const eco = this.state.economy;
    const delta = { ...((effects && effects.delta) || {}) };
    if (clamp) for (const [k, v] of Object.entries(delta)) if (v < 0) delta[k] = -Math.min(-v, eco.get(k));
    for (const k of Object.keys(delta)) if (!delta[k]) delete delta[k];
    if (Object.keys(delta).length) eco.apply(delta, "event");
    if (effects && effects.reputation) this.addReputation(effects.reputation);
    if (effects && effects.shipDelay && this.nextShipDay !== Infinity) {
      this.nextShipDay = Math.max(this.state.clock.day + 1, this.nextShipDay + effects.shipDelay);
    }
    return delta;
  }

  // ---- achievements ------------------------------------------------------------------------------------------------

  unlock(id) {
    if (this.unlocked.includes(id)) return;
    this.unlocked.push(id);
    this.events.emit("trade.achievement", { id });
  }

  checkAchievements() {
    const cal = this.state.data.calendar;
    if (this.stats.shipsDocked >= 1) this.unlock("first_ship");
    if (this.stats.ordersFilled >= 10) this.unlock("ten_orders");
    if (this.reputation >= 50) this.unlock("harbour_master");
    const yearDays = cal.seasons.length * cal.daysPerSeason;
    if (this.state.clock.day - Math.max(this.stats.lastBrokeDay, this.startDay) >= yearDays) this.unlock("no_debt_year");
  }

  // ---- saving ------------------------------------------------------------------------------------------------------

  /** Everything this module keeps, as plain JSON (see the README for what P4 does with it). */
  snapshot() {
    return JSON.parse(
      JSON.stringify({
        v: SNAPSHOT_VERSION,
        scenario: this.scenario,
        enabled: this.enabled,
        startDay: this.startDay,
        reputation: this.reputation,
        nextShipDay: this.nextShipDay === Infinity ? null : this.nextShipDay,
        nextShipId: this.nextShipId,
        ships: this.ships,
        queue: this.queue,
        card: this.card,
        history: this.history,
        storyIndex: this.storyIndex,
        storyDone: this.storyDone,
        stats: this.stats,
        unlocked: this.unlocked,
        classesSeen: this.classesSeen,
        rng: { ships: this.rngShips.state, events: this.rngEvents.state, outcomes: this.rngOutcomes.state },
      }),
    );
  }

  /** Read a snapshot made by `snapshot()` (a copy: the object is not kept). The game must have the same map and buildings. */
  restore(snap) {
    if (!snap || snap.v !== SNAPSHOT_VERSION) throw new Error(`trade snapshot version ${snap && snap.v} is not ${SNAPSHOT_VERSION}`);
    this.start(snap.scenario);
    const s = JSON.parse(JSON.stringify(snap));
    this.enabled = s.enabled;
    this.startDay = s.startDay;
    this.reputation = s.reputation;
    this.nextShipDay = s.nextShipDay === null ? Infinity : s.nextShipDay;
    this.nextShipId = s.nextShipId;
    this.ships = s.ships;
    this.queue = s.queue;
    this.card = s.card;
    this.history = s.history;
    this.storyIndex = s.storyIndex;
    this.storyDone = s.storyDone;
    this.stats = s.stats;
    this.unlocked = s.unlocked;
    this.classesSeen = s.classesSeen;
    this.rngShips.state = s.rng.ships;
    this.rngEvents.state = s.rng.events;
    this.rngOutcomes.state = s.rng.outcomes;
    this.events.emit("trade.restored", {});
  }

  /** A fingerprint of the trade (tests compare two runs with it). */
  hash() {
    const text = JSON.stringify(this.snapshot());
    let h = 0x811c9dc5;
    for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, "0");
  }
}
