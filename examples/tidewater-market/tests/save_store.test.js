// The save slots (scripts/game/save_store.js), the autosave rules (autosave.js) and the cloud copies (cloud_sync.js).
import { test, expect, game } from "factoria:test";
import { storage, session, scene, platform } from "factoria";
import { smallTown, fillHouses, runDays } from "./town_helper.js";
import { createGame } from "../scripts/game/state.js";
import { VERSION } from "../scripts/game/savegame.js";
import { SLOTS, writeEntry, readMeta, listSlots, latestEntry, loadEntry, renameEntry, deleteEntry, deleteSlot, dataKey, metaKey, cleanName } from "../scripts/game/save_store.js";
import slotV1 from "./fixtures/slot_v1.json";
import { Autosaver } from "../scripts/game/autosave.js";
import { syncCloud, pickWinner, cloudKey, listConflicts, takeConflict } from "../scripts/game/cloud_sync.js";

const GAME = "scenes/game.scene.json";

function town(days = 3) {
  const { game: state } = smallTown();
  fillHouses(state);
  runDays(state, days);
  return state;
}

test("save and load round-trip in every slot, manual and auto, and the loaded game plays on like the original", () => {
  storage.clear();
  const state = town(2);
  for (let slot = 1; slot <= SLOTS; slot++) {
    for (const kind of ["manual", "auto"]) {
      const res = writeEntry(slot, kind, state, { name: `T${slot}`, playSeconds: 100 + slot });
      expect(res.ok).toBe(true);
      const meta = readMeta(slot, kind);
      expect(meta.hash).toBe(state.hash());
      expect(meta.slot).toBe(slot);
      expect(meta.kind).toBe(kind);
      expect(meta.version).toBe(VERSION);
      expect(meta.thumb.rows.length).toBe(10);
      const loaded = loadEntry(slot, kind, state.data);
      expect(loaded.ok).toBe(true);
      expect(loaded.state.hash()).toBe(state.hash());
    }
    const twin = loadEntry(slot, "manual", state.data).state;
    runDays(twin, 4);
    const again = loadEntry(slot, "auto", state.data).state;
    runDays(again, 4);
    expect(twin.hash()).toBe(again.hash());
  }
  // the original, played the same days, is the same town as a loaded one
  runDays(state, 4);
  expect(loadEntry(1, "manual", state.data).state.hash()).not.toBe(state.hash()); // saved before those days
  const slots = listSlots();
  expect(slots).toHaveLength(SLOTS);
  expect(slots.every((s) => s.manual && s.auto)).toBe(true);
});

test("revisions grow with every write and Continue picks the latest entry", () => {
  storage.clear();
  const state = town(1);
  expect(latestEntry()).toBe(null);
  writeEntry(2, "manual", state);
  writeEntry(1, "auto", state);
  writeEntry(3, "manual", state);
  expect(latestEntry()).toMatchObject({ slot: 3, kind: "manual" });
  writeEntry(1, "manual", state);
  expect(latestEntry()).toMatchObject({ slot: 1, kind: "manual" });
  expect(readMeta(1, "manual").revision).toBeGreaterThan(readMeta(3, "manual").revision);
});

test("rename keeps the save, delete removes the entry, names are cleaned", () => {
  storage.clear();
  const state = town(1);
  writeEntry(1, "manual", state, { name: "First" });
  expect(renameEntry(1, "  My   harbour \n town that is far too long to fit ")).toBe(true);
  const name = readMeta(1, "manual").name;
  expect(name).toBe(cleanName("My harbour town that is far too long"));
  expect(name.length).toBeLessThanOrEqual(24);
  expect(loadEntry(1, "manual", state.data).ok).toBe(true);
  expect(renameEntry(2, "x")).toBe(false);
  writeEntry(1, "auto", state);
  deleteEntry(1, "manual");
  expect(listSlots()[0].manual).toBe(null);
  expect(listSlots()[0].auto).not.toBe(null);
  deleteSlot(1);
  expect(listSlots()[0].auto).toBe(null);
  // saving again into a slot keeps its name unless a new one is given
  writeEntry(2, "manual", state, { name: "Keep" });
  writeEntry(2, "manual", state);
  expect(readMeta(2, "manual").name).toBe("Keep");
});

test("a corrupt, truncated, future or empty slot is refused with a message, and the others still load", () => {
  storage.clear();
  const state = town(1);
  for (const slot of [1, 2, 3]) writeEntry(slot, "manual", state);
  storage.set(dataKey(1, "manual"), '{"format":"tidewater.save","version":1,"map":'); // truncated text
  const truncated = loadEntry(1, "manual", state.data);
  expect(truncated.ok).toBe(false);
  expect(["bad_json", "invalid"]).toContain(truncated.error.code);
  const future = JSON.parse(JSON.stringify(storage.get(dataKey(2, "manual"))));
  future.version = VERSION + 5;
  storage.set(dataKey(2, "manual"), future);
  const res = loadEntry(2, "manual", state.data);
  expect(res.ok).toBe(false);
  expect(res.error.code).toBe("future_version");
  expect(res.error.message).toContain(String(VERSION + 5));
  expect(loadEntry(4, "manual", state.data).ok).toBe(false);
  expect(loadEntry(1, "auto", state.data).error.code).toBe("not_a_save"); // empty
  expect(loadEntry(3, "manual", state.data).ok).toBe(true);
  // the meta is damaged but the data is fine: the slot screen shows a damaged slot, which still loads
  storage.set(metaKey(3, "manual"), "oops");
  expect(listSlots()[2].manual).toEqual({ meta: null, damaged: true });
  expect(loadEntry(3, "manual", state.data).ok).toBe(true);
});

test("autosave triggers: season (end of frame), timer, leaving; nothing when the town did not change; never without a slot", () => {
  storage.clear();
  const state = town(1);
  const run = { slot: 2, scenario: "sandbox", name: "", playSeconds: 0 };
  const saver = new Autosaver(state, run, { intervalSeconds: 60 });
  saver.update(0.016);
  expect(readMeta(2, "auto")).toBe(null);
  // a season: asked now, written at the next update
  saver.onSeason();
  expect(readMeta(2, "auto")).toBe(null);
  saver.update(0.016);
  expect(readMeta(2, "auto")).not.toBe(null);
  expect(saver.log).toEqual(["season"]);
  expect(readMeta(2, "manual")).toBe(null); // never the manual save
  // the timer: 60 seconds of play, but only when something changed
  for (let i = 0; i < 70; i++) saver.update(1);
  expect(saver.log).toEqual(["season"]);
  runDays(state, 1);
  for (let i = 0; i < 60; i++) saver.update(1);
  expect(saver.log).toEqual(["season", "timer"]);
  expect(readMeta(2, "auto").day).toBe(state.clock.day);
  // leaving: blur, suspend and quit write at once
  runDays(state, 1);
  saver.onLeave("blur");
  expect(saver.log[saver.log.length - 1]).toBe("blur");
  expect(readMeta(2, "auto").day).toBe(state.clock.day);
  runDays(state, 1);
  saver.onLeave("quit");
  expect(saver.log[saver.log.length - 1]).toBe("quit");
  // play time stops while the window is not in focus
  const before = run.playSeconds;
  saver.onLeave("suspend");
  saver.update(5);
  expect(run.playSeconds).toBe(before);
  saver.onReturn();
  saver.update(5);
  expect(run.playSeconds).toBe(before + 1); // one frame counts at most a second
  expect(readMeta(2, "auto").playSeconds).toBeGreaterThan(60);
  // a game without a slot is never saved
  storage.clear();
  const loose = new Autosaver(state, { slot: 0, scenario: "sandbox", name: "", playSeconds: 0 });
  loose.onSeason();
  loose.update(1);
  loose.onLeave("blur");
  expect(listSlots().every((s) => !s.auto && !s.manual)).toBe(true);
});

test("in the game scene: a season, losing the focus and closing the window autosave the slot the game was started from", () => {
  storage.clear();
  session.boot = { slot: 3, scenario: "sandbox", name: "" };
  game.load(GAME, { testMap: true, music: false });
  game.step(3);
  expect(scene.current).toBe(GAME);
  expect(session.boot).toBe(undefined); // taken
  const ctl = game.find("controller").behaviour;
  expect(ctl.run.slot).toBe(3);
  expect(readMeta(3, "auto")).toBe(null);
  // a season passes
  runDays(ctl.state, 10);
  game.step(2);
  expect(readMeta(3, "auto")).not.toBe(null);
  const dayOfSeasonSave = readMeta(3, "auto").revision;
  // the window loses the focus after something changed
  ctl.state.economy.apply({ coins: 5 }, "test");
  game.blur();
  game.step(1);
  expect(readMeta(3, "auto").revision).toBeGreaterThan(dayOfSeasonSave);
  expect(readMeta(3, "auto").coins).toBe(ctl.state.economy.coins);
  game.focus();
  ctl.state.economy.apply({ coins: 5 }, "test");
  expect(game.closeWindow()).toBe(true);
  expect(readMeta(3, "auto").coins).toBe(ctl.state.economy.coins);
  // loading that autosave in a new game screen gives the same town
  const want = ctl.state.hash();
  session.boot = { slot: 3, kind: "auto" };
  game.load(GAME, { testMap: true, music: false });
  game.step(3);
  expect(game.find("controller").behaviour.state.hash()).toBe(want);
});

test("cloud: the higher revision wins, then more play time, and the loser is kept as a backup", async () => {
  expect(pickWinner({ revision: 5, playSeconds: 1, hash: "a" }, { revision: 4, playSeconds: 999, hash: "b" })).toBe("local");
  expect(pickWinner({ revision: 4, playSeconds: 1, hash: "a" }, { revision: 5, playSeconds: 0, hash: "b" })).toBe("remote");
  expect(pickWinner({ revision: 4, playSeconds: 10, hash: "a" }, { revision: 4, playSeconds: 20, hash: "b" })).toBe("remote");
  expect(pickWinner({ revision: 4, playSeconds: 20, hash: "a" }, { revision: 4, playSeconds: 20, hash: "b" })).toBe("local");
  expect(pickWinner({ revision: 1, playSeconds: 1, hash: "a" }, { revision: 9, playSeconds: 9, hash: "a" })).toBe("same");

  storage.clear();
  game.platform.reset();
  expect(platform.has("cloudSave")).toBe(true);
  const a = town(1);
  const b = town(3);
  writeEntry(1, "manual", a, { playSeconds: 30 });
  writeEntry(2, "auto", b, { playSeconds: 90 });
  // 1. first sync: everything goes up
  let res = await syncCloud();
  expect(res.ok).toBe(true);
  expect(res.pushed.sort()).toEqual([cloudKey(1, "manual"), cloudKey(2, "auto")].sort());
  expect(await platform.cloud.list()).toContain("tm_slot_1");
  // 2. this device alone gets a newer save in slot 1: it wins and goes up
  const c = town(5);
  writeEntry(1, "manual", c, { playSeconds: 200 });
  res = await syncCloud();
  expect(res.pushed).toEqual([cloudKey(1, "manual")]);
  expect(res.conflicts).toEqual([cloudKey(1, "manual")]);
  expect(listConflicts().map((x) => [x.slot, x.kind, x.from])).toEqual([[1, "manual", "cloud"]]);
  expect((await platform.cloud.load("tm_slot_1")).meta.hash).toBe(c.hash());
  // 3. another device saved slot 1 later (higher revision): a fresh device takes the cloud copy and keeps its own as a backup
  const other = town(8);
  await platform.cloud.save("tm_slot_1", { revision: 500, meta: { ...readMeta(1, "manual"), revision: 500, hash: other.hash(), day: other.clock.day, playSeconds: 400 }, save: JSON.parse(JSON.stringify(storage.get(dataKey(1, "manual")))) });
  res = await syncCloud();
  expect(res.pulled).toEqual([cloudKey(1, "manual")]);
  expect(readMeta(1, "manual").revision).toBe(500);
  expect(storage.get("tm.rev")).toBeGreaterThanOrEqual(500);
  writeEntry(1, "manual", a);
  expect(readMeta(1, "manual").revision).toBeGreaterThan(500);
  // 4. the backup swaps back in
  expect(takeConflict(1, "manual")).toBe(true);
  expect(readMeta(1, "manual").revision).toBeGreaterThan(500);
  // 5. a damaged cloud value is skipped and replaced by the device's copy
  await platform.cloud.save("tm_slot_2_auto", { revision: 9, meta: 3, save: "no" });
  res = await syncCloud();
  expect(res.skipped).toEqual([cloudKey(2, "auto")]);
  expect(res.pushed).toContain(cloudKey(2, "auto"));
  // 6. nothing to do when both agree
  res = await syncCloud();
  expect(res.pushed.length + res.pulled.length).toBe(0);
});

test("cloud: no store service means no sync and no error; a sign-out is an answer, not a crash; a scene change stops the sync", async () => {
  storage.clear();
  game.platform.reset();
  writeEntry(1, "manual", town(1));
  game.platform.set({ backend: "none" });
  const none = await syncCloud();
  expect(none).toMatchObject({ ok: true, unavailable: true });
  game.platform.reset();
  game.platform.set({ signedIn: false });
  const out = await syncCloud();
  expect(out.ok).toBe(false);
  expect(out.error.code).toBe("notSignedIn");
  game.platform.reset();
  let calls = 0;
  const stopped = await syncCloud({ isCurrent: () => ++calls < 3 });
  expect(stopped.stopped).toBe(true);
});

test("a slot written by the first version of the game (tests/fixtures/slot_v1.json) is listed and loads", () => {
  storage.clear();
  storage.set(metaKey(2, "manual"), slotV1.meta);
  storage.set(dataKey(2, "manual"), slotV1.save);
  const entry = listSlots()[1].manual;
  expect(entry.meta.name).toBe("Old harbour");
  expect(entry.meta.version).toBe(1);
  expect(entry.meta.playSeconds).toBe(754);
  expect(latestEntry()).toMatchObject({ slot: 2, kind: "manual" });
  const res = loadEntry(2, "manual", createGame({ testMap: true }).data);
  expect(res.ok).toBe(true);
  expect(res.state.hash()).toBe(slotV1.meta.hash);
});
