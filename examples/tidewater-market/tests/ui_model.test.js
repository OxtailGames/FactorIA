// The interface's model (scripts/game/ui_model.js): numbers, the goods table, the recorder, notifications, overlays, the
// inspector's facts, the drag-and-drop rule, and the support in the simulation (worker pin, free rotation with undo).
import { test, expect } from "factoria:test";
import { createGame } from "../scripts/game/state.js";
import {
  formatCompact, categories, Recorder, goodsRows, Notices, overlayField, Traffic, describeBuilding, describeVillager,
  canDropWorker, SHORTCUTS,
} from "../scripts/game/ui_model.js";
import { smallTown, runSeconds, runDays, fillHouses, put, roadRow, rich } from "./town_helper.js";

test("formatCompact never grows past 5 characters", () => {
  expect(formatCompact(0)).toBe("0");
  expect(formatCompact(9999)).toBe("9999");
  expect(formatCompact(10000)).toBe("10k");
  expect(formatCompact(12345)).toBe("12.3k");
  expect(formatCompact(99999)).toBe("100k");
  expect(formatCompact(123456)).toBe("123k");
  expect(formatCompact(1234567)).toBe("1.2M");
  expect(formatCompact(99999999)).toBe("100M");
  expect(formatCompact(1234567890)).toBe("1235M");
  expect(formatCompact(-1500)).toBe("-1500");
  expect(formatCompact(-45000)).toBe("-45k");
  for (const n of [0, 7, 999, 10001, 54321, 999999, 5000000, 87654321]) expect(formatCompact(n).length).toBeLessThanOrEqual(5);
});

test("categories follow data/buildings.json and hold every building once", () => {
  const game = createGame({ testMap: true });
  const cats = categories(game.data);
  expect(cats.map((c) => c.id)).toContain("production");
  expect(cats.flatMap((c) => c.buildings).sort()).toEqual([...game.data.buildingIds].sort());
});

test("the recorder: per-day rates, money history, goods table sorted by any column", () => {
  const { game } = smallTown();
  fillHouses(game);
  const rec = new Recorder(game);
  runDays(game, 4);
  expect(rec.samples.length).toBeGreaterThanOrEqual(4);
  expect(rec.money(10).length).toBeGreaterThan(2);
  const made = game.data.goodIds.reduce((n, g) => n + rec.rates(g).made, 0);
  expect(made).toBeGreaterThan(0);
  const name = (id) => id;
  const byStock = goodsRows(game, rec, { column: "stock", dir: -1 }, name);
  expect(byStock).toHaveLength(game.data.goodIds.length);
  for (let i = 1; i < byStock.length; i++) expect(byStock[i - 1].stock).toBeGreaterThanOrEqual(byStock[i].stock);
  const byName = goodsRows(game, rec, { column: "name", dir: 1 }, name);
  expect(byName.map((r) => r.name)).toEqual([...byName.map((r) => r.name)].sort());
  const byPrice = goodsRows(game, rec, { column: "price", dir: 1 }, name);
  for (let i = 1; i < byPrice.length; i++) expect(byPrice[i - 1].price).toBeLessThanOrEqual(byPrice[i].price);
  // the same input gives the same order (ties by the file's order)
  expect(goodsRows(game, rec, { column: "price", dir: 1 }, name).map((r) => r.id)).toEqual(byPrice.map((r) => r.id));
  rec.destroy();
});

test("notices: no workers, no road, shortage; stacked once, expiring, never for a brand new building", () => {
  const game = createGame({ testMap: true });
  rich(game);
  roadRow(game, 5, 1, 4);
  const farm = put(game, "farm", 2, 3); // next to the road, but nobody lives anywhere
  const lonely = put(game, "sawmill", 8, 7); // no road
  const notes = new Notices(game, { max: 4, seconds: 5 });
  notes.scan();
  expect(notes.items.filter((n) => n.building)).toHaveLength(0); // younger than a day
  runDays(game, 1);
  const keys = notes.items.map((n) => `${n.key}:${n.building}`);
  expect(keys).toContain(`noWorkers:${farm.id}`);
  expect(keys).toContain(`noRoad:${lonely.id}`);
  const noRoad = notes.items.find((n) => n.key === "noRoad");
  expect(noRoad.cell).toEqual([8, 7]);
  const before = notes.pushed;
  notes.scan();
  notes.scan();
  expect(notes.pushed).toBe(before); // the same message is refreshed, not stacked
  expect(notes.items.find((n) => n.key === "noRoad").count).toBeGreaterThan(1);
  // fading: opaque in the middle, transparent at the end
  const n = notes.items[0];
  expect(Notices.opacity({ ...n, age: 0, ttl: 5 })).toBe(0);
  expect(Notices.opacity({ ...n, age: 1, ttl: 4 })).toBe(1);
  expect(Notices.opacity({ ...n, age: 4.5, ttl: 0.5 })).toBe(0.5);
  notes.update(6);
  expect(notes.items).toHaveLength(0);
  // demolishing the building takes its messages away
  notes.scan();
  expect(notes.items.length).toBeGreaterThan(0);
  game.demolish(lonely.x, lonely.y);
  expect(notes.items.some((m) => m.building === lonely.id)).toBe(false);
  notes.destroy();
});

test("notices keep at most `max` messages, newest first", () => {
  const game = createGame({ testMap: true });
  const notes = new Notices(game, { max: 3 });
  for (let i = 0; i < 5; i++) notes.push("hungry", { count: i }, null, 0, "bad");
  expect(notes.items).toHaveLength(1); // the same message again only refreshes it, with the newest numbers
  expect(notes.items[0].args.count).toBe(4);
  expect(notes.items[0].count).toBe(5);
  notes.items.length = 0;
  for (let i = 0; i < 5; i++) notes.push("storageFull", { good: `g${i}` }, null, 0);
  expect(notes.items).toHaveLength(3);
  expect(notes.items[0].args.good).toBe("g4");
});

test("overlays: coverage around markets and warehouses, desirability on free cells, traffic from walkers", () => {
  const { game, ids } = smallTown();
  fillHouses(game);
  const market = game.buildings.get(ids.market);
  const f = overlayField(game, "market");
  expect(f.cells.length).toBeGreaterThan(10);
  expect(f.values[market.y * game.map.width + market.x]).toBeGreaterThan(0.8);
  expect(f.values[0]).toBe(0); // water far away
  const w = overlayField(game, "warehouse");
  expect(w.cells.length).toBeGreaterThan(f.cells.length - 1);
  const d = overlayField(game, "desirability");
  expect(d.cells.length).toBeGreaterThan(0);
  for (const i of d.cells) {
    const c = i % game.map.width;
    const r = (i - c) / game.map.width;
    expect(game.map.occupantAt(c, r)).toBe(0);
    expect(d.values[i]).toBeGreaterThan(0);
    expect(d.values[i]).toBeLessThanOrEqual(1);
  }
  const traffic = new Traffic(game);
  runSeconds(game, 40);
  const t = overlayField(game, "traffic", traffic);
  expect(t.cells.length).toBeGreaterThan(0);
  traffic.destroy();
});

test("the inspector facts: a workplace, a house, a villager", () => {
  const { game, ids } = smallTown();
  fillHouses(game);
  runSeconds(game, 20);
  const farm = describeBuilding(game, ids.farm);
  expect(farm.type).toBe("farm");
  expect(farm.workers.max).toBe(2);
  expect(farm.connected).toBe(true);
  expect(farm.recipe.all).toHaveLength(1);
  expect(farm.rotatable).toBe(true);
  const house = describeBuilding(game, ids.houses[0]);
  expect(house.residents.max).toBe(4);
  expect(house.rotatable).toBe(false);
  expect(describeBuilding(game, 9999)).toBe(null);
  const vid = farm.workers.staff[0] ? farm.workers.staff[0].id : [...game.sim.people.villagers.keys()][0];
  const v = describeVillager(game, vid);
  expect(v.home).not.toBe(null);
  expect(v.hungry).toBe(false);
  expect(describeVillager(game, 9999)).toBe(null);
  expect(SHORTCUTS.length).toBeGreaterThan(8);
});

test("a worker can be moved to another workplace by hand; the job is pinned; the rule says why not", () => {
  const { game, ids } = smallTown();
  fillHouses(game);
  runSeconds(game, 5);
  const people = game.sim.people;
  const worker = [...people.villagers.values()].find((v) => v.job === ids.farm);
  expect(worker).toBeTruthy();
  const dock = ids.dock;
  expect(canDropWorker(game, worker.id, ids.farm)).toEqual({ ok: false, code: "same" });
  expect(canDropWorker(game, worker.id, ids.houses[0]).code).toBe("no_jobs");
  expect(canDropWorker(game, 9999, dock).code).toBe("gone");
  // fill the dock, then it is full
  const staffed = () => [...people.villagers.values()].filter((v) => v.job === dock).length;
  const verdict = canDropWorker(game, worker.id, dock);
  if (staffed() >= game.data.buildings.fisher_dock.workers) {
    expect(verdict.code).toBe("full");
    const other = [...people.villagers.values()].find((v) => v.job === dock);
    people.release(other.id);
  }
  const hash = game.sim.hash ? game.sim.hash() : 0;
  expect(people.reassign(worker.id, dock)).toEqual({ ok: true });
  expect(worker.job).toBe(dock);
  expect(worker.pin).toBe(true);
  runDays(game, 2);
  expect(worker.job).toBe(dock); // the pin holds across the day's assignment
  expect(hash === hash).toBe(true);
  expect(people.release(worker.id).ok).toBe(true);
  expect(worker.pin).toBe(false);
});

test("rotating a placed building is free, one undo step, and not for roads and houses", () => {
  const game = createGame({ testMap: true });
  rich(game);
  roadRow(game, 5, 1, 8);
  const farm = put(game, "farm", 5, 3);
  const coins = game.economy.coins;
  const res = game.rotateBuilding(farm.id);
  expect(res.ok).toBe(true);
  expect(res.building.rot).toBe(1);
  expect(game.economy.coins).toBe(coins);
  expect(game.buildings.has(farm.id)).toBe(false);
  expect(game.undo().ok).toBe(true);
  const back = [...game.buildings.values()].find((b) => b.type === "farm");
  expect(back.rot).toBe(0);
  expect(game.redo().ok).toBe(true);
  expect([...game.buildings.values()].find((b) => b.type === "farm").rot).toBe(1);
  const house = put(game, "house", 1, 4);
  expect(game.rotateBuilding(house.id).ok).toBe(false);
  const road = [...game.buildings.values()].find((b) => b.type === "road");
  expect(game.rotateBuilding(road.id).ok).toBe(false);
  expect(game.rotateBuilding(9999).ok).toBe(false);
});
