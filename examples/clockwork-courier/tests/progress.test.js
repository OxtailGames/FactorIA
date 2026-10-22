// P3: progress and the save: unlock order, district stars, best result per level, the profile name, migration from the
// P1 format (version 1), damaged and newer saves (never destroyed: copied to "progressBackup"), and the pure merge of two copies.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { storage } from "factoria";
import * as progress from "../scripts/progress.js";
import * as saveData from "../scripts/save_data.js";
import { LEVELS, DISTRICTS } from "../scripts/levels.js";

const win = (id, stars, time = 40) => progress.record(id, { time, springLeft: 30, stars });

const fresh = () => {
  game.setStorageText(null);
  storage.remove("progress");
  storage.remove("progressBackup");
};

describe("unlock rules", () => {
  beforeEach(fresh);
  test("a new player has only the first level open", () => {
    expect(LEVELS.filter((l) => progress.isUnlocked(l.id)).map((l) => l.id)).toEqual(["rooftops_1"]);
  });

  test("winning a level opens the next one", () => {
    win("rooftops_1", 1);
    expect(progress.isUnlocked("rooftops_2")).toBe(true);
    expect(progress.isUnlocked("rooftops_3")).toBe(false);
  });

  test("the market needs the stars of the rooftops, not only a won level", () => {
    expect(DISTRICTS[1].stars).toBe(6);
    win("rooftops_1", 2);
    win("rooftops_2", 2);
    win("rooftops_3", 1); // 5 stars: the last level is won but the district stays shut
    expect(progress.starsBefore("market")).toBe(5);
    expect(progress.isDistrictUnlocked("market")).toBe(false);
    expect(progress.isUnlocked("market_1")).toBe(false);
    win("rooftops_3", 2); // better result: 6 stars
    expect(progress.isDistrictUnlocked("market")).toBe(true);
    expect(progress.isUnlocked("market_1")).toBe(true);
    expect(progress.isUnlocked("market_2")).toBe(false);
  });

  test("nextUnfinished is what Continue starts", () => {
    expect(progress.nextUnfinished().id).toBe("rooftops_1");
    win("rooftops_1", 3);
    expect(progress.nextUnfinished().id).toBe("rooftops_2");
    win("rooftops_2", 3);
    win("rooftops_3", 3);
    expect(progress.nextUnfinished().id).toBe("market_1");
  });
});

describe("stars and best results", () => {
  beforeEach(fresh);
  test("totalStars adds the best stars of every level", () => {
    expect(progress.totalStars()).toBe(0);
    win("rooftops_1", 2);
    win("rooftops_2", 3);
    expect(progress.totalStars()).toBe(5);
    win("rooftops_1", 1); // worse: nothing changes
    expect(progress.totalStars()).toBe(5);
  });

  test("a result with more stars wins over a faster one; the same stars take the faster time", () => {
    win("rooftops_1", 2, 30);
    expect(win("rooftops_1", 1, 10)).toBe(false);
    expect(win("rooftops_1", 3, 50)).toBe(true);
    expect(progress.resultFor("rooftops_1")).toMatchObject({ stars: 3, time: 50 });
    expect(win("rooftops_1", 3, 45)).toBe(true);
    expect(progress.resultFor("rooftops_1").time).toBe(45);
  });

  test("every write is one whole save with a counter that only goes up", () => {
    win("rooftops_1", 1);
    const a = storage.get("progress");
    win("rooftops_2", 1);
    const b = storage.get("progress");
    expect(a.version).toBe(2);
    expect(b.counter).toBe(a.counter + 1);
  });
});

describe("profile name", () => {
  beforeEach(fresh);
  test("setName cleans the text and keeps it", () => {
    expect(progress.hasName()).toBe(false);
    expect(progress.setName("  Ana   Maria \n")).toBe("Ana Maria");
    expect(progress.name()).toBe("Ana Maria");
    expect(progress.hasName()).toBe(true);
  });

  test("a name is cut to the limit and an empty one is refused", () => {
    expect(progress.setName("ABCDEFGHIJKLMNOPQRST").length).toBe(saveData.NAME_MAX);
    expect(progress.setName("   ")).toBe("");
    expect(progress.name().length).toBe(saveData.NAME_MAX); // the refused one saved nothing
  });
});

describe("migration and damaged saves", () => {
  beforeEach(fresh);
  const v1 = {
    version: 1,
    results: {
      rooftops_1: { time: 41.5, springLeft: 50, stars: 3, goals: { fast: true, springy: true, thorough: true } },
      rooftops_2: { time: 80, springLeft: 20, stars: 1, goals: null },
      gone_level: { time: 1, springLeft: 1, stars: 3, goals: null },
    },
  };

  test("a version 1 save (P1) is read as version 2: results kept, no name yet", () => {
    game.setStorageText(JSON.stringify({ progress: v1 }));
    const data = progress.load();
    expect(data.version).toBe(2);
    expect(data.name).toBe("");
    expect(data.results.rooftops_1.stars).toBe(3);
    expect(data.results.rooftops_2.time).toBe(80);
    expect(data.results.gone_level).toBeUndefined(); // not a level of this game
    expect(progress.totalStars()).toBe(4);
    expect(progress.isUnlocked("rooftops_3")).toBe(true);
  });

  test("the first write after the migration stores version 2 and keeps everything", () => {
    game.setStorageText(JSON.stringify({ progress: v1 }));
    progress.setName("Ana");
    const saved = storage.get("progress");
    expect(saved.version).toBe(2);
    expect(saved.results.rooftops_1.time).toBe(41.5);
    expect(saved.name).toBe("Ana");
  });

  test("a damaged save starts empty and the bad text is kept as a backup before it is replaced", () => {
    game.setStorageText(JSON.stringify({ progress: "garbage" }));
    expect(progress.totalStars()).toBe(0);
    win("rooftops_1", 1);
    expect(storage.get("progressBackup")).toBe("garbage");
    expect(progress.resultFor("rooftops_1").stars).toBe(1);
  });

  test("a save from a newer game is not read, and not destroyed either", () => {
    const future = { version: 99, results: { rooftops_1: { time: 1, springLeft: 1, stars: 3 } }, extra: true };
    game.setStorageText(JSON.stringify({ progress: future }));
    expect(progress.resultFor("rooftops_1")).toBeNull();
    expect(saveData.parse(future).ok).toBe(false);
    win("rooftops_1", 1);
    expect(storage.get("progressBackup")).toEqual(future);
  });

  test("an unreadable storage file (storage.corrupt) still lets the game save", () => {
    game.setStorageText("{ not json");
    expect(storage.corrupt).toBe(true);
    expect(progress.hasName()).toBe(false);
    expect(progress.setName("Ana")).toBe("Ana");
    game.setStorageText(null);
  });

  test("mangled results are dropped one by one, the good ones stay", () => {
    const mixed = { version: 2, counter: 4, name: "Ana", results: { rooftops_1: { time: "fast", stars: 3 }, rooftops_2: { time: 70, springLeft: 5, stars: 2 } }, daily: null, dailyTimes: {} };
    game.setStorageText(JSON.stringify({ progress: mixed }));
    expect(progress.resultFor("rooftops_1")).toBeNull();
    expect(progress.resultFor("rooftops_2").stars).toBe(2);
    expect(progress.name()).toBe("Ana");
  });
});

describe("save_data.merge", () => {
  beforeEach(fresh);
  const base = () => saveData.empty();

  test("equal progress is the same", () => {
    const a = base();
    a.results.rooftops_1 = { time: 40, springLeft: 20, stars: 2, goals: null };
    expect(saveData.merge(a, JSON.parse(JSON.stringify(a))).from).toBe("same");
  });

  test("one side with everything wins without a new copy", () => {
    const a = base();
    const b = base();
    b.results.rooftops_1 = { time: 40, springLeft: 20, stars: 2, goals: null };
    expect(saveData.merge(a, b).from).toBe("b");
    expect(saveData.merge(b, a).from).toBe("a");
  });

  test("two devices that each progressed are joined: best per level, nothing lost", () => {
    const a = base();
    const b = base();
    a.counter = 5;
    b.counter = 7;
    a.name = "Phone";
    b.name = "Tablet";
    a.results.rooftops_1 = { time: 40, springLeft: 20, stars: 3, goals: null };
    a.results.rooftops_2 = { time: 70, springLeft: 20, stars: 1, goals: null };
    b.results.rooftops_1 = { time: 30, springLeft: 20, stars: 2, goals: null };
    b.results.rooftops_3 = { time: 90, springLeft: 20, stars: 1, goals: null };
    const m = saveData.merge(a, b);
    expect(m.from).toBe("both");
    expect(Object.keys(m.data.results).sort()).toEqual(["rooftops_1", "rooftops_2", "rooftops_3"]);
    expect(m.data.results.rooftops_1.stars).toBe(3);
    expect(m.data.name).toBe("Tablet"); // the copy with the higher counter names the profile
    expect(m.data.counter).toBe(8);
  });
});
