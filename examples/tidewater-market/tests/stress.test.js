// The stress town (scripts/game/stress_town.js): 500+ villagers walking at once. The simulation half runs here without the
// engine; the scene half (scenes/stress.scene.json) draws it and reports what the walkers cost.
import { test, expect, game } from "factoria:test";
import { createGame } from "../scripts/game/state.js";
import { buildStressTown, stressRows } from "../scripts/game/stress_town.js";
import { navFinder } from "../scripts/game/nav_backend.js";
import { storage } from "factoria";
import { getData } from "../scripts/game/data.js";
import { writeEntry, loadEntry, entryBytes } from "../scripts/game/save_store.js";

function crowd(villagers = 640) {
  const state = createGame({ rows: stressRows(60) });
  const info = buildStressTown(state, { villagers });
  state.clock.setSpeed(0);
  return { state, info };
}

test("stress: the town holds 640 villagers and over 500 of them are on the roads at the same time", () => {
  const { state, info } = crowd();
  expect(info.villagers).toBe(640);
  expect(info.markets).toBe(4);
  const clock = state.clock;
  let peak = 0;
  // one morning at the fixed step: the commute and the walk to the market
  for (let i = 0; i < clock.ticksPerDay * 0.5; i++) {
    clock.tick(clock.step);
    peak = Math.max(peak, state.sim.walkers.count);
  }
  console.log("stress: villagers", info.villagers, "houses", info.houses, "workplaces", info.workplaces, "peak walkers", peak, "gave up", state.sim.walkers.gaveUp);
  expect(peak).toBeGreaterThanOrEqual(500);
  expect(state.sim.walkers.gaveUp).toBe(0);
});

test("stress scene: the crowd is drawn with a handful of draw calls", () => {
  game.load("scenes/stress.scene.json");
  game.step(1); // onStart queues the steps
  const ctl = game.find("controller").behaviour;
  // the town is laid out one small step per frame (no frame may run over the 2 s script limit on a slow runner)
  for (let i = 0; i < 200 && ctl.stressSteps.length; i++) game.step(1);
  const state = ctl.state;
  expect(ctl.stressSteps.length).toBe(0);
  expect(state.sim.people.villagers.size).toBe(640);
  let peak = 0;
  for (let i = 0; i < 400 && peak < 500; i++) {
    game.step(1);
    peak = Math.max(peak, state.sim.walkers.count);
  }
  expect(peak).toBeGreaterThanOrEqual(500);
  const stats = game.renderStats();
  console.log("stress scene: walkers", state.sim.walkers.count, "drawCalls", stats.drawCalls, "sprites", stats.sprites);
  // walkers and buildings are regions of one atlas: they batch, so the draw calls do not grow with the crowd
  expect(stats.drawCalls).toBeLessThan(60);
});

test("walker routes: nav.findTilePath on the kept grid finds the same ways as the flow fields (the fields are the shortest)", () => {
  const { state } = crowd(160);
  const net = state.sim.net;
  const houses = state.list("house").slice(0, 12);
  const market = state.list("market")[0];
  const withFields = houses.map((h) => net.routeBuildings(h, market)?.length ?? null);
  net.setFinder(navFinder(net));
  const withNav = houses.map((h) => net.routeBuildings(h, market)?.length ?? null);
  net.setFinder(null);
  for (let i = 0; i < houses.length; i++) {
    expect(withFields[i]).not.toBe(null);
    expect(withNav[i]).not.toBe(null);
    expect(withNav[i]).toBeGreaterThanOrEqual(withFields[i]);
  }
});

test("stress: saving and loading the 640-villager town is exact and its cost is printed", () => {
  const { state } = crowd();
  for (let i = 0; i < state.clock.ticksPerDay * 0.25; i++) state.clock.tick(state.clock.step); // walkers on the roads
  const now = () => (typeof performance !== "undefined" ? performance.now() : Date.now());
  storage.clear();
  const t0 = now();
  const res = writeEntry(1, "manual", state, { scenario: "sandbox", name: "Stress", playSeconds: 1 });
  const t1 = now();
  expect(res.ok).toBe(true);
  const bytes = entryBytes(1, "manual");
  const back = loadEntry(1, "manual", getData());
  const t2 = now();
  expect(back.ok).toBe(true);
  expect(back.state.hash()).toBe(state.hash());
  console.log("stress save: bytes", bytes, "write ms", (t1 - t0).toFixed(1), "read+restore ms", (t2 - t1).toFixed(1), "walkers", state.sim.walkers.count);
});
