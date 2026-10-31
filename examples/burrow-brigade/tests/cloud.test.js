// Cloud saves on the fake store: upload, download, the conflict rule (cloud.js header), the cases that must not touch a file,
// and the screens that use it.
import { test, describe, expect, game } from "factoria:test";
import { storage, platform } from "factoria";
import v2 from "./fixtures/save_v2.json";
import * as cloud from "../scripts/game/cloud.js";
import * as saveFile from "../scripts/game/save.js";
import { run, startRun } from "../scripts/game/run_state.js";
import * as players from "../scripts/game/players.js";
import { cleanBeforeEach } from "./helpers/world.js";
import { clearSlots, CAMP, TITLE } from "./helpers/camp.js";

const text = (id) => game.find(id).get("Text").text;
/** A save of slot 1 with the given progress. */
const file = (over = {}) => ({ ...v2, slot: 1, ...over });
const local = () => storage.get("burrow.slot.1", null);
const remote = () => platform.cloud.load("burrow.slot.1");
/** Lets the fire-and-forget syncs of the screens finish. */
async function settle() {
  for (let i = 0; i < 60; i++) await Promise.resolve();
}

describe("syncSlot: one side changed", () => {
  cleanBeforeEach();

  test("the cloud is there when the game is run on the fake store", () => {
    expect(cloud.available()).toBe(true);
    expect(cloud.cloudKey(2)).toBe("burrow.slot.2");
  });

  test("nothing on either side: nothing happens", async () => {
    clearSlots();
    expect(await cloud.syncSlot(1)).toEqual({ slot: 1, action: "none" });
  });

  test("a local slot with an empty cloud is uploaded, and the same state is then in sync", async () => {
    clearSlots();
    storage.set("burrow.slot.1", file());
    expect(await cloud.syncSlot(1)).toEqual({ slot: 1, action: "uploaded" });
    expect(await remote()).toEqual(file());
    expect(await cloud.syncSlot(1)).toEqual({ slot: 1, action: "inSync" });
  });

  test("an empty local slot takes the cloud copy (a new device)", async () => {
    clearSlots();
    await platform.cloud.save("burrow.slot.1", file({ cash: 321 }));
    expect(await cloud.syncSlot(1)).toEqual({ slot: 1, action: "downloaded" });
    expect(local().cash).toBe(321);
    expect(saveFile.readSlot(1).status).toBe("ok");
  });

  test("playing on this device after a sync uploads the new save; the other device's progress downloads", async () => {
    clearSlots();
    storage.set("burrow.slot.1", file());
    await cloud.syncSlot(1);
    // this device plays: revision 7 -> 8
    startRun({ slot: 1 });
    saveFile.continueSlot(1);
    run.cash += 10;
    expect(saveFile.save()).toBe(true);
    expect(await cloud.syncSlot(1)).toEqual({ slot: 1, action: "uploaded" });
    expect((await remote()).cash).toBe(150);
    // the other device plays: the cloud moves ahead, this one did not change
    await platform.cloud.save("burrow.slot.1", file({ revision: 9, cash: 400, playTime: 2400 }));
    expect(await cloud.syncSlot(1)).toEqual({ slot: 1, action: "downloaded" });
    expect(local()).toMatchObject({ revision: 9, cash: 400 });
  });
});

describe("syncSlot: both changed is a conflict", () => {
  cleanBeforeEach();

  /** A synced slot at revision 7 that then changed on both sides. */
  async function conflict(localOver, remoteOver) {
    clearSlots();
    storage.set("burrow.slot.1", file());
    await cloud.syncSlot(1);
    storage.set("burrow.slot.1", file({ revision: 8, ...localOver }));
    await platform.cloud.save("burrow.slot.1", file({ revision: 8, ...remoteOver }));
  }

  test("the copy with more play time wins: here the cloud, and the local one is kept as a backup", async () => {
    await conflict({ playTime: 2000, cash: 10 }, { playTime: 3000, cash: 20 });
    const r = await cloud.syncSlot(1);
    expect(r).toEqual({ slot: 1, action: "conflict", winner: "cloud" });
    expect(local()).toMatchObject({ playTime: 3000, cash: 20 });
    expect(storage.get("burrow.backup.1")).toMatchObject({ playTime: 2000, cash: 10 });
    expect(await cloud.syncSlot(1)).toEqual({ slot: 1, action: "inSync" });
  });

  test("here the local one has more play time: it replaces the cloud copy, which is kept as a backup in the cloud", async () => {
    await conflict({ playTime: 5000, cash: 10 }, { playTime: 3000, cash: 20 });
    const r = await cloud.syncSlot(1);
    expect(r).toEqual({ slot: 1, action: "conflict", winner: "local" });
    expect(await remote()).toMatchObject({ playTime: 5000, cash: 10 });
    expect(await platform.cloud.load("burrow.backup.1")).toMatchObject({ playTime: 3000, cash: 20 });
  });

  test("equal play time: the deeper best depth wins, then the higher revision, then the cloud", async () => {
    await conflict({ bestDepth: 90 }, { bestDepth: 60, cash: 1 });
    expect((await cloud.syncSlot(1)).winner).toBe("local");
    await conflict({ revision: 9 }, { revision: 8, cash: 1 });
    expect((await cloud.syncSlot(1)).winner).toBe("local");
    await conflict({ cash: 5 }, { cash: 6 });
    expect((await cloud.syncSlot(1)).winner).toBe("cloud");
  });

  test("a device that never synced and has its own save meets the cloud's as a conflict, not an overwrite", async () => {
    clearSlots();
    storage.set("burrow.slot.1", file({ playTime: 100, cash: 1 }));
    await platform.cloud.save("burrow.slot.1", file({ playTime: 900, cash: 2 }));
    const r = await cloud.syncSlot(1);
    expect(r).toMatchObject({ action: "conflict", winner: "cloud" });
    expect(storage.get("burrow.backup.1")).toMatchObject({ playTime: 100 });
  });

  test("while a run is played (allowDownload: false) a cloud win waits instead of replacing the run", async () => {
    await conflict({ playTime: 2000 }, { playTime: 3000 });
    const mine = local();
    expect(await cloud.syncSlot(1, { allowDownload: false })).toMatchObject({ action: "waiting", winner: "cloud" });
    expect(local()).toEqual(mine);
    // a local win still uploads
    await conflict({ playTime: 9000 }, { playTime: 3000 });
    expect((await cloud.syncSlot(1, { allowDownload: false })).action).toBe("conflict");
  });
});

describe("syncSlot: what is never touched", () => {
  cleanBeforeEach();

  test("a cloud copy of a newer format is not applied, and neither side changes", async () => {
    clearSlots();
    storage.set("burrow.slot.1", file());
    const future = { ...file(), format: 3 };
    await platform.cloud.save("burrow.slot.1", future);
    const r = await cloud.syncSlot(1);
    expect(r.action).toBe("blocked");
    expect(r.message).toContain("newer version");
    expect(r.hint).toContain("update the game");
    expect(local()).toEqual(file());
    expect(await remote()).toEqual(future);
  });

  test("a damaged cloud copy is kept as a backup and replaced by the local save", async () => {
    clearSlots();
    storage.set("burrow.slot.1", file());
    await platform.cloud.save("burrow.slot.1", { format: 2, cash: "lots" });
    const r = await cloud.syncSlot(1);
    expect(r.action).toBe("uploaded");
    expect(r.message).toContain("damaged");
    expect(await remote()).toEqual(file());
    expect(await platform.cloud.load("burrow.backup.1")).toEqual({ format: 2, cash: "lots" });
  });

  test("a local slot that cannot be read is left alone and the cloud copy too", async () => {
    clearSlots();
    storage.set("burrow.slot.1", { format: 77 });
    await platform.cloud.save("burrow.slot.1", file());
    const r = await cloud.syncSlot(1);
    expect(r.action).toBe("blocked");
    expect(local()).toEqual({ format: 77 });
    expect(await remote()).toEqual(file());
  });

  test("a store that fails answers an error, never throws, and the local save is safe", async () => {
    clearSlots();
    storage.set("burrow.slot.1", file());
    game.platform.respond("cloud.save", { error: "network", hint: "Check the connection." });
    const r = await cloud.syncSlot(1);
    expect(r.action).toBe("error");
    expect(r.message).toContain("cloud save of slot 1 failed");
    expect(r.hint).toBe("Check the connection.");
    expect(local()).toEqual(file());
    expect((await cloud.syncSlot(1)).action).toBe("uploaded"); // the next sync tries again
  });

  test("a build with no store plugin says so", async () => {
    clearSlots();
    game.platform.set({ backend: "none" });
    expect(cloud.available()).toBe(false);
    expect((await cloud.syncSlot(1)).action).toBe("unavailable");
    game.platform.reset();
  });

  test("deleting a slot also deletes its cloud copy, or it would come back", async () => {
    clearSlots();
    storage.set("burrow.slot.1", file());
    await cloud.syncSlot(1);
    expect(await remote()).toBeDefined();
    saveFile.erase(1);
    expect(await cloud.removeSlot(1)).toEqual({ slot: 1, action: "removed" });
    expect(await remote()).toBeUndefined();
    expect(storage.get("burrow.cloudBase.1", null)).toBeNull();
    expect((await cloud.syncSlot(1)).action).toBe("none");
  });
});

describe("the screens", () => {
  cleanBeforeEach();

  test("opening the slot screen syncs: a slot that lives only in the cloud shows up and says so", async () => {
    clearSlots();
    await platform.cloud.save("burrow.slot.2", file({ slot: 2, cash: 77 }));
    players.clear();
    game.load(TITLE);
    game.step(3);
    game.click("play");
    await settle();
    game.step(2);
    expect(game.find("slot_2").get("Button").text).toContain("77 cash");
    expect(text("slots_message")).toBe("Slot 2 came down from the cloud.");
    expect(game.find("continue").active).toBe(true);
  });

  test("the Sync button settles the slots again and reports a conflict", async () => {
    clearSlots();
    players.clear();
    game.load(TITLE);
    game.step(3);
    game.click("play");
    await settle();
    storage.set("burrow.slot.1", file({ playTime: 10 }));
    await platform.cloud.save("burrow.slot.1", file({ playTime: 20 }));
    game.click("sync_slots");
    game.step(1);
    await settle();
    game.step(2);
    expect(text("slots_message")).toContain("changed in two places");
    expect(text("slots_message")).toContain("cloud");
  });

  test("an answer that arrives after the player left the slot screen writes nothing and does not fail", async () => {
    clearSlots();
    await platform.cloud.save("burrow.slot.1", file());
    game.platform.set({ delayFrames: 5 });
    players.clear();
    game.load(TITLE);
    game.step(3);
    game.click("play");
    game.step(1);
    game.click("slots_back"); // left before the cloud answered
    game.step(1);
    expect(game.find("main_menu").active).toBe(true);
    game.step(20);
    await settle();
    expect(game.find("main_menu").active).toBe(true);
    expect(text("menu_message")).not.toContain("cloud");
    game.platform.reset();
  });

  test("a purchase in the camp uploads the slot, and the camp never downloads over the run", async () => {
    clearSlots();
    players.clear();
    storage.set("burrow.slot.1", file({ stratum: 0, floor: 2, cash: 100, playTime: 50, upgrades: { ...v2.upgrades, torches: 6, pickTier: 0 } }));
    saveFile.continueSlot(1);
    game.load(CAMP);
    game.step(3);
    await settle();
    expect((await remote()).cash).toBe(100); // entering the camp saved and uploaded
    game.click("buy_torches");
    await settle();
    expect((await remote()).cash).toBe(80);
    expect((await remote()).upgrades.torches).toBe(8);
    // the other device gets further: the camp leaves the run it is playing alone
    await platform.cloud.save("burrow.slot.1", file({ revision: 99, cash: 5, playTime: 9999 }));
    game.click("buy_torches");
    await settle();
    expect(run.cash).toBe(30);
    expect((await remote()).cash).toBe(5);
  });
});
