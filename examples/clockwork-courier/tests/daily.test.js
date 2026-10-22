// P3: the daily route (scripts/daily.js): the same route for the same date, another for the next day, only on levels the
// player has open, the parcels really move, the finish records its own best time and sends daily_route_finished, and
// it never touches the stars of the level. Dates are chosen with game.setDate (the engine's game.today() reads them).
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene, session, storage } from "factoria";
import * as progress from "../scripts/progress.js";
import * as daily from "../scripts/daily.js";
import * as clock from "../scripts/clock.js";
import { LEVELS } from "../scripts/levels.js";

const ALL = LEVELS.map((l) => l.id);
const win = (id, stars, time = 40) => progress.record(id, { time, springLeft: 30, stars });
const PARCELS = ["parcel_1", "parcel_bonus_1"];
const spots = () => PARCELS.map((id) => game.find(id).position).map((p) => [p.x, p.y, p.z].map((v) => Math.round(v * 100) / 100));

describe("daily route", () => {
  beforeEach(() => {
    game.setStorageText(null);
    storage.remove("progress");
    session.daily = null;
    session.nextScene = null;
    game.setDate("2026-10-22");
  });

  test("the clock gives the engine's calendar date, and tests choose it with game.setDate", () => {
    game.setDate("2026-03-14");
    expect(clock.today()).toBe("2026-03-14");
    game.setDate("2026-10-22");
    expect(clock.today()).toBe("2026-10-22");
    expect(clock.addDays("2026-10-31", 1)).toBe("2026-11-01");
    expect(clock.addDays("2026-12-31", 1)).toBe("2027-01-01");
  });

  test("the same date always gives the same route", () => {
    const a = daily.routeFor("2026-10-22", ALL);
    const b = daily.routeFor("2026-10-22", ALL);
    expect(a).toEqual(b);
    expect(a.date).toBe("2026-10-22");
  });

  test("the next day gives a different route", () => {
    const a = daily.routeFor("2026-10-22", ALL);
    const b = daily.routeFor(clock.addDays("2026-10-22", 1), ALL);
    expect(JSON.stringify([a.level, a.order])).not.toBe(JSON.stringify([b.level, b.order]));
    // and over a month the routes are not all the same level
    const levels = new Set();
    for (let i = 0; i < 30; i++) levels.add(daily.routeFor(clock.addDays("2026-10-01", i), ALL).level);
    expect(levels.size).toBeGreaterThan(2);
  });

  test("the parcels are always laid out differently from the level's normal layout", () => {
    for (let i = 0; i < 40; i++) {
      const r = daily.routeFor(clock.addDays("2026-01-01", i), ALL);
      const slots = LEVELS.find((l) => l.id === r.level);
      expect(r.order.length).toBe(slots.parcels + slots.optionalParcels);
      expect([...r.order].sort()).toEqual(r.order.map((_, k) => k)); // a permutation
      expect(r.order.every((v, k) => v === k)).toBe(false);
    }
  });

  test("a new player only gets the first level; unlocking more widens the pool", () => {
    for (let i = 0; i < 30; i++) expect(daily.routeFor(clock.addDays("2026-10-01", i), daily.openLevels()).level).toBe("rooftops_1");
    win("rooftops_1", 1);
    win("rooftops_2", 1);
    expect(daily.openLevels()).toEqual(["rooftops_1", "rooftops_2", "rooftops_3"]);
  });

  test("today's route is saved when first asked: unlocking a level later does not change it", () => {
    win("rooftops_1", 1);
    const first = daily.current();
    expect(progress.dailyRoute()).toEqual(first);
    win("rooftops_2", 3);
    win("rooftops_3", 3);
    expect(daily.current()).toEqual(first);
  });

  test("a new day picks a new route and saves it", () => {
    for (const id of ["rooftops_1", "rooftops_2", "rooftops_3"]) win(id, 3); // a player with four open levels: a wide pool
    const today = daily.current();
    game.setDate("2026-10-23");
    const tomorrow = daily.current();
    expect(tomorrow.date).toBe("2026-10-23");
    expect(JSON.stringify([today.level, today.order])).not.toBe(JSON.stringify([tomorrow.level, tomorrow.order]));
    expect(progress.dailyRoute().date).toBe("2026-10-23");
  });

  test("the parcels of the level move to the route's layout, the same way every run", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    const normal = spots();
    const route = daily.routeFor("2026-10-22", ["rooftops_1"]);
    daily.start(route);
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    const moved = spots();
    expect(moved).not.toEqual(normal);
    expect([...moved].sort()).toEqual([...normal].sort()); // the same two places, swapped
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    expect(spots()).toEqual(moved);
  });

  test("a normal run (no daily route) leaves the parcels where the scene has them", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    const normal = spots();
    daily.clear();
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    expect(spots()).toEqual(normal);
  });

  test("finishing records the day's own best time, sends daily_route_finished, and leaves the stars alone", () => {
    const route = daily.routeFor("2026-10-22", ["rooftops_1"]);
    daily.start(route);
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    const log = [];
    game.world.on("daily_route_finished", (d) => log.push(d));
    game.find("level").behaviour.onDelivery("door", 1, 0); // the required parcel: the level is won
    game.step(150);
    expect(log.length).toBe(1);
    expect(log[0]).toMatchObject({ date: "2026-10-22", level: "rooftops_1" });
    expect(log[0].time).toBeGreaterThanOrEqual(0);
    expect(progress.dailyTime("2026-10-22").level).toBe("rooftops_1");
    expect(progress.resultFor("rooftops_1")).toBeNull(); // no stars for a daily run
    expect(progress.totalStars()).toBe(0);
    expect(game.find("results_panel").active).toBe(true);
    expect(game.find("results_heading").get("Text").text).toContain("Daily route done");
    expect(game.find("results_next").active).toBe(false);
  });

  test("the daily best only improves", () => {
    expect(progress.recordDaily("2026-10-22", "rooftops_1", 50)).toBe(true);
    expect(progress.recordDaily("2026-10-22", "rooftops_1", 60)).toBe(false);
    expect(progress.recordDaily("2026-10-22", "rooftops_1", 40)).toBe(true);
    expect(progress.dailyTime("2026-10-22").time).toBe(40);
    expect(progress.dailyTime("2026-10-23")).toBeNull();
  });

  test("the level select starts today's route and shows the time once it is done", () => {
    progress.setName("Ana");
    game.load("scenes/level_select.scene.json");
    game.step(5);
    expect(game.find("select_daily").get("Button").text).toBe("Daily route");
    game.click("select_daily");
    const route = session.daily;
    expect(route.active).toBe(true);
    expect(route.date).toBe("2026-10-22");
    expect(session.nextScene).toBe(LEVELS.find((l) => l.id === route.level).scene);
    expect(scene.current).toBe("scenes/loading.scene.json");
    progress.recordDaily("2026-10-22", route.level, 33.3);
    game.load("scenes/level_select.scene.json");
    game.step(5);
    expect(game.find("select_daily").get("Button").text).toBe("Daily route: 33.3 s");
  });

  test("the title screen clears a daily route left over from a run", () => {
    session.daily = { date: "2026-10-22", level: "rooftops_1", order: [1, 0], active: true };
    game.load("scenes/main.scene.json");
    game.step(5);
    expect(daily.active()).toBeNull();
  });
});
