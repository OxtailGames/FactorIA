// @ts-check
// Carriers (pure): the villagers who work at a warehouse. Once per `dispatchSeconds` the planner lists what the town needs
// moved and hands each job to an idle carrier of the warehouse nearest (by road) to the building concerned:
//
//   supply   take goods out of the stock, walk to a producer (its inbox needs them) or to the market (its shelf is below
//            marketTarget), put them there, walk back;
//   collect  walk to a producer that has finished goods in its outbox, take them, walk to the warehouse and add them to the
//            stock.
//
// All goods in the warehouses are ONE stock (state.economy.stock), at most `capacity()` of each good (baseStorage plus the
// storage of every warehouse); a good that does not fit when a carrier delivers it is lost (ledger.lost) and the planner does
// not send a carrier for a good whose stock is full, so a producer waits with a full outbox instead. Without a warehouse
// nothing moves: producers fill their outbox and stop, and the market stays empty.
//
// Reservations keep two carriers from being sent for the same goods: a supply reserves room in the inbox/shelf (`inRes`,
// `shelfRes`), a collect reserves goods in the outbox (`outRes`); both are released when the errand ends or is dropped.

export class Logistics {
  /** @param {import("./sim.js").Simulation} sim */
  constructor(sim) {
    this.sim = sim;
    this.state = sim.state;
    this.cfg = sim.cfg;
    this.timer = 0;
    /** @type {Map<number, number>} building id -> nearest warehouse id (0 = none), for one road/layout version */
    this.nearest = new Map();
    this.nearestKey = "";
    /** Errands started since the start. */
    this.errands = 0;
  }

  /** Units of a good in carriers' hands. */
  carried(good) {
    let n = 0;
    for (const v of this.sim.people.villagers.values()) if (v.trip) n += v.trip.cargo[good] || 0;
    return n;
  }

  // ---- planning ----------------------------------------------------------------------------------------------------------

  step(dt, f) {
    this.timer += dt;
    if (this.timer < this.cfg.dispatchSeconds) return;
    this.timer = 0;
    if (f < this.cfg.workStartDay || f >= this.cfg.workEndDay - 0.03) return;
    this.dispatch();
  }

  warehouseFor(target) {
    const sim = this.sim;
    const key = `${sim.net.version}:${sim.layoutVersion}`;
    if (key !== this.nearestKey) {
      this.nearest.clear();
      this.nearestKey = key;
    }
    const hit = this.nearest.get(target.id);
    if (hit !== undefined) return hit;
    let best = 0;
    let bestD = Infinity;
    for (const wh of sim.ofType("warehouse")) {
      const b = this.state.buildings.get(wh.id);
      const d = sim.net.distance(target, b);
      if (d >= 0 && d < bestD) {
        bestD = d;
        best = wh.id;
      }
    }
    this.nearest.set(target.id, best);
    return best;
  }

  /** The recipe a producer would run next if it had its inputs: the first with every input in the stock or inbox, this season. */
  wantedRecipe(rt, def) {
    const sim = this.sim;
    for (const id of def.recipes) {
      const r = sim.data.recipes[id];
      if (!Object.keys(r.inputs).length || sim.seasonRate(id) <= 0) continue;
      if (Object.entries(r.inputs).every(([g, n]) => (this.state.economy.stock[g] || 0) + (rt.inbox[g] || 0) + (rt.inRes[g] || 0) >= n)) return r;
    }
    return null;
  }

  plan() {
    const sim = this.sim;
    const stock = this.state.economy.stock;
    const defs = this.state.data.buildings;
    const cap = this.cfg.carrierCapacity;
    const storage = sim.capacity();
    const jobs = [];
    for (const rt of sim.rt.values()) {
      const def = defs[rt.type];
      if (rt.type === "market") {
        let onShelf = 0;
        for (const g of sim.foodGoods) onShelf += rt.shelf[g] || 0;
        for (const g of sim.foodGoods) {
          const need = this.cfg.marketTarget - (rt.shelf[g] || 0) - (rt.shelfRes[g] || 0);
          const qty = Math.min(need, cap, Math.floor(stock[g] || 0));
          if (qty >= 1 && (need >= 3 || (rt.shelf[g] || 0) < 1)) jobs.push({ prio: onShelf === 0 ? 0 : 2, kind: "supply", target: rt.id, goods: { [g]: qty } });
        }
        continue;
      }
      if (!def.recipes || !def.recipes.length) continue;
      const recipe = this.wantedRecipe(rt, def);
      if (recipe) {
        for (const [g, n] of Object.entries(recipe.inputs)) {
          const have = (rt.inbox[g] || 0) + (rt.inRes[g] || 0);
          const need = sim.inboxCap(rt, g) - have;
          const qty = Math.min(need, cap, Math.floor(stock[g] || 0));
          if (qty >= 1 && (have < n || need >= 3)) jobs.push({ prio: (rt.inbox[g] || 0) < n ? 1 : 3, kind: "supply", target: rt.id, goods: { [g]: qty } });
        }
      }
      const load = {};
      let total = 0;
      for (const g of this.state.data.goodIds) {
        const avail = Math.floor((rt.outbox[g] || 0) - (rt.outRes[g] || 0));
        if (avail < 1 || (stock[g] || 0) >= storage) continue;
        const take = Math.min(avail, cap - total);
        if (take < 1) break;
        load[g] = take;
        total += take;
      }
      if (total >= 2 || (total >= 1 && rt.stall === "output_full")) jobs.push({ prio: 2, kind: "collect", target: rt.id, goods: load });
    }
    return jobs.sort((a, b) => a.prio - b.prio || a.target - b.target);
  }

  dispatch() {
    const sim = this.sim;
    const people = sim.people;
    /** @type {Map<number, any[]>} idle carriers by warehouse */
    const idle = new Map();
    for (const v of people.villagers.values()) {
      if (!v.job || v.trip || v.state !== "inside" || v.at !== v.job) continue;
      const rt = sim.rt.get(v.job);
      if (!rt || rt.type !== "warehouse") continue;
      let list = idle.get(v.job);
      if (!list) idle.set(v.job, (list = []));
      list.push(v);
    }
    if (!idle.size) return;
    const stock = this.state.economy.stock;
    for (const job of this.plan()) {
      const target = this.state.buildings.get(job.target);
      const trt = sim.rt.get(job.target);
      if (!target || !trt) continue;
      const whId = this.warehouseFor(target);
      const carriers = idle.get(whId);
      if (!carriers || !carriers.length) continue;
      const wh = this.state.buildings.get(whId);
      const cargo = {};
      if (job.kind === "supply") {
        for (const [g, n] of Object.entries(job.goods)) {
          const q = Math.min(n, Math.floor(stock[g] || 0));
          if (q >= 1) cargo[g] = q;
        }
        if (!Object.keys(cargo).length) continue;
      }
      const v = carriers[0];
      const w = sim.walkers.start(v.id, "carrier", wh, target, this.cfg.walkSpeed.carrier, true);
      if (!w) continue;
      carriers.shift();
      v.state = "walking";
      v.purpose = "carry";
      const res = { ...(job.kind === "supply" ? cargo : job.goods) };
      v.trip = { kind: job.kind, target: job.target, wh: whId, phase: "out", cargo: job.kind === "supply" ? cargo : {}, res };
      if (job.kind === "supply") {
        this.state.economy.apply(Object.fromEntries(Object.entries(cargo).map(([g, n]) => [g, -n])), "dispatch");
        const bag = trt.type === "market" ? trt.shelfRes : trt.inRes;
        for (const [g, n] of Object.entries(cargo)) bag[g] = (bag[g] || 0) + n;
      } else {
        for (const [g, n] of Object.entries(res)) trt.outRes[g] = (trt.outRes[g] || 0) + n;
      }
      this.errands++;
    }
  }

  // ---- an errand ---------------------------------------------------------------------------------------------------------

  /** A carrier's walker arrived (at the target, or back at the warehouse). */
  arrived(v, w) {
    const sim = this.sim;
    const trip = v.trip;
    const b = this.state.buildings.get(w.goal);
    v.state = "inside";
    if (trip.phase === "out") {
      const trt = sim.rt.get(trip.target);
      v.at = b ? b.id : v.at;
      if (!b || !trt) {
        this.abort(v);
        v.at = v.home;
        return;
      }
      if (trip.kind === "supply") {
        const bag = trt.type === "market" ? trt.shelf : trt.inbox;
        const res = trt.type === "market" ? trt.shelfRes : trt.inRes;
        for (const [g, n] of Object.entries(trip.cargo)) {
          bag[g] = (bag[g] || 0) + n;
          res[g] = Math.max(0, (res[g] || 0) - n);
        }
        trip.cargo = {};
      } else {
        for (const [g, n] of Object.entries(trip.res)) {
          const take = Math.min(n, Math.floor(trt.outbox[g] || 0));
          trt.outRes[g] = Math.max(0, (trt.outRes[g] || 0) - n);
          if (take > 0) {
            trt.outbox[g] -= take;
            trip.cargo[g] = (trip.cargo[g] || 0) + take;
          }
        }
        trip.res = {};
      }
      const wh = this.state.buildings.get(trip.wh);
      if (!wh || !sim.rt.has(trip.wh) || !v.job) {
        this.abort(v);
        v.at = v.home;
        return;
      }
      const back = sim.walkers.start(v.id, "carrier", b, wh, this.cfg.walkSpeed.carrier, false);
      if (!back) {
        this.abort(v);
        v.at = v.home;
        return;
      }
      trip.phase = "back";
      v.state = "walking";
      return;
    }
    // back at the warehouse
    v.at = b ? b.id : v.home;
    this.unload(trip.cargo);
    v.trip = null;
  }

  /** Put goods in the stock; what does not fit is lost. */
  unload(cargo) {
    const sim = this.sim;
    const cap = sim.capacity();
    const delta = {};
    for (const [g, n] of Object.entries(cargo)) {
      if (n <= 0) continue;
      const room = Math.max(0, cap - (this.state.economy.stock[g] || 0));
      const put = Math.min(n, room);
      if (put > 0) delta[g] = put;
      if (n > put) sim.ledger.lost[g] += n - put;
    }
    if (Object.keys(delta).length) {
      this.state.economy.apply(delta, "delivery");
      this.state.events.emit("delivery", { goods: delta });
    }
  }

  /** The errand cannot go on (a building is gone, no road): release the reservations and put the cargo back in the stock. */
  abort(v) {
    const trip = v.trip;
    if (!trip) return;
    v.trip = null;
    this.sim.walkers.remove(v.id);
    const trt = this.sim.rt.get(trip.target);
    if (trt) {
      const bag = trip.kind === "collect" ? trt.outRes : trt.type === "market" ? trt.shelfRes : trt.inRes;
      const amounts = trip.kind === "collect" ? trip.res : trip.cargo;
      for (const [g, n] of Object.entries(amounts)) bag[g] = Math.max(0, (bag[g] || 0) - n);
    }
    this.unload(trip.cargo);
  }

  /** A building is gone: its carriers drop their errands (a warehouse's staff leaves with it). */
  buildingRemoved(b) {
    if (this.state.data.buildings[b.type].kind === "road") return;
    for (const v of this.sim.people.villagers.values()) if (v.trip && v.job === b.id) {
      this.abort(v);
      v.state = "inside";
      v.at = v.home;
    }
  }
}
