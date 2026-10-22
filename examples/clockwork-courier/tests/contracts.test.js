// The contracts later packages build on: the level list (scripts/levels.js), saved progress (scripts/progress.js) and
// the event names (scripts/events.js). Changing any of these is a breaking change for the districts that use them.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { storage } from "factoria";
import * as levels from "../scripts/levels.js";
import * as progress from "../scripts/progress.js";
import { EVENTS } from "../scripts/events.js";

describe("levels.js", () => {
  test("every level has the documented fields", () => {
    expect(levels.LEVELS.length).toBeGreaterThanOrEqual(1);
    for (const l of levels.LEVELS) {
      for (const k of ["id", "name", "nameKey", "district", "scene"]) expect(typeof l[k]).toBe("string");
      for (const k of ["spring", "parTime", "parcels"]) expect(typeof l[k]).toBe("number");
      expect(l.scene).toMatch(/^scenes\/.*\.scene\.json$/);
      expect(l.spring).toBeGreaterThan(l.parTime);
    }
  });

  test("ids are unique and the scenes load", () => {
    const ids = levels.LEVELS.map((l) => l.id);
    expect(new Set(ids).size).toBe(ids.length);
    for (const l of levels.LEVELS) {
      game.load(l.scene);
      game.step(2);
      expect(game.find("level").get("Script").props.levelId).toBe(l.id);
    }
  });

  test("helpers", () => {
    expect(levels.first().id).toBe("test_yard");
    expect(levels.byId("test_yard").scene).toBe("scenes/test_yard.scene.json");
    expect(levels.byId("nope")).toBeNull();
    expect(levels.byScene("scenes/test_yard.scene.json").id).toBe("test_yard");
    expect(levels.next("test_yard")).toBeNull();
    expect(levels.inDistrict("test").length).toBe(1);
    expect(levels.inDistrict("nowhere")).toEqual([]);
  });

  test("every level name has a translation in every language", async () => {
    const { i18n } = await import("factoria");
    for (const lang of ["en", "es"]) {
      i18n.setLanguage(lang);
      for (const l of levels.LEVELS) expect(i18n.t(l.nameKey)).not.toBe(l.nameKey);
    }
    i18n.setLanguage("en");
  });
});

describe("progress.js", () => {
  beforeEach(() => storage.remove("progress"));

  test("starts empty", () => {
    expect(progress.resultFor("test_yard")).toBeNull();
    expect(progress.load()).toEqual({ version: 1, results: {} });
  });

  test("record keeps the first result and returns true", () => {
    expect(progress.record("test_yard", { time: 31.234, springLeft: 28.7, stars: 2 })).toBe(true);
    expect(progress.resultFor("test_yard")).toEqual({ time: 31.23, springLeft: 28.7, stars: 2 });
  });

  test("a worse result does not replace a better one", () => {
    progress.record("test_yard", { time: 30, springLeft: 30, stars: 3 });
    expect(progress.record("test_yard", { time: 20, springLeft: 40, stars: 2 })).toBe(false);
    expect(progress.resultFor("test_yard").stars).toBe(3);
  });

  test("the same stars with a better time replace it", () => {
    progress.record("test_yard", { time: 30, springLeft: 30, stars: 3 });
    expect(progress.record("test_yard", { time: 25, springLeft: 35, stars: 3 })).toBe(true);
    expect(progress.resultFor("test_yard").time).toBe(25);
  });

  test("the first level is always unlocked, an unknown one never", () => {
    expect(progress.isUnlocked("test_yard")).toBe(true);
    expect(progress.isUnlocked("nope")).toBe(false);
  });

  test("survives a damaged save", () => {
    game.setStorageText('{"progress": 5}');
    expect(progress.load()).toEqual({ version: 1, results: {} });
    game.setStorageText(null);
  });

  test("reset forgets everything", () => {
    progress.record("test_yard", { time: 30, springLeft: 30, stars: 1 });
    progress.reset();
    expect(progress.resultFor("test_yard")).toBeNull();
  });
});

describe("events.js", () => {
  test("the event names are the documented ones", () => {
    expect(Object.values(EVENTS).sort()).toEqual(
      [
        "checkpoint_reached",
        "courier_caught",
        "game_paused",
        "game_resumed",
        "level_completed",
        "level_failed",
        "level_started",
        "parcel_delivered",
        "parcel_picked",
        "spring_empty",
        "spring_wound",
      ].sort(),
    );
  });

  test("level_started carries the level, the parcel count and the spring", () => {
    game.load("scenes/test_yard.scene.json");
    const log = [];
    game.world.on("level_started", (d) => log.push(d));
    game.step(3);
    expect(log.length).toBe(1);
    expect(log[0]).toEqual({ level: "test_yard", parcels: 1, spring: 60 });
  });

  test("the courier is caught: courier_caught then level_failed with reason caught", () => {
    game.load("scenes/test_yard.scene.json");
    game.step(3);
    const log = [];
    for (const n of ["courier_caught", "level_failed"]) game.world.on(n, (d) => log.push([n, d]));
    game.find("courier").behaviour.caught("test_guard");
    game.step(3);
    expect(log.map((e) => e[0])).toEqual(["courier_caught", "level_failed"]);
    expect(log[0][1].by).toBe("test_guard");
    expect(log[1][1].reason).toBe("caught");
  });

  test("checkpoint_reached moves the respawn point", () => {
    game.load("scenes/test_yard.scene.json");
    game.step(3);
    game.world.emit("checkpoint_reached", { position: [4, 0.6, 10] });
    game.step(1);
    game.find("courier").position = [0, -30, 0];
    game.step(4);
    expect(game.find("courier").position.x).toBeCloseTo(4, 0);
  });
});
