// P5: achievements and stats, driven by the game events bus and written to the store layer (the fake store in tests).
import { test, describe, expect, game } from "factoria:test";
import { platform, assets } from "factoria";
import * as events from "../scripts/game/events.js";
import * as trophies from "../scripts/game/trophies.js";
import { freshOnline, shift } from "./helpers/online.js";

const unlocked = () => Object.keys(game.platform.state().fake.achievements).filter((id) => game.platform.state().fake.achievements[id].unlocked ?? game.platform.state().fake.achievements[id]);
const stat = (id) => game.platform.state().fake.stats[id] ?? 0;
async function settle() {
  await trophies.idle();
}

describe("achievements", () => {
  freshOnline();

  test("the catalog has six achievements with names, descriptions and an icon each", async () => {
    const rows = await trophies.list();
    expect(rows.map((r) => r.id)).toEqual(["first_ore", "mole_rescuer", "mole_king", "bright_stratum", "full_house", "bug_squasher"]);
    for (const r of rows) {
      expect(r.name).not.toBe(r.id);
      expect(r.description.length).toBeGreaterThan(10);
      expect(r.unlocked).toBe(false);
      expect(r.icon).toMatch(/^assets\/achievements\/[a-z_]+\.png$/);
      expect(assets.textureSize(r.icon)).toEqual({ width: 64, height: 64 });
    }
  });

  test("first_ore: the first ore picked up unlocks it and counts in the stat", async () => {
    events.emit("orePicked", { ore: "copper", value: 1, by: 0, total: 1 });
    await settle();
    expect(stat("oreDug")).toBe(1);
    expect(unlocked()).toEqual(["first_ore"]);
  });

  test("an unlock is announced once, with the name in the current language", async () => {
    const seen = [];
    const off = events.on("achievementUnlocked", (d) => seen.push(d));
    events.emit("orePicked", { ore: "copper", value: 1, by: 0, total: 1 });
    events.emit("orePicked", { ore: "copper", value: 1, by: 0, total: 2 });
    await settle();
    off();
    expect(seen).toEqual([{ id: "first_ore", name: "First Strike" }]);
    expect(stat("oreDug")).toBe(2);
  });

  test("mole_rescuer: the tenth mole, over several shifts, not the ninth", async () => {
    for (let i = 0; i < 9; i++) events.emit("moleRescued", { tx: i, ty: 0, by: 0, rescued: i + 1, total: 12 });
    await settle();
    expect(stat("molesRescued")).toBe(9);
    expect(unlocked()).toEqual([]);
    events.emit("moleRescued", { tx: 9, ty: 0, by: 0, rescued: 10, total: 12 });
    await settle();
    expect(unlocked()).toEqual(["mole_rescuer"]);
    const row = (await trophies.list()).find((r) => r.id === "mole_rescuer");
    expect(row.unlocked).toBe(true);
  });

  test("mole_king: the Mole King falling unlocks it", async () => {
    events.emit("bossDefeated", { by: 0 });
    await settle();
    expect(unlocked()).toEqual(["mole_king"]);
  });

  test("bug_squasher: 25 enemies defeated", async () => {
    for (let i = 0; i < 24; i++) events.emit("enemyDefeated", { kind: "beetle", tx: 0, ty: 0, by: 0 });
    await settle();
    expect(unlocked()).toEqual([]);
    events.emit("enemyDefeated", { kind: "thief", tx: 0, ty: 0, by: 0 });
    await settle();
    expect(stat("enemiesDefeated")).toBe(25);
    expect(unlocked()).toEqual(["bug_squasher"]);
  });

  test("full_house: a shift with 4 players that ends on the lift; 3 players or the dark do not", async () => {
    shift({ players: 3 });
    shift({ players: 4, outcome: "dark", banked: 0 });
    await settle();
    expect(unlocked()).toEqual([]);
    shift({ players: 4 });
    await settle();
    expect(unlocked()).toEqual(["full_house"]);
  });

  test("bright_stratum: the last floor of a stratum cleared with every lamp lit", async () => {
    shift({ stratum: 0, floor: 1 });
    shift({ stratum: 0, floor: 2 });
    await settle();
    expect(unlocked()).toEqual([]); // not the last floor yet
    shift({ stratum: 0, floor: 3 });
    await settle();
    expect(unlocked()).toEqual(["bright_stratum"]);
  });

  test("bright_stratum: a lamp that went out anywhere in the stratum spoils it, and the next stratum starts clean", async () => {
    shift({ stratum: 0, floor: 1 });
    shift({ stratum: 0, floor: 2 }, () => events.emit("lampOut", { player: 0 }));
    shift({ stratum: 0, floor: 3 });
    await settle();
    expect(unlocked()).toEqual([]);
    shift({ stratum: 1, floor: 1 });
    shift({ stratum: 1, floor: 2 });
    shift({ stratum: 1, floor: 3 });
    await settle();
    expect(unlocked()).toEqual(["bright_stratum"]);
  });

  test("bright_stratum: replaying a floor after a shift in the dark does not wash the record clean", async () => {
    shift({ stratum: 0, floor: 1 });
    shift({ stratum: 0, floor: 2 }, () => events.emit("lampOut", { player: 0 }));
    shift({ stratum: 0, floor: 2, outcome: "dark", banked: 0 });
    shift({ stratum: 0, floor: 2 });
    shift({ stratum: 0, floor: 3 });
    await settle();
    expect(unlocked()).toEqual([]);
  });

  test("the floors cleared stat counts lifts only", async () => {
    shift({ floor: 1 });
    shift({ floor: 2, outcome: "allDown", banked: 0 });
    shift({ floor: 2 });
    await settle();
    expect(stat("floorsCleared")).toBe(2);
  });

  test("the stats and achievements are listed for the Trophies screen", async () => {
    events.emit("orePicked", { ore: "gold", value: 5, by: 0, total: 1 });
    events.emit("moleRescued", { tx: 0, ty: 0, by: 0, rescued: 1, total: 3 });
    await settle();
    const stats = await trophies.statValues();
    expect(stats.map((s) => [s.id, s.label, s.value])).toEqual([
      ["oreDug", "Ore dug", 1],
      ["molesRescued", "Moles rescued", 1],
      ["floorsCleared", "Floors cleared", 0],
      ["enemiesDefeated", "Enemies defeated", 0],
    ]);
    const rows = await trophies.list();
    expect(rows.find((r) => r.id === "mole_rescuer").progress).toEqual({ value: 1, goal: 10 });
  });

  test("a new run does not drop the listeners (events.keep survives startRun)", async () => {
    const { startRun } = await import("../scripts/game/run_state.js");
    startRun({ seed: 9 });
    events.emit("orePicked", { ore: "copper", value: 1, by: 0, total: 1 });
    await settle();
    expect(unlocked()).toEqual(["first_ore"]);
  });

  test("a store that is not there does not break the game", async () => {
    game.platform.set({ backend: "none" });
    expect(platform.has("achievements")).toBe(false);
    events.emit("orePicked", { ore: "copper", value: 1, by: 0, total: 1 });
    shift({});
    await settle();
    expect(game.platform.calls().length).toBe(0);
    game.platform.reset();
  });
});
