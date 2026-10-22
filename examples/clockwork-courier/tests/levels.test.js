// Every level of the player's list, played by the waypoint bot (tests/helpers/routes.js): the main route delivers every
// parcel, the expert shortcut (where a level has one) wins too and is not slower. Also checks the shape of the list.
import { test, describe, expect, game } from "factoria:test";
import { storage } from "factoria";
import { Autoplay } from "./helpers/autoplay.js";
import { ROUTES } from "./helpers/routes.js";
import { LEVELS, TEST_LEVELS, byId } from "../scripts/levels.js";
import * as progress from "../scripts/progress.js";

function record(names) {
  const log = [];
  for (const n of names) game.world.on(n, (data) => log.push({ name: n, data }));
  return log;
}

function play(level, route) {
  storage.remove("progress");
  game.load(level.scene);
  game.step(10);
  const log = record(["parcel_picked", "parcel_delivered", "level_completed", "level_failed", "spring_wound", "checkpoint_reached", "courier_caught"]);
  const bot = new Autoplay(game, { maxFrames: 1500 });
  const r = bot.run(route);
  game.step(120);
  return { r, log, bot };
}

describe("the level list", () => {
  test("six levels in two districts; the test scenes are not in the player's list", () => {
    expect(LEVELS.map((l) => l.id)).toEqual(["rooftops_1", "rooftops_2", "rooftops_3", "market_1", "market_2", "market_3"]);
    expect(LEVELS.filter((l) => l.district === "rooftops").length).toBe(3);
    expect(LEVELS.filter((l) => l.district === "market").length).toBe(3);
    expect(LEVELS.some((l) => l.id === "test_yard" || l.id === "test_arena")).toBe(false);
    expect(byId("test_yard")).not.toBeNull();
    expect(byId("test_arena")).not.toBeNull();
    expect(TEST_LEVELS.length).toBe(2);
  });

  test("every level has a main route, a shortcut and a scene", () => {
    for (const l of LEVELS) {
      expect(ROUTES[l.id]).toBeDefined();
      expect(ROUTES[l.id].main.length).toBeGreaterThan(10);
      expect(ROUTES[l.id].shortcut).not.toBeNull();
    }
  });
});

for (const level of LEVELS) {
  describe(level.id, () => {
    test("the bot delivers every parcel (optional ones too) and wins with at least one star", () => {
      const { r, log } = play(level, ROUTES[level.id].main);
      expect(JSON.stringify(r)).toContain('"reached":true');
      const names = log.map((e) => e.name);
      expect(names).not.toContain("level_failed");
      expect(names).not.toContain("courier_caught"); // the bot slips past the dogs (sneaking where a route says walk)
      const delivered = log.filter((e) => e.name === "parcel_delivered").pop().data;
      expect(delivered.delivered).toBe(level.parcels);
      expect(delivered.optional).toBe(level.optionalParcels);
      expect(names.filter((n) => n === "level_completed").length).toBe(1);
      const done = log.find((e) => e.name === "level_completed").data;
      expect(done.level).toBe(level.id);
      expect(done.stars).toBeGreaterThanOrEqual(1);
      expect(done.springLeft).toBeGreaterThan(0);
      expect(progress.resultFor(level.id).stars).toBeGreaterThanOrEqual(1);
      expect(game.find("results_panel").active).toBe(true);
    });

    test("the expert shortcut wins too", () => {
      const main = play(level, ROUTES[level.id].main);
      const fast = play(level, ROUTES[level.id].shortcut);
      expect(JSON.stringify(fast.r)).toContain('"reached":true');
      expect(fast.log.map((e) => e.name)).toContain("level_completed");
      // Not slower than the main route, give or take 5 s: the rope bridge and the seesaw of rooftops_3 are physics, and
      // the main route takes 2000..2800 frames depending on which tests ran before it in the same process (FB-0033).
      expect(fast.r.frames).toBeLessThanOrEqual(main.r.frames + 300);
    });
  });
}
