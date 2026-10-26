// The stress town (scripts/game/stress_town.js): 500+ villagers walking at once. The simulation half runs here without the
// engine; the scene half (scenes/stress.scene.json) draws it and reports what the walkers cost.
import { test, expect, game } from "factoria:test";
import { createGame } from "../scripts/game/state.js";
import { buildStressTown, stressRows } from "../scripts/game/stress_town.js";
import { navFinder } from "../scripts/game/nav_backend.js";

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
  game.step(20); // the town is laid out one step per frame
  const ctl = game.find("controller").behaviour;
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

test("walker routes: the engine's nav.findTilePath finds the same ways as the distance fields (the fields are the shortest)", () => {
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
