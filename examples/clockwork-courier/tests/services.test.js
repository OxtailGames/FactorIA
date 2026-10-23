// Achievements, stats and leaderboard submissions (scripts/services.js): every achievement trigger, the stats, what happens
// when the store is away (signed out, no store, network down), the shortcut zones played by the bot, and a real delivery.
import { test, describe, expect, game, beforeEach, afterEach } from "factoria:test";
import { storage, platform } from "factoria";
import { Autoplay, YARD_ROUTE } from "./helpers/autoplay.js";
import { ROUTES } from "./helpers/routes.js";
import { fresh, cleanup, send, services, calls, fake, record, loadYard } from "./helpers/store.js";
import * as svc from "../scripts/services.js";
import * as progress from "../scripts/progress.js";
import * as shortcuts from "../scripts/shortcuts.js";
import { LEVELS } from "../scripts/levels.js";

const delivered = (optional = 0) => ({ door: "door", delivered: 1, total: 1, optional });
const completed = (o = {}) => ({ level: "rooftops_1", time: 80, springLeft: 20, stars: 1, goals: {}, best: true, ...o });
const stars = (n) => ({ time: 50, springLeft: 20, stars: n, goals: {} });
const winAll = (ids, n = 1) => ids.forEach((id) => progress.record(id, stars(n)));

const setup = () => {
  fresh();
  loadYard();
};

describe("the catalog and the code agree", () => {
  beforeEach(setup);
  afterEach(cleanup);
  test("every achievement, stat and board the code names is in the catalog of factoria.json", () => {
    const catalog = game.platform.state().catalog;
    expect(catalog.achievements.slice().sort()).toEqual(svc.ACHIEVEMENTS.slice().sort());
    expect(catalog.stats.slice().sort()).toEqual(svc.STATS.slice().sort());
    for (const l of LEVELS) expect(catalog.leaderboards).toContain(svc.timeBoard(l.id));
    expect(catalog.leaderboards).toContain("total_stars");
    expect(catalog.leaderboards).toContain("daily_route");
  });

  test("the services start with the scene and sign in", () => {
    expect(game.find("store_services")).not.toBeNull();
    expect(game.platform.state().player.signedIn).toBe(true);
    expect(calls("player.signIn").length).toBe(1);
  });
});

describe("achievement triggers", () => {
  beforeEach(setup);
  afterEach(cleanup);
  /** @type {Array<[string, () => void]>} */
  const cases = [
    ["first_delivery", () => send("parcel_delivered", delivered())],
    [
      "rooftops_done",
      () => {
        winAll(["rooftops_1", "rooftops_2", "rooftops_3"]);
        send("level_completed", completed({ level: "rooftops_3" }));
      },
    ],
    [
      "market_done",
      () => {
        winAll(["market_1", "market_2", "market_3"]);
        send("level_completed", completed({ level: "market_3" }));
      },
    ],
    [
      "star_collector",
      () => {
        winAll(["rooftops_1", "rooftops_2", "rooftops_3"], 3);
        send("level_completed", completed({ level: "rooftops_3", stars: 3 }));
      },
    ],
    [
      "all_stars",
      () => {
        winAll(LEVELS.map((l) => l.id), 3);
        send("level_completed", completed({ level: "market_3", stars: 3 }));
      },
    ],
    ["clean_run", () => send("level_completed", completed())],
    ["last_second", () => send("level_completed", completed({ springLeft: 3 }))],
    ["quick_courier", () => send("level_completed", completed({ time: 45 }))], // par time of rooftops_1 is 50 s
    ["extra_mile", () => send("parcel_delivered", delivered(1))],
    ["first_shortcut", () => send("shortcut_found", { level: "rooftops_1", shortcut: "rooftops_1.gap" })],
    [
      "all_shortcuts",
      () => {
        for (const id of shortcuts.all()) send("shortcut_found", { level: id.split(".")[0], shortcut: id }, 1);
        game.step(3);
      },
    ],
    [
      "dog_whisperer",
      () => {
        for (let i = 0; i < svc.DOGS_FOR_WHISPERER; i++) send("dog_gave_up", { dog: "dog_1" }, 1);
        game.step(3);
      },
    ],
    ["daily_courier", () => send("daily_route_finished", { date: "2026-10-22", level: "rooftops_1", time: 61.5 })],
    ["fresh_paint", () => send("paint_equipped", { paint: "rust" })],
  ];

  for (const [id, trigger] of cases) {
    test(`${id} unlocks on its trigger, in the save and in the store, with a toast`, () => {
      expect(svc.isUnlocked(id)).toBe(false);
      trigger();
      game.step(5);
      expect(svc.isUnlocked(id)).toBe(true);
      expect(fake().achievements[id]?.unlocked).toBe(true);
      expect(services().toasts.shown.some((t) => t.includes("Achievement unlocked"))).toBe(true);
    });
  }

  test("there is a trigger for every achievement of the catalog", () => {
    expect(cases.map((c) => c[0]).sort()).toEqual(svc.ACHIEVEMENTS.slice().sort());
  });

  test("the near misses do not unlock: 4 dogs, 5 s left, over par, the factory paint, 8 stars", () => {
    for (let i = 0; i < svc.DOGS_FOR_WHISPERER - 1; i++) send("dog_gave_up", { dog: "dog_1" }, 1);
    send("level_completed", completed({ springLeft: 5.5, time: 55 }));
    send("paint_equipped", { paint: "factory" });
    winAll(["rooftops_1", "rooftops_2"], 3);
    winAll(["rooftops_3"], 2); // 8 stars
    send("level_completed", completed({ level: "rooftops_3", springLeft: 5.5, time: 120 }));
    for (const id of ["dog_whisperer", "last_second", "quick_courier", "fresh_paint", "star_collector", "rooftops_done"]) {
      // rooftops_done is true here (three rooftop levels were won): check the others only
      if (id !== "rooftops_done") expect(svc.isUnlocked(id)).toBe(false);
    }
  });

  test("clean_run needs a level without a catch", () => {
    send("courier_caught", { by: "dog_1" });
    send("level_completed", completed());
    expect(svc.isUnlocked("clean_run")).toBe(false);
    send("level_started", { level: "rooftops_1", parcels: 1, spring: 100 }); // a new attempt
    send("level_completed", completed());
    expect(svc.isUnlocked("clean_run")).toBe(true);
  });

  test("an achievement is sent to the store once, however often the trigger repeats", () => {
    send("parcel_delivered", delivered());
    send("parcel_delivered", delivered());
    expect(calls("achievements.unlock").filter((c) => c.args.id === "first_delivery").length).toBe(1);
    expect(services().toasts.shown.length).toBe(1);
  });

  test("toasts show one at a time and fade away", () => {
    send("parcel_delivered", delivered(1)); // first_delivery and extra_mile in the same frame
    game.step(5);
    expect(game.find("toast")).not.toBeNull();
    expect(services().toasts.queue.length).toBe(1);
    game.step(400);
    expect(services().toasts.shown.length).toBe(2);
    expect(game.find("toast")).toBeNull();
  });
});

describe("stats", () => {
  beforeEach(setup);
  afterEach(cleanup);
  test("the events count in the save and in the store", () => {
    send("parcel_delivered", delivered());
    send("courier_caught", { by: "dog_1" });
    send("courier_caught", { by: "dog_1" });
    send("level_failed", { level: "test_yard", reason: "spring_empty" });
    send("spring_wound", { seconds: 10, left: 30 });
    send("dog_gave_up", { dog: "dog_1" });
    send("shortcut_found", { level: "rooftops_1", shortcut: "rooftops_1.gap" });
    send("level_completed", completed());
    send("more_time_granted", { level: "rooftops_1", seconds: 20 });
    const expected = { parcels_delivered: 1, times_caught: 2, springs_run_down: 1, keys_wound: 1, dogs_shaken: 1, shortcuts_found: 1, levels_won: 1, more_time_used: 1 };
    for (const [id, n] of Object.entries(expected)) {
      expect(svc.stat(id)).toBe(n);
      expect(fake().stats[id]).toBe(n);
    }
  });

  test("a delivery event that carries two parcels counts two", () => {
    send("parcel_delivered", { door: "d", delivered: 1, total: 3, optional: 0 });
    send("parcel_delivered", { door: "d", delivered: 3, total: 3, optional: 0 });
    expect(svc.stat("parcels_delivered")).toBe(3);
  });

  test("a stat is sent as its value, so a call sent twice changes nothing", () => {
    send("spring_wound", { seconds: 10, left: 30 });
    send("spring_wound", { seconds: 10, left: 30 });
    const sets = calls("stats.set").filter((c) => c.args.id === "keys_wound").map((c) => c.args.value);
    expect(sets).toEqual([1, 2]);
  });
});

describe("leaderboard submissions", () => {
  beforeEach(setup);
  afterEach(cleanup);
  test("a won level sends its time in milliseconds and the total stars", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(10);
    progress.record("rooftops_1", stars(3));
    send("level_completed", completed({ time: 42.5, stars: 3 }));
    const times = calls("leaderboards.submit").filter((c) => c.args.id === "time_rooftops_1");
    expect(times.map((c) => c.args.score)).toEqual([42500]);
    expect(calls("leaderboards.submit").filter((c) => c.args.id === "total_stars").map((c) => c.args.score)).toEqual([3]);
    expect(fake().leaderboards.time_rooftops_1).toBe(42500);
  });

  test("the test yard has no time board: nothing is submitted for it", () => {
    send("level_completed", completed({ level: "test_yard", time: 30 }));
    expect(calls("leaderboards.submit").filter((c) => c.args.id.startsWith("time_")).length).toBe(0);
  });

  test("a run that was continued with rewarded time does not go on the board", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(10);
    send("level_completed", completed({ time: 42.5, continued: true }));
    expect(calls("leaderboards.submit").filter((c) => c.args.id === "time_rooftops_1").length).toBe(0);
  });

  test("the daily route sends its time", () => {
    send("daily_route_finished", { date: "2026-10-22", level: "rooftops_2", time: 61.25 });
    expect(calls("leaderboards.submit").filter((c) => c.args.id === "daily_route").map((c) => c.args.score)).toEqual([61250]);
  });

  test("the daily board is the engine's daily period: today's score is there, the next day's board is empty", async () => {
    game.setDate("2026-10-22");
    send("daily_route_finished", { date: "2026-10-22", level: "rooftops_2", time: 61.25 });
    expect((await platform.leaderboards.entries("daily_route")).length).toBe(1);
    game.setDate("2026-10-23");
    expect((await platform.leaderboards.entries("daily_route")).length).toBe(0);
  });
});

describe("when the store is away", () => {
  beforeEach(setup);
  afterEach(cleanup);
  test("signed out: the unlock is kept in the save and sent when the player signs in", async () => {
    game.platform.set({ signedIn: false });
    send("parcel_delivered", delivered());
    expect(svc.isUnlocked("first_delivery")).toBe(true); // the game does not wait for the store
    expect(fake().achievements.first_delivery).toBeUndefined();
    expect(svc.load().outbox.length).toBeGreaterThan(0);
    game.platform.set({ signedIn: true });
    services().flush();
    game.step(5);
    expect(fake().achievements.first_delivery?.unlocked).toBe(true);
    expect(fake().stats.parcels_delivered).toBe(1);
    expect(svc.load().outbox.length).toBe(0);
  });

  test("a network error keeps the call for later", () => {
    game.platform.respond("achievements.unlock", { error: "network" });
    send("parcel_delivered", delivered());
    expect(svc.load().outbox.some((c) => c.op === "unlock" && c.id === "first_delivery")).toBe(true);
    services().flush();
    game.step(5);
    expect(fake().achievements.first_delivery?.unlocked).toBe(true);
    expect(svc.load().outbox.length).toBe(0);
  });

  test("a store without the service drops the calls and the game still keeps its own unlocks", () => {
    game.platform.set({ backend: "none" });
    send("parcel_delivered", delivered());
    expect(svc.isUnlocked("first_delivery")).toBe(true);
    expect(svc.load().outbox.length).toBe(0); // nothing to wait for
    expect(game.platform.state().backend).toBeDefined();
  });

  test("the outbox is sent at the next start", () => {
    game.platform.set({ signedIn: false });
    send("parcel_delivered", delivered());
    game.platform.set({ signedIn: true });
    loadYard(); // a new run: the services sign in and flush
    game.step(10);
    expect(fake().achievements.first_delivery?.unlocked).toBe(true);
  });
});

describe("shortcut zones", () => {
  beforeEach(setup);
  afterEach(cleanup);
  const withZones = LEVELS.filter((l) => shortcuts.ZONES[l.id]);

  test("six shortcuts in four levels; the two other levels list none", () => {
    expect(shortcuts.total()).toBe(6);
    expect(withZones.map((l) => l.id)).toEqual(["rooftops_1", "rooftops_2", "market_1", "market_2"]);
  });

  for (const level of withZones) {
    test(`${level.id}: the shortcut route finds every zone, the main route none`, () => {
      const run = (route) => {
        fresh();
        game.load(level.scene);
        game.step(10);
        const log = record(["shortcut_found"]);
        new Autoplay(game, { maxFrames: 1500 }).run(route);
        game.step(60);
        return log.map((e) => e.data.shortcut);
      };
      expect(run(ROUTES[level.id].main)).toEqual([]);
      expect(run(ROUTES[level.id].shortcut).sort()).toEqual(shortcuts.ZONES[level.id].map((z) => z.id).sort());
    });
  }

  test("a zone counts once per attempt but the stat and the list of found shortcuts are kept", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(10);
    const courier = game.find("courier");
    const z = shortcuts.ZONES.rooftops_1[0];
    const log = record(["shortcut_found"]);
    courier.position = [z.x, 0.6, z.z];
    game.step(10);
    courier.position = [z.x, 0.6, z.z + 5];
    game.step(5);
    courier.position = [z.x, 0.6, z.z];
    game.step(10);
    expect(log.length).toBe(1);
    expect(svc.load().shortcuts).toEqual(["rooftops_1.gap"]);
    expect(svc.isUnlocked("first_shortcut")).toBe(true);
  });
});

describe("a real delivery", () => {
  beforeEach(setup);
  afterEach(cleanup);
  test("the bot delivers the parcel in the yard: the achievements and stats follow without a line of test glue", () => {
    const bot = new Autoplay(game);
    expect(bot.run(YARD_ROUTE).reached).toBe(true);
    game.step(200);
    expect(svc.isUnlocked("first_delivery")).toBe(true);
    expect(svc.isUnlocked("clean_run")).toBe(true);
    expect(svc.stat("levels_won")).toBe(1);
    expect(svc.stat("parcels_delivered")).toBe(1);
    expect(fake().achievements.first_delivery.unlocked).toBe(true);
    expect(storage.get("services").ach.clean_run).toBe(true);
  });
});
