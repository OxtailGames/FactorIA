// Saves: the three slots, format 2, the migration of format 1, files that cannot be read, and Continue.
import { test, describe, expect, game } from "factoria:test";
import { scene, storage, ui } from "factoria";
import v1 from "./fixtures/save_v1.json";
import v2 from "./fixtures/save_v2.json";
import { run, startRun, beginShift, endShift } from "../scripts/game/run_state.js";
import * as saveFile from "../scripts/game/save.js";
import { live } from "../scripts/game/mine_map.js";
import * as players from "../scripts/game/players.js";
import { cleanBeforeEach } from "./helpers/world.js";
import { clearSlots, arrive, CAMP, SHIFT, TITLE, enterRun } from "./helpers/camp.js";

const text = (id) => game.find(id).get("Text").text;
const label = (id) => game.find(id).get("Button").text;

/** The title with the slots panel open. */
function openSlots() {
  players.clear();
  game.load(TITLE);
  game.step(3);
  game.click("play");
  game.step(2);
}

describe("format 2 and the migration of format 1", () => {
  cleanBeforeEach();

  test("the format 1 fixture is migrated: the new fields get their defaults and the run is untouched", () => {
    const r = saveFile.migrate(v1, 3);
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.from).toBe(1);
    expect(r.data).toMatchObject({ format: 2, slot: 3, revision: 1, savedOn: "", playTime: 0, seed: 123456, stratum: 1, floor: 2, shiftNumber: 4, cash: 85 });
    expect(r.data.bestDepth).toBe(50); // stratum 1 floor 2 is 50 m deep: the deepest a format 1 file can tell
    expect(r.data.upgrades.pickSpeed).toBe(1.25);
    expect(r.data.upgrades.torches).toBe(6);
    expect(v1.format).toBe(1); // the fixture itself is not changed
  });

  test("a format 1 file in a slot is read as format 2, and the next save writes format 2", () => {
    storage.set("burrow.slot.1", v1);
    const slot = saveFile.readSlot(1);
    expect(slot.status).toBe("ok");
    if (slot.status !== "ok") return;
    expect(slot.migratedFrom).toBe(1);
    expect(slot.summary).toMatchObject({ slot: 1, stratum: 1, floor: 2, cash: 85, bestDepth: 50 });
    expect(saveFile.continueSlot(1)).toEqual({ ok: true, resume: "camp" });
    expect(run.cash).toBe(85);
    expect(run.upgrades.pickTier).toBe(1);
    expect(saveFile.save()).toBe(true);
    expect(storage.get("burrow.slot.1")).toMatchObject({ format: 2, slot: 1, revision: 2, cash: 85, seed: 123456 });
  });

  test("the format 2 fixture loads as it is", () => {
    const r = saveFile.migrate(v2, 2);
    expect(r).toEqual({ ok: true, data: v2 });
    storage.set("burrow.slot.2", v2);
    expect(saveFile.continueSlot(2)).toEqual({ ok: true, resume: "camp" });
    expect(run).toMatchObject({ slot: 2, seed: 987654, stratum: 2, floor: 1, shiftNumber: 9, cash: 140, playTime: 1800.5, bestDepth: 50, mode: "normal", dailyKey: null });
    expect(run.upgrades).toEqual(v2.upgrades);
  });

  test("a snapshot of a run that played survives the round trip through a slot", () => {
    clearSlots();
    startRun({ seed: 55, slot: 2 });
    beginShift();
    run.ore.gold = 3;
    run.shiftTime = 120;
    endShift("lift");
    expect(saveFile.save({ stratum: 0, floor: 2 })).toBe(true);
    const file = storage.get("burrow.slot.2");
    expect(file).toMatchObject({ format: 2, slot: 2, revision: 1, seed: 55, stratum: 0, floor: 2, shiftNumber: 1, playTime: 120, bestDepth: 10, savedOn: "2026-01-01" });
    startRun({ seed: 1 });
    expect(saveFile.apply(2)).toBe(true);
    expect(run).toMatchObject({ seed: 55, stratum: 0, floor: 2, shiftNumber: 1, playTime: 120 });
  });

  test("a run without a slot, and the daily dig, are never written", () => {
    clearSlots();
    startRun({ seed: 3 });
    expect(saveFile.save()).toBe(false);
    startRun({ seed: 3, mode: "daily", dailyKey: "2026-01-01", slot: 2 });
    expect(run.slot).toBeNull();
    expect(saveFile.save()).toBe(false);
    expect(storage.get("burrow.slot.2", null)).toBeNull();
  });

  test("the old file of P1 (burrow.save) becomes a slot once, and is removed", () => {
    clearSlots();
    storage.set("burrow.save", v1);
    expect(saveFile.importLegacy()).toEqual({ imported: true, slot: 1 });
    expect(storage.get("burrow.save", null)).toBeNull();
    expect(storage.get("burrow.slot.1").format).toBe(2);
    expect(saveFile.importLegacy()).toEqual({ imported: false, reason: "none" });
  });
});

describe("a file that cannot be read", () => {
  cleanBeforeEach();

  test("a damaged save is named by its place and teaches what to do; it does not throw", () => {
    clearSlots();
    storage.set("burrow.slot.1", { format: 2, seed: 5, stratum: 0, floor: 1, shiftNumber: 1, cash: -4, upgrades: {} });
    const r = saveFile.readSlot(1);
    expect(r.status).toBe("error");
    if (r.status !== "error") return;
    expect(r.kind).toBe("corrupt");
    expect(r.message).toContain("#/cash");
    expect(r.message).toContain("-4");
    expect(r.hint).toContain("delete the slot");
    storage.set("burrow.slot.1", "not a save");
    expect(saveFile.readSlot(1)).toMatchObject({ status: "error", kind: "corrupt" });
    storage.set("burrow.slot.1", { cash: 1 });
    expect(saveFile.readSlot(1).message ?? "").toContain("format");
  });

  test("a save from a newer format is refused, kept as it is, and the hint says to update", () => {
    clearSlots();
    const future = { ...v2, format: 3, newField: true };
    storage.set("burrow.slot.2", future);
    const r = saveFile.readSlot(2);
    expect(r).toMatchObject({ status: "error", kind: "newer" });
    if (r.status !== "error") return;
    expect(r.message).toContain("format 3");
    expect(r.hint).toContain("update the game");
    expect(saveFile.continueSlot(2).ok).toBe(false);
    startRun({ slot: 2 });
    expect(saveFile.save()).toBe(false); // never overwrites what it cannot read
    expect(storage.get("burrow.slot.2")).toEqual(future);
    expect(saveFile.newRun(2).ok).toBe(false);
  });

  test("the slot screen shows an unreadable slot, explains it on a click, and Continue skips it", () => {
    clearSlots();
    storage.set("burrow.slot.1", { format: 99 });
    storage.set("burrow.slot.2", v2);
    openSlots();
    expect(label("slot_1")).toBe("Slot 1: cannot be read");
    expect(label("slot_2")).toContain("Slot 2: Magma Deep");
    game.click("slot_1");
    game.step(1);
    expect(scene.current).toBe(TITLE);
    expect(text("slots_message")).toContain("newer version");
    expect(text("slots_message")).toContain("update the game");
    expect(saveFile.lastSlot()).toBe(2);
  });

  test("a storage file that did not parse starts the game empty and the title says so", () => {
    game.setStorageText('{"broken');
    expect(storage.corrupt).toBe(true);
    players.clear();
    game.load(TITLE);
    game.step(3);
    expect(text("menu_message")).toContain("save folder was damaged");
    expect(game.find("continue").active).toBe(false);
  });
});

describe("the slot screen", () => {
  cleanBeforeEach();

  test("three slots; an empty one starts a new run that is saved at once and shows up in the list", () => {
    clearSlots();
    openSlots();
    expect(label("slot_1")).toBe("Slot 1: empty - new run");
    expect(label("slot_3")).toBe("Slot 3: empty - new run");
    expect(game.find("delete_2").get("Button").interactable).toBe(false);
    game.click("slot_2");
    game.step(1);
    expect(scene.current).toBe("scenes/loading.scene.json");
    enterRun(SHIFT);
    expect(run.slot).toBe(2);
    expect(run.shiftNumber).toBe(1);
    expect(storage.get("burrow.slot.2")).toMatchObject({ format: 2, slot: 2, shiftNumber: 0, seed: run.seed });
    expect(storage.get("burrow.lastSlot")).toBe(2);
  });

  test("a filled slot shows the floor, the cash, the play time and the best depth, and a click continues it", () => {
    clearSlots();
    storage.set("burrow.slot.3", v2);
    openSlots();
    expect(label("slot_3")).toBe("Slot 3: Magma Deep, floor 1 - 140 cash - 30:00 - best 50 m");
    game.click("slot_3");
    game.step(1);
    enterRun(CAMP);
    expect(run).toMatchObject({ slot: 3, cash: 140, shiftNumber: 9 });
  });

  test("delete asks first: No keeps the slot, Yes erases it (and only it)", () => {
    clearSlots();
    storage.set("burrow.slot.1", v1);
    storage.set("burrow.slot.2", v2);
    openSlots();
    game.click("delete_2");
    game.step(2);
    expect(game.find("confirm_delete").active).toBe(true);
    expect(text("confirm_text")).toBe("Delete slot 2? This cannot be undone.");
    expect(ui.focused.id).toBe("confirm_no"); // the safe answer has the focus
    game.click("confirm_no");
    game.step(2);
    expect(game.find("slots").active).toBe(true);
    expect(storage.get("burrow.slot.2", null)).not.toBeNull();
    game.click("delete_2");
    game.step(2);
    game.click("confirm_yes");
    game.step(2);
    expect(storage.get("burrow.slot.2", null)).toBeNull();
    expect(storage.get("burrow.slot.1", null)).not.toBeNull();
    expect(label("slot_2")).toBe("Slot 2: empty - new run");
    expect(text("slots_message")).toBe("Slot 2 deleted.");
  });

  test("with a gamepad: A on the slot, B backs out of the confirmation", () => {
    clearSlots();
    storage.set("burrow.slot.1", v2);
    openSlots();
    const pad = game.gamepad(0);
    pad.tap("DpadRight"); // the Delete button of slot 1
    pad.tap("A");
    expect(game.find("confirm_delete").active).toBe(true);
    pad.tap("B");
    expect(game.find("slots").active).toBe(true);
    expect(storage.get("burrow.slot.1", null)).not.toBeNull();
    pad.tap("B"); // back to the title
    expect(game.find("main_menu").active).toBe(true);
  });
});

describe("Continue", () => {
  cleanBeforeEach();

  test("is hidden with no save, takes the focus once there is one, and lands in the camp of the last slot played", () => {
    clearSlots();
    players.clear();
    game.load(TITLE);
    game.step(3);
    expect(game.find("continue").active).toBe(false);
    expect(ui.focused.id).toBe("play");
    storage.set("burrow.slot.1", v1);
    storage.set("burrow.slot.2", v2);
    storage.set("burrow.lastSlot", 2);
    game.load(TITLE);
    game.step(3);
    expect(game.find("continue").active).toBe(true);
    expect(ui.focused.id).toBe("continue");
    game.click("continue");
    enterRun(CAMP);
    expect(run.slot).toBe(2);
    expect(run.cash).toBe(140);
    expect(game.find("camp_cash").get("Text").text).toBe("Cash: 140");
  });

  test("a run that only began (no shift played) continues straight into the shift", () => {
    clearSlots();
    openSlots();
    game.click("slot_1");
    enterRun(SHIFT);
    game.load(TITLE);
    game.step(3);
    game.click("continue");
    enterRun(SHIFT);
    expect(run.slot).toBe(1);
    expect(run.shiftNumber).toBe(1);
  });

  test("a whole round: a shift, the camp, the title, Continue, and the camp shows the same cash and upgrades", () => {
    clearSlots();
    openSlots();
    game.click("slot_1");
    enterRun(SHIFT);
    run.ore.gold = 6;
    const seed = run.seed;
    game.step(3);
    endShiftByLift();
    game.step(130);
    game.click("again");
    arrive(CAMP);
    const cash = run.cash;
    expect(cash).toBeGreaterThan(20);
    game.click("buy_torches");
    game.step(1);
    game.click("to_title");
    game.step(3);
    game.load(TITLE);
    game.step(3);
    game.click("continue");
    enterRun(CAMP);
    expect(run.cash).toBe(cash - 20);
    expect(run.upgrades.torches).toBe(8);
    expect(run.seed).toBe(seed);
    expect([run.stratum, run.floor]).toEqual([0, 2]);
    expect(run.playTime).toBeGreaterThan(0);
  });
});

/** Walks the miner onto the lift: the shift ends. */
function endShiftByLift() {
  const e = live.map.tileCenter(live.mine.exit.tx, live.mine.exit.ty);
  game.world.findByTag("miner")[0].position = [e.x, e.y, 0];
  game.step(3);
}
