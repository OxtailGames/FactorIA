// The daily dig: one seed per date, started from the title, never saved to a slot, and the two fields P5 reads.
import { test, describe, expect, game } from "factoria:test";
import { scene, storage } from "factoria";
import * as daily from "../scripts/game/daily.js";
import * as saveFile from "../scripts/game/save.js";
import * as players from "../scripts/game/players.js";
import { run, startRun, mineSeed } from "../scripts/game/run_state.js";
import { live } from "../scripts/game/mine_map.js";
import { cleanBeforeEach } from "./helpers/world.js";
import { clearSlots, arrive, SHIFT, CAMP, TITLE, enterRun } from "./helpers/camp.js";

/** From the title to the first shift of today's daily dig. */
function startDaily() {
  players.clear();
  game.load(TITLE);
  game.step(3);
  game.click("daily");
  enterRun(SHIFT);
}

describe("the seed of a date", () => {
  cleanBeforeEach();

  test("is a function of the date alone, pinned for a fixed date", () => {
    expect(daily.seedFor("2026-03-14")).toBe(1281020852);
    expect(daily.seedFor("2026-03-15")).toBe(1297798471);
    expect(daily.seedFor("2026-03-14")).toBe(daily.seedFor("2026-03-14"));
    expect(daily.seedFor("2026-03-14")).toBeLessThan(0x80000000);
  });

  test("the date comes from game.today(), which a test can fix", () => {
    expect(daily.todayKey()).toBe("2026-01-01"); // the engine's fixed default
    game.setDate("2026-03-14");
    expect(daily.todayKey()).toBe("2026-03-14");
    expect(daily.seedFor(daily.todayKey())).toBe(1281020852);
  });

  test("a text that is not a date is an error that says what a date looks like", () => {
    expect(() => daily.seedFor("14/03/2026")).toThrow("2026-01-31");
    expect(daily.isKey("2026-03-14")).toBe(true);
    expect(daily.isKey("2026-3-14")).toBe(false);
  });
});

describe("the daily dig from the title", () => {
  cleanBeforeEach();

  test("starts a run of the date's seed in the daily mode, with no slot, and tells the date and tries on the title", () => {
    clearSlots();
    game.setDate("2026-03-14");
    players.clear();
    game.load(TITLE);
    game.step(3);
    expect(game.find("menu_message").get("Text").text).toBe("Daily dig 2026-03-14: 0 tries, deepest 0 m");
    game.click("daily");
    enterRun(SHIFT);
    expect(run).toMatchObject({ mode: "daily", dailyKey: "2026-03-14", slot: null, seed: 1281020852, stratum: 0, floor: 1, shiftNumber: 1, cash: 0 });
    expect(live.mine.seed).toBe(1281020852);
    expect(daily.status().tries).toBe(1);
  });

  test("two tries on one date play the same mine; another date plays another one", () => {
    clearSlots();
    storage.remove("burrow.daily");
    game.setDate("2026-03-14");
    startDaily();
    const first = live.mine.hash;
    startDaily();
    expect(live.mine.hash).toBe(first);
    expect(daily.status().tries).toBe(2);
    game.setDate("2026-03-15");
    startDaily();
    expect(live.mine.hash).not.toBe(first);
    expect(run.dailyKey).toBe("2026-03-15");
    expect(daily.status().tries).toBe(1); // a new date starts its own count
  });

  test("a daily try is never written to a slot and does not become Continue", () => {
    clearSlots();
    startDaily();
    run.cash = 50;
    expect(saveFile.save()).toBe(false);
    for (let n = 1; n <= 3; n++) expect(storage.get(`burrow.slot.${n}`, null)).toBeNull();
    game.load(TITLE);
    game.step(3);
    expect(game.find("continue").active).toBe(false);
  });

  test("the camp between floors keeps the date's mine: the same floor is the same mine on every shift", () => {
    clearSlots();
    startDaily();
    expect(mineSeed(1)).toBe(run.seed);
    expect(mineSeed(5)).toBe(run.seed);
    const e = live.mine.exit;
    game.world.findByTag("miner")[0].position = [live.map.tileCenter(e.tx, e.ty).x, live.map.tileCenter(e.tx, e.ty).y, 0];
    game.step(130);
    expect(run.lastShift.seed).toBe(run.seed);
    game.click("again");
    arrive(CAMP);
    expect(run.mode).toBe("daily");
    expect(saveFile.save()).toBe(false);
    expect(daily.status().bestDepth).toBe(10); // floor 1 done: 10 m
  });

  test("the best depth and the win of the date are kept, and survive another try", () => {
    storage.remove("burrow.daily");
    game.setDate("2026-03-14");
    startRun({ seed: daily.seedFor("2026-03-14"), mode: "daily", dailyKey: "2026-03-14" });
    daily.noteShift({ stratum: 1, floor: 2, outcome: "lift" }, false);
    daily.noteShift({ stratum: 0, floor: 3, outcome: "lift" }, false);
    expect(daily.status("2026-03-14")).toEqual({ key: "2026-03-14", tries: 0, bestDepth: 50, won: false });
    daily.noteShift({ stratum: 2, floor: 3, outcome: "lift" }, true);
    expect(daily.status("2026-03-14").won).toBe(true);
    expect(daily.status("2026-03-15")).toEqual({ key: "2026-03-15", tries: 0, bestDepth: 0, won: false });
  });

  test("a shift that ends after midnight still counts for the date the try began on", () => {
    storage.remove("burrow.daily");
    game.setDate("2026-03-14");
    daily.start();
    game.setDate("2026-03-15");
    daily.noteShift({ stratum: 0, floor: 2, outcome: "lift" }, false);
    expect(daily.status("2026-03-14").bestDepth).toBe(20);
    expect(daily.status("2026-03-15").bestDepth).toBe(0);
  });
});

describe("run.mode and run.dailyKey (the contract P5 reads)", () => {
  cleanBeforeEach();

  test("every run that is not the daily dig is 'normal' with a null dailyKey", () => {
    startRun({ seed: 5 });
    expect(run).toMatchObject({ mode: "normal", dailyKey: null });
    startRun({ seed: 5, mode: "daily", dailyKey: "2026-03-14" });
    expect(run).toMatchObject({ mode: "daily", dailyKey: "2026-03-14" });
    startRun({ seed: 5 }); // the next run clears them
    expect(run).toMatchObject({ mode: "normal", dailyKey: null });
    startRun({ seed: 5, dailyKey: "2026-03-14" }); // a key without the mode is ignored
    expect(run).toMatchObject({ mode: "normal", dailyKey: null });
  });

  test("a run from a slot, from Continue and from a seed code are all 'normal'", () => {
    clearSlots();
    saveFile.newRun(1, { seed: 9 });
    expect(run).toMatchObject({ mode: "normal", dailyKey: null, slot: 1 });
    saveFile.continueSlot(1);
    expect(run).toMatchObject({ mode: "normal", dailyKey: null, slot: 1 });
  });

  test("a victory of a daily try goes back to the title; it is one try", () => {
    startRun({ seed: 5, mode: "daily", dailyKey: "2026-03-14" });
    run.lastShift = { outcome: "lift", stratum: 2, floor: 3, ore: {}, oreCount: 0, value: 0, banked: 0, time: 1, molesRescued: 0, molesTotal: 0, shiftNumber: 9, seed: 5 };
    game.load("scenes/results.scene.json");
    game.step(3);
    game.click("again");
    game.step(3);
    expect(scene.current).toBe(TITLE);
  });
});
