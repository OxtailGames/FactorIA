// The town's life (scripts/game/sim.js and its parts) on the hand-made test map: villagers and growth, the day's schedule,
// walkers on the roads (a road cut under them), production, carriers and the stock, the market, wages, hunger.
import { test, expect } from "factoria:test";
import { createGame } from "../scripts/game/state.js";
import { smallTown, runSeconds, runDays, runToDayFraction, fillHouses, inventory, put, roadRow, roadCol, rich } from "./town_helper.js";

/** The goods that only move and are made and eaten (building costs and demolition refunds also touch wood, stone and planks). */
const FLOW_GOODS = ["fish", "grain", "flour", "bread", "smoked_fish"];

/** The balance of a good over the run: what a conserving economy keeps equal to zero. */
function drift(game, before, good) {
  const l = game.sim.ledger;
  return game.sim.inventory(good) - (before[good] + l.produced[good] - l.consumed[good] - l.eaten[good] - l.lost[good]);
}

test("houses take in villagers one by one, up to four each, and a house without a road gets none", () => {
  const game = createGame({ testMap: true });
  rich(game);
  roadRow(game, 5, 1, 4);
  const house = put(game, "house", 2, 4);
  const lonely = put(game, "house", 8, 7);
  const arrived = [];
  game.events.on("villager.arrived", (e) => arrived.push(e.house));
  runSeconds(game, 3);
  expect(game.sim.people.villagers.size).toBe(0);
  runSeconds(game, 2); // firstArrivalSeconds = 4
  expect(game.sim.people.villagers.size).toBe(1);
  runSeconds(game, 11); // growthSeconds = 12
  expect(game.sim.people.villagers.size).toBe(1);
  runSeconds(game, 1);
  expect(game.sim.people.villagers.size).toBe(2);
  runSeconds(game, 60);
  expect(game.sim.rt.get(house.id).residents.length).toBeLessThanOrEqual(4);
  expect(game.sim.rt.get(lonely.id).residents.length).toBe(0);
  expect(arrived.every((id) => id === house.id)).toBe(true);
  expect(game.sim.summary().housing).toBe(8);
});

test("work: the employed are inside their workplace in work hours and at home at night", () => {
  const { game, ids } = smallTown();
  fillHouses(game);
  const people = game.sim.people;
  expect(people.villagers.size).toBe(24);
  runToDayFraction(game, 0.3);
  runSeconds(game, 3); // everybody has had time to leave and arrive
  const farm = game.sim.rt.get(ids.farm);
  expect(farm.staff).toHaveLength(2);
  expect(farm.present).toBe(2);
  for (const id of farm.staff) {
    const v = people.villagers.get(id);
    expect(v.at).toBe(ids.farm);
    expect(v.state).toBe("inside");
  }
  // only carriers (on errands) and shoppers are out in work hours: nobody is still commuting
  for (const v of people.villagers.values()) expect(v.purpose === "work" && v.state === "walking").toBe(false);
  // in the evening they walk home
  runToDayFraction(game, 0.62);
  runSeconds(game, 1);
  expect(game.sim.walkers.count).toBeGreaterThan(0);
  runToDayFraction(game, 0.85);
  const market = game.sim.rt.get(ids.market);
  for (const v of people.villagers.values()) {
    if (v.job === ids.market) continue; // the market stays open until marketCloseDay
    expect(v.state === "walking" || v.at === v.home).toBe(true);
  }
  runToDayFraction(game, 0.999);
  for (const v of people.villagers.values()) if (v.job !== ids.market && v.state !== "walking") expect(v.at).toBe(v.home); // the late ones are still on the road
  expect(market.staff).toHaveLength(2);
});

test("jobs go by priority: every workplace gets one worker first, the market and the warehouse before the farms", () => {
  const { game, ids } = smallTown();
  const people = game.sim.people;
  const rt = (id) => game.sim.rt.get(id);
  // 3 villagers for 6 workplaces: the market, the warehouse and one producer
  for (let i = 0; i < 3; i++) people.moveIn(ids.houses[0]);
  people.assign();
  expect(rt(ids.market).staff).toHaveLength(1);
  expect(rt(ids.warehouse).staff).toHaveLength(1);
  expect(rt(ids.farm).staff.length + rt(ids.dock).staff.length + rt(ids.bakery).staff.length + rt(ids.smokehouse).staff.length).toBe(1);
  // 8 villagers: one in every workplace, the 2 left go to the market and the warehouse
  for (let i = 0; i < 5; i++) people.moveIn(ids.houses[i < 1 ? 0 : 1]);
  people.assign();
  expect(people.villagers.size).toBe(8);
  expect(rt(ids.market).staff).toHaveLength(2);
  expect(rt(ids.warehouse).staff).toHaveLength(2);
  for (const id of [ids.farm, ids.dock, ids.bakery, ids.smokehouse]) expect(rt(id).staff).toHaveLength(1);
  // more arrive: they fill the remaining jobs, nobody has two
  fillHouses(game);
  people.assign();
  const jobs = [...people.villagers.values()].filter((v) => v.job).length;
  expect(jobs).toBe(Math.min(game.sim.summary().jobs, people.villagers.size));
});

test("a walker follows the roads and a villager arrives at the door of its workplace", () => {
  const { game, ids } = smallTown({ parts: ["farm"] });
  const v = game.sim.people.moveIn(ids.houses[0]);
  game.sim.people.assign();
  expect(v.job).toBe(ids.farm);
  runToDayFraction(game, 0.06);
  runSeconds(game, 0.4);
  const w = game.sim.walkers.list.get(v.id);
  expect(w).toBeDefined();
  expect(w.kind).toBe("villager");
  expect(game.sim.net.road[w.path[0]]).toBe(1);
  expect(game.sim.net.road[w.path[w.path.length - 1]]).toBe(1);
  // every cell of the way is road and consecutive cells share an edge
  const width = game.map.width;
  for (let k = 0; k < w.path.length; k++) {
    expect(game.sim.net.road[w.path[k]]).toBe(1);
    if (k) expect(Math.abs((w.path[k] % width) - (w.path[k - 1] % width)) + Math.abs(Math.floor(w.path[k] / width) - Math.floor(w.path[k - 1] / width))).toBe(1);
  }
  runSeconds(game, 10);
  expect(v.at).toBe(ids.farm);
});

/** A ring of roads: row 5 and row 7 joined by columns 2 and 8, a house at (2,4) and a farm at (7,3). */
function ringTown() {
  const game = createGame({ testMap: true });
  rich(game);
  roadRow(game, 5, 2, 8);
  roadRow(game, 7, 2, 8);
  roadCol(game, 2, 6, 6);
  roadCol(game, 8, 6, 6);
  const house = put(game, "house", 2, 4);
  const farm = put(game, "farm", 7, 3);
  const v = game.sim.people.moveIn(house.id);
  game.sim.people.assign();
  return { game, house, farm, v };
}

test("a road cut under a walker sends it the other way round", () => {
  const { game, farm, v } = ringTown();
  runToDayFraction(game, 0.06);
  runSeconds(game, 1);
  const w = game.sim.walkers.list.get(v.id);
  expect(w).toBeDefined();
  const first = w.path.length;
  expect(first).toBeLessThan(9); // along row 5
  const gone = game.demolish(6, 5);
  expect(gone.ok).toBe(true);
  runSeconds(game, 0.2);
  expect(game.sim.walkers.rerouted).toBe(1);
  expect(game.sim.walkers.list.get(v.id).path.length).toBeGreaterThan(first);
  runSeconds(game, 10);
  expect(v.at).toBe(farm.id);
  expect(game.sim.walkers.gaveUp).toBe(0);
});

test("a road cut with no way round makes the walker wait, then give up and go home", () => {
  const game = createGame({ testMap: true });
  rich(game);
  roadRow(game, 5, 2, 8);
  const house = put(game, "house", 2, 4);
  put(game, "farm", 7, 3);
  const v = game.sim.people.moveIn(house.id);
  game.sim.people.assign();
  runToDayFraction(game, 0.06);
  runSeconds(game, 1);
  expect(game.sim.walkers.list.has(v.id)).toBe(true);
  expect(game.demolish(6, 5).ok).toBe(true);
  runSeconds(game, 5);
  const w = game.sim.walkers.list.get(v.id);
  expect(w.blocked).toBe(true);
  // joining the road again lets it go on
  expect(game.placeRoads([[6, 5]]).ok).toBe(true);
  runSeconds(game, 5);
  expect(v.at).not.toBe(house.id);
  // and a cut for good: patienceSeconds later it is back home and without a job
  runToDayFraction(game, 0.9);
  runToDayFraction(game, 0.06);
  runSeconds(game, 1);
  expect(game.demolish(6, 5).ok).toBe(true);
  runSeconds(game, game.data.sim.patienceSeconds + 1);
  expect(game.sim.walkers.gaveUp).toBeGreaterThanOrEqual(1); // villagers born meanwhile took the same road
  expect(v.at).toBe(house.id);
  expect(v.state).toBe("inside");
  expect(v.job).toBe(0);
});

test("production: a farm fills its outbox and stops when nobody collects, in winter it does not grow at all", () => {
  const { game, ids } = smallTown({ parts: ["farm"] });
  fillHouses(game);
  runDays(game, 8);
  runToDayFraction(game, 0.3);
  runSeconds(game, 3);
  const rt = game.sim.rt.get(ids.farm);
  expect(rt.cycles).toBeGreaterThan(0);
  expect(rt.outbox.grain).toBe(16); // outboxCycles 2 x 8 grain, no warehouse to carry it away
  expect(rt.stall).toBe("output_full");
  // winter: nothing grows
  const w = createGame({ testMap: true });
  rich(w);
  roadRow(w, 5, 1, 4);
  const house = put(w, "house", 2, 4);
  const farm = put(w, "farm", 5, 3);
  roadRow(w, 5, 5, 6);
  w.sim.people.moveIn(house.id);
  w.sim.people.moveIn(house.id);
  w.clock.setDay(30);
  runToDayFraction(w, 0.3);
  runSeconds(w, 5);
  expect(w.clock.date().season).toBe("winter");
  expect(w.sim.rt.get(farm.id).stall).toBe("season");
  expect(w.sim.rt.get(farm.id).cycles).toBe(0);
});

test("the production chain: fish, grain and flour go through a warehouse to the market, nothing is lost", () => {
  const { game, ids } = smallTown();
  fillHouses(game);
  const before = inventory(game);
  runDays(game, 12);
  const l = game.sim.ledger;
  for (const g of game.data.goodIds) expect(drift(game, before, g)).toBe(0);
  expect(l.produced.grain).toBeGreaterThan(0);
  expect(l.produced.fish).toBeGreaterThan(0);
  expect(l.produced.smoked_fish).toBeGreaterThan(0);
  expect(l.produced.bread).toBeGreaterThan(0);
  expect(l.eaten.bread + l.eaten.smoked_fish + l.eaten.fish).toBeGreaterThan(0);
  expect(game.sim.logistics.errands).toBeGreaterThan(0);
  // the market sold, and the sales are money in the bank
  expect(l.sales).toBeGreaterThan(0);
  const market = game.sim.rt.get(ids.market);
  expect(Object.values(market.shelf).reduce((a, b) => a + b, 0)).toBeGreaterThanOrEqual(0);
});

test("carriers are the warehouse's staff, and without a warehouse nothing moves", () => {
  const { game, ids } = smallTown({ parts: ["farm", "market", "bakery"] });
  fillHouses(game);
  runDays(game, 6);
  expect(game.sim.logistics.errands).toBe(0);
  expect(game.sim.rt.get(ids.market).shelf.bread || 0).toBe(0);
  const w = smallTown({ parts: ["farm", "market", "bakery", "warehouse"] });
  fillHouses(w.game);
  runDays(w.game, 6);
  expect(w.game.sim.logistics.errands).toBeGreaterThan(0);
  const carriers = w.game.sim.rt.get(w.ids.warehouse).staff;
  expect(carriers).toHaveLength(3);
});

test("wages and upkeep are paid at the start of every day, as far as the coins go", () => {
  const { game } = smallTown();
  fillHouses(game);
  game.sim.people.assign();
  const sum = game.sim.summary();
  let upkeep = 0;
  for (const rt of game.sim.rt.values()) upkeep += game.data.buildings[rt.type].upkeep || 0;
  const paid = [];
  game.events.on("payday", (e) => paid.push(e));
  const coins = game.economy.coins;
  runDays(game, 1);
  expect(paid).toHaveLength(1);
  expect(paid[0].wages).toBe(sum.employed * game.data.sim.wagePerDay);
  expect(paid[0].upkeep).toBe(upkeep);
  expect(game.economy.coins).toBeLessThanOrEqual(coins - paid[0].wages - paid[0].upkeep + game.sim.ledger.sales);
  expect(game.sim.ledger.wages).toBe(paid[0].wages);
  // broke: not enough coins pays what it can, the rest is owed and the buildings slow down
  runToDayFraction(game, 0.99);
  game.economy.apply({ coins: -game.economy.coins + 3 }, "test");
  runSeconds(game, 1);
  expect(paid).toHaveLength(2);
  expect(paid[1].broke).toBe(true);
  expect(game.sim.broke).toBe(true);
  expect(game.economy.coins).toBeGreaterThanOrEqual(0);
  expect(game.sim.ledger.wagesShort).toBeGreaterThan(0);
});

test("without a market the villagers go hungry and leave", () => {
  const { game, ids } = smallTown({ parts: ["farm"] });
  fillHouses(game);
  const left = [];
  let arrived = 0;
  game.events.on("villager.left", (e) => left.push(e.reason));
  game.events.on("villager.arrived", () => arrived++);
  const start = game.sim.people.villagers.size;
  runDays(game, 14);
  expect(left.length).toBeGreaterThan(0);
  expect(left.every((r) => r === "starved")).toBe(true);
  // the founders rule brings new villagers while the town has fewer than data.sim.founders: they starve in their turn
  expect(game.sim.people.villagers.size).toBe(start + arrived - left.length);
  void ids;
});

test("with a market and food nobody starves and the town keeps its people", () => {
  const { game, ids } = smallTown();
  game.clock.setDay(10); // summer: the grain grows at full speed (in spring it takes about 10 days to reach the bakery)
  for (let i = 0; i < 6; i++) game.sim.people.moveIn(ids.houses[i < 4 ? 0 : 1]);
  const left = [];
  game.events.on("villager.left", (e) => left.push(e.reason));
  runDays(game, 25);
  expect(left).toEqual([]);
  expect(game.sim.people.villagers.size).toBeGreaterThanOrEqual(6);
  expect(game.sim.summary().hungry).toBeLessThan(3);
  expect(game.sim.ledger.eaten.bread + game.sim.ledger.eaten.fish + game.sim.ledger.eaten.smoked_fish).toBeGreaterThan(20);
});

test("demolishing a home sends its villagers away, a workplace frees its staff, a warehouse drops the errands", () => {
  const { game, ids } = smallTown();
  fillHouses(game);
  const before = inventory(game);
  runDays(game, 4);
  const left = [];
  game.events.on("villager.left", (e) => left.push(e.reason));
  const size = game.sim.people.villagers.size;
  game.demolish(1, 4); // a house with 4 villagers
  expect(left).toEqual(["home_lost", "home_lost", "home_lost", "home_lost"]);
  expect(game.sim.people.villagers.size).toBe(size - 4);
  runToDayFraction(game, 0.3);
  game.demolish(7, 6); // the warehouse, probably with carriers out
  expect(game.sim.rt.has(ids.warehouse)).toBe(false);
  runDays(game, 2);
  for (const v of game.sim.people.villagers.values()) expect(v.trip).toBeNull();
  for (const g of FLOW_GOODS) expect(drift(game, before, g)).toBe(0);
});

test("the same town gives the same state hash, a different layout a different one", () => {
  const run = () => {
    const { game } = smallTown();
    fillHouses(game);
    runDays(game, 6);
    return game.hash();
  };
  const a = run();
  expect(run()).toBe(a);
  const { game } = smallTown({ parts: ["farm", "market", "bakery", "warehouse"] });
  fillHouses(game);
  runDays(game, 6);
  expect(game.hash()).not.toBe(a);
});

test("undo of a building also takes it out of the simulation", () => {
  const { game, ids } = smallTown();
  expect(game.sim.rt.has(ids.warehouse)).toBe(true);
  expect(game.undo().ok).toBe(true);
  expect(game.sim.rt.has(ids.warehouse)).toBe(false);
  expect(game.redo().ok).toBe(true);
  expect(game.sim.rt.has(ids.warehouse)).toBe(true);
});
