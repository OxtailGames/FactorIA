// @ts-check
// The villagers (pure): who lives where, who works where, what they eat and when they go out.
//
// A villager is INSIDE a building (`at`) or WALKING (a walker with the same id, walkers.js). The day (fractions of
// data/economy.json calendar.secondsPerDay):
//   work hours   from workStartDay (+ a spread by id, so they do not all leave together) to workEndDay (marketCloseDay for
//                the market's staff): the employed walk to their workplace and stay.
//   after work   a hungry villager goes to the market if it is open and has food, then everybody walks home.
// A villager eats `foodPerDay` food units a day from a buffer; it fills the buffer at the market (the coins go to the town).
// With the buffer empty for `hungerLimitDays` days it leaves the town.
//
// Villager = { id, home, job, at, state: "inside" | "walking", purpose, food, hunger, lastShop, trip }
//   job   workplace building id (0 = none); pin = true when the player put it there (reassign); trip = the carrier's current errand (logistics.js) or null.
//
// Events: "villager.arrived" {villager, house}, "villager.left" {villager, reason} (reason: starved | home_lost).

export class People {
  /** @param {import("./sim.js").Simulation} sim */
  constructor(sim) {
    this.sim = sim;
    this.state = sim.state;
    this.cfg = sim.cfg;
    /** @type {Map<number, any>} */
    this.villagers = new Map();
    this.nextId = 1;
    /** Jobs have to be handed out again (a building, a villager or a road changed). */
    this.dirty = true;
    this.seenRoads = -1;
    this.unemployedNow = 0;
    this.hungryNow = 0;
    /** Villagers that walked as far as they could and gave up, since the start. */
    this.lostCount = 0;
    /** Per-tick cache: the open markets. */
    this.openMarkets = [];
  }

  employed() {
    let n = 0;
    for (const v of this.villagers.values()) if (v.job) n++;
    return n;
  }

  summary() {
    let employed = 0;
    let hungry = 0;
    for (const v of this.villagers.values()) {
      if (v.job) employed++;
      if (v.food <= 0) hungry++;
    }
    return { population: this.villagers.size, employed, unemployed: this.villagers.size - employed, hungry };
  }

  // ---- a step ------------------------------------------------------------------------------------------------------------

  step(dt, f) {
    const sim = this.sim;
    const day = this.state.clock.day;
    if (this.dirty || this.seenRoads !== sim.net.version) this.assign();
    const ticksPerDay = this.state.clock.ticksPerDay;
    const dayDt = dt / this.state.clock.calendar.secondsPerDay;
    // presence and the open markets, from the state at the start of the step
    for (const rt of sim.rt.values()) rt.present = 0;
    for (const v of this.villagers.values()) if (v.state === "inside" && v.job && v.at === v.job) {
      const rt = sim.rt.get(v.job);
      if (rt) rt.present++;
    }
    this.openMarkets = [];
    for (const rt of sim.ofType("market")) if (rt.present > 0 && f < this.cfg.marketCloseDay) this.openMarkets.push(rt);
    let unemployed = 0;
    let hungry = 0;
    for (const v of [...this.villagers.values()]) {
      v.food -= this.cfg.foodPerDay * dayDt;
      if (v.food <= 0) {
        v.food = 0;
        v.hunger += dayDt;
        if (v.hunger >= this.cfg.hungerLimitDays) {
          this.leave(v, "starved");
          continue;
        }
        hungry++;
      } else v.hunger = 0;
      if (!v.job) unemployed++;
      if (v.state === "inside") this.decide(v, f, day);
    }
    this.unemployedNow = unemployed;
    this.hungryNow = hungry;
    void ticksPerDay;
    this.grow(dt);
  }

  startOf(v) {
    return this.cfg.workStartDay + ((v.id % 10) / 10) * this.cfg.departSpreadDay;
  }

  /** An inside villager: where should it be now? */
  decide(v, f, day) {
    const b = this.state.buildings;
    const job = v.job ? b.get(v.job) : null;
    const open = f >= this.startOf(v);
    const end = job && job.type === "market" ? this.cfg.marketCloseDay : this.cfg.workEndDay;
    if (job && open && f < end) {
      if (v.at !== job.id) this.go(v, job, "work");
      else if (job.type === "market" && v.food < this.cfg.shopBelow && v.lastShop !== day) {
        v.lastShop = day; // the market's own staff eat at the stall
        this.shop(v, job);
      }
      return;
    }
    if (open && f < this.cfg.marketCloseDay && v.food < this.cfg.shopBelow && v.lastShop !== day && this.openMarkets.length) {
      const m = this.nearestOpenMarket(v);
      if (m) {
        v.lastShop = day;
        this.go(v, m, "shop");
        return;
      }
    }
    if (v.at !== v.home) this.go(v, b.get(v.home), "home");
  }

  nearestOpenMarket(v) {
    const from = this.state.buildings.get(v.at);
    if (!from) return null;
    let best = null;
    let bestD = Infinity;
    for (const rt of this.openMarkets) {
      if (rt.id === v.at) {
        continue;
      }
      const m = this.state.buildings.get(rt.id);
      if (!m || !this.hasFood(rt)) continue;
      const d = this.sim.net.distance(from, m);
      if (d >= 0 && d < bestD) {
        bestD = d;
        best = m;
      }
    }
    return best;
  }

  hasFood(rt) {
    for (const g of this.sim.foodGoods) if ((rt.shelf[g] || 0) >= 1) return true;
    return false;
  }

  /** Send an inside villager walking to a building. Returns false when there is no way (it stays where it is). */
  go(v, target, purpose) {
    const from = this.state.buildings.get(v.at);
    if (!from) {
      v.at = v.home;
      return false;
    }
    const w = this.sim.walkers.start(v.id, "villager", from, target, this.cfg.walkSpeed.villager, target.type === "house");
    if (!w) return false;
    v.state = "walking";
    v.purpose = purpose;
    return true;
  }

  /** A walker arrived. */
  arrived(w) {
    const v = this.villagers.get(w.id);
    if (!v) return;
    if (v.trip) {
      this.sim.logistics.arrived(v, w);
      return;
    }
    const b = this.state.buildings.get(w.goal);
    v.state = "inside";
    if (!b) {
      v.at = v.home;
      return;
    }
    v.at = b.id;
    if (v.purpose === "shop") this.shop(v, b);
  }

  /** A walker gave up (no way over the roads, or its goal is gone): the villager is back home, in a manner of speaking. */
  lost(w, why) {
    void why;
    const v = this.villagers.get(w.id);
    if (!v) return;
    this.lostCount++;
    if (v.trip) this.sim.logistics.abort(v);
    v.state = "inside";
    v.at = v.home;
  }

  // ---- shopping ------------------------------------------------------------------------------------------------------------

  /** Buy food at the market until the buffer is full. */
  shop(v, market) {
    const sim = this.sim;
    const rt = sim.rt.get(market.id);
    const f = this.state.clock.dayFraction();
    if (!rt || rt.present === 0 || f >= this.cfg.marketCloseDay) return;
    const items = {};
    let coins = 0;
    while (v.food < this.cfg.foodBuffer) {
      let best = "";
      let bestCost = Infinity;
      for (const g of sim.foodGoods) {
        if ((rt.shelf[g] || 0) < 1) continue;
        const cost = sim.priceOf(g) / this.state.data.goods[g].nutrition;
        if (cost < bestCost) {
          bestCost = cost;
          best = g;
        }
      }
      if (!best) break;
      rt.shelf[best]--;
      v.food += this.state.data.goods[best].nutrition;
      v.hunger = 0;
      sim.ledger.eaten[best]++;
      items[best] = (items[best] || 0) + 1;
      coins += sim.priceOf(best);
    }
    if (coins === 0) v.lastShop = -1; // the shelves were empty: it may try again (this market or another)
    else sim.sale(coins, { market: market.id, villager: v.id, items, coins });
  }

  // ---- jobs --------------------------------------------------------------------------------------------------------------

  /** Hand out the jobs: the workplaces in priority order take the nearest unemployed villagers; a more important workplace may take staff from a less important one. */
  assign() {
    const sim = this.sim;
    const net = sim.net;
    this.dirty = false;
    this.seenRoads = net.version;
    const b = this.state.buildings;
    const defs = this.state.data.buildings;
    // drop jobs that are gone or cannot be reached any more
    for (const v of this.villagers.values()) {
      if (!v.job) continue;
      const wp = b.get(v.job);
      const home = b.get(v.home);
      if (!wp || !home || net.distance(home, wp) < 0) {
        v.job = 0;
        v.pin = false;
      }
    }
    /** @type {Map<number, number[]>} */
    const staff = new Map();
    for (const rt of sim.rt.values()) staff.set(rt.id, []);
    for (const v of this.villagers.values()) if (v.job) staff.get(v.job).push(v.id);
    const workplaces = [...sim.rt.values()].filter((rt) => defs[rt.type].workers > 0).sort((a, c) => defs[a.type].jobPriority - defs[c.type].jobPriority || a.id - c.id);
    const unemployed = [...this.villagers.values()].filter((v) => !v.job);
    // two rounds, so a small town runs everything slowly instead of a few buildings at full speed and the rest not at all:
    // first one worker for every workplace (by priority), then the rest of the jobs (by priority)
    for (const round of [1, 2]) {
      for (const wp of workplaces) {
        const def = defs[wp.type];
        const wb = b.get(wp.id);
        const list = /** @type {number[]} */ (staff.get(wp.id));
        const want = round === 1 ? Math.min(1, def.workers) : def.workers;
        while (list.length < want) {
          let pick = this.nearest(unemployed, wb);
          if (!pick) pick = this.steal(wp, wb, workplaces, staff, round === 1 ? 1 : 2);
          if (!pick) break;
          pick.job = wp.id;
          const i = unemployed.indexOf(pick);
          if (i >= 0) unemployed.splice(i, 1);
          list.push(pick.id);
        }
      }
    }
    for (const rt of sim.rt.values()) rt.staff = /** @type {number[]} */ (staff.get(rt.id));
  }

  /** The villager among `list` nearest to a workplace by road (ties: the lowest id). */
  nearest(list, wb) {
    const net = this.sim.net;
    let best = null;
    let bestD = Infinity;
    for (const v of list) {
      const home = this.state.buildings.get(v.home);
      const d = home ? net.distance(home, wb) : -1;
      if (d >= 0 && d < bestD) {
        bestD = d;
        best = v;
      }
    }
    return best;
  }

  /**
   * Take a villager for a workplace that has none. First round (`keep` 1): from the workplace with the most staff, so a new
   * building gets its first worker before an old one has two (ties: the least important), then from a sole worker of a less
   * important workplace. Second round (`keep` 2): only from a less important workplace that keeps at least one worker.
   */
  steal(wp, wb, workplaces, staff, keep) {
    const defs = this.state.data.buildings;
    const mine = defs[wp.type].jobPriority;
    const take = (o) => {
      const list = /** @type {number[]} */ (staff.get(o.id));
      const pick = this.nearest(list.map((id) => this.villagers.get(id)).filter((v) => !v.pin), wb); // a pinned job is the player's
      if (!pick) return null;
      list.splice(list.indexOf(pick.id), 1);
      pick.job = 0;
      return pick;
    };
    const size = (o) => /** @type {number[]} */ (staff.get(o.id)).length;
    const byImportance = (a, c) => defs[c.type].jobPriority - defs[a.type].jobPriority || c.id - a.id;
    if (keep === 1) {
      const crowded = workplaces.filter((o) => o !== wp && size(o) >= 2).sort((a, c) => size(c) - size(a) || byImportance(a, c));
      for (const o of crowded) {
        const pick = take(o);
        if (pick) return pick;
      }
    }
    const victims = workplaces.filter((o) => defs[o.type].jobPriority > mine && size(o) >= keep).sort(byImportance);
    for (const o of victims) {
      const pick = take(o);
      if (pick) return pick;
    }
    return null;
  }

  /**
   * Player action (the inspector's drag and drop, scripts/game/ui_hud.js): put a villager to work at a workplace and PIN the job, so
   * `assign` does not hand it to somebody else or take the villager for a more important workplace. The workplace must have
   * a free place and a road from the villager's home. The job it left is filled again from the unemployed.
   * @returns {{ ok: boolean, code?: string }} code: gone, no_jobs, same, no_road, full
   */
  reassign(villagerId, workplaceId) {
    const check = this.canReassign(villagerId, workplaceId);
    if (!check.ok) return check;
    const v = this.villagers.get(villagerId);
    v.job = workplaceId;
    v.pin = true;
    this.dirty = true;
    this.state.events.emit("villager.reassigned", { villager: v.id, workplace: workplaceId });
    return { ok: true };
  }

  /** Could `reassign` do it? Same answer, nothing changes (the drag asks while the mouse moves, to colour the target). */
  canReassign(villagerId, workplaceId) {
    const v = this.villagers.get(villagerId);
    const rt = this.sim.rt.get(workplaceId);
    if (!v || !rt) return { ok: false, code: "gone" };
    const def = this.state.data.buildings[rt.type];
    if (!def.workers) return { ok: false, code: "no_jobs" };
    if (v.job === workplaceId) return { ok: false, code: "same" };
    const home = this.state.buildings.get(v.home);
    const wp = this.state.buildings.get(workplaceId);
    if (!home || !wp || this.sim.net.distance(home, wp) < 0) return { ok: false, code: "no_road" };
    let staffed = 0;
    for (const o of this.villagers.values()) if (o.job === workplaceId) staffed++;
    if (staffed >= def.workers) return { ok: false, code: "full" };
    return { ok: true };
  }

  /** Player action: take a villager off its job and let `assign` decide again (a villager dropped on "free"). */
  release(villagerId) {
    const v = this.villagers.get(villagerId);
    if (!v) return { ok: false, code: "gone" };
    v.pin = false;
    v.job = 0;
    this.dirty = true;
    this.state.events.emit("villager.reassigned", { villager: v.id, workplace: 0 });
    return { ok: true };
  }

  // ---- growth --------------------------------------------------------------------------------------------------------------

  /** Houses take in a new villager when there is room, food and work for it. */
  grow(dt) {
    const sim = this.sim;
    const defs = this.state.data.buildings;
    let townFood = -1;
    for (const rt of sim.ofType("house")) {
      const def = defs.house;
      if (rt.residents.length >= def.housing) {
        rt.timer = 0;
        continue;
      }
      const period = rt.arrivals === 0 ? this.cfg.firstArrivalSeconds : this.cfg.growthSeconds;
      rt.timer = Math.min(period, rt.timer + dt);
      if (rt.timer < period) continue;
      if (this.villagers.size >= this.cfg.founders) {
        if (this.unemployedNow >= this.cfg.unemployedLimit || this.hungryNow > 0) continue;
        if (townFood < 0) townFood = this.townFood();
        if (townFood < (this.villagers.size + 1) * this.cfg.foodPerDay * this.cfg.growthFoodDays) continue;
      }
      if (!sim.net.accessCells(this.state.buildings.get(rt.id)).length) continue; // a house without a road to it is not a home
      this.arrive(rt);
      rt.timer = 0;
      townFood = -1;
    }
  }

  /** Food units the town has to offer: the market shelves and the stock (not the packs the villagers carry). */
  townFood() {
    const sim = this.sim;
    const goods = this.state.data.goods;
    let n = 0;
    for (const g of sim.foodGoods) {
      n += (this.state.economy.stock[g] || 0) * goods[g].nutrition;
      for (const rt of sim.rt.values()) n += (rt.shelf[g] || 0) * goods[g].nutrition;
    }
    return n;
  }

  arrive(houseRt) {
    const v = { id: this.nextId++, home: houseRt.id, job: 0, at: houseRt.id, state: "inside", purpose: "", food: this.cfg.foodBuffer, hunger: 0, lastShop: -1, trip: null };
    this.villagers.set(v.id, v);
    houseRt.residents.push(v.id);
    houseRt.arrivals++;
    this.dirty = true;
    this.state.events.emit("villager.arrived", { villager: v.id, house: houseRt.id });
    return v;
  }

  /** Put a villager in a house at once (tests, the stress town); the house must have room. */
  moveIn(houseId) {
    const rt = this.sim.rt.get(houseId);
    if (!rt || rt.residents.length >= this.state.data.buildings.house.housing) return null;
    return this.arrive(rt);
  }

  leave(v, reason) {
    this.sim.walkers.remove(v.id);
    if (v.trip) this.sim.logistics.abort(v);
    this.villagers.delete(v.id);
    const home = this.sim.rt.get(v.home);
    if (home) home.residents.splice(home.residents.indexOf(v.id), 1);
    this.dirty = true;
    this.state.events.emit("villager.left", { villager: v.id, reason });
  }

  // ---- buildings going away ------------------------------------------------------------------------------------------------

  buildingRemoved(b, rt) {
    for (const v of [...this.villagers.values()]) {
      if (v.home === b.id) {
        this.leave(v, "home_lost");
        continue;
      }
      if (v.job === b.id) v.job = 0;
      if (v.state === "inside" && v.at === b.id) v.at = v.home;
    }
    void rt;
  }
}
