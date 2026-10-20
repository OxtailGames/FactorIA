import { test, expect, game } from "factoria:test";
import { ui, scene, storage, i18n, time, session, platform } from "factoria";
import * as progress from "../scripts/progress.js";
import * as saves from "../scripts/saves.js";
import { teleportOnto } from "./helpers/autoplay.js";
import v1 from "./fixtures/save_v1.json";

// Save slots, the level select and cloud saves. The menus are driven with the gamepad, like tests/menus.test.js.
const pad = () => game.gamepad(0);
const text = (id) => game.find(id).get("Text").text;
const button = (id) => game.find(id).get("Button").text;

const used = (counter, levels) => JSON.stringify({ version: 2, counter, levels });
const done = (bestTime, embers = [false, false, false]) => ({ completed: true, bestTime, embers });
const TWO_LEVELS = { "1-1": done(30, [true, true, true]), "1-2": done(41.25, [true, false, false]) };

/** A new run of the game: English, no slots, nothing finished, a signed-in fake store, the main menu open. */
function fresh() {
  for (const n of saves.SLOTS) storage.remove(`slot${n}`);
  storage.remove("lastSlot");
  storage.remove("settings");
  session.slot = null;
  session.menuTarget = null;
  progress.reset();
  i18n.setLanguage("en");
  time.scale = 1;
  game.platform.reset();
  game.load("scenes/menu.scene.json");
  game.step(2);
}

function waitForScene(path) {
  for (let i = 0; i < 12 && scene.current !== path; i++) game.step(1);
  expect(scene.current).toBe(path);
  game.step(3);
}

test("a new game: Play, an empty slot says New game, choosing it opens the level select with only 1-1 open", () => {
  fresh();
  pad().tap("A"); // Play
  expect(game.find("slots").active).toBe(true);
  expect(ui.focused.id).toBe("slot_1");
  expect(button("slot_1")).toBe("Slot 1: New game");
  expect(game.find("delete_1").get("Button").interactable).toBe(false); // nothing to delete
  pad().tap("A");
  expect(session.slot).toBe(1);
  expect(game.find("level_select").active).toBe(true);
  expect(ui.focused.id).toBe("lvl_1-1");
  expect(button("lvl_1-1")).toBe("1-1  First Light\nNot finished");
  expect(button("lvl_1-2")).toBe("1-2  The Gate\nLocked");
  expect(game.find("lvl_1-2").get("Button").interactable).toBe(false);
  expect(game.find("lvl_2-3").get("Button").interactable).toBe(false);
  pad().tap("A");
  waitForScene("scenes/levels/1-1.scene.json");
  expect(storage.get("slot1", null)).toBeNull(); // nothing is written until a level is finished
});

test("autosave: finishing a level writes the slot, and the level select shows the result", () => {
  fresh();
  pad().tap("A");
  pad().tap("A");
  pad().tap("A"); // 1-1
  waitForScene("scenes/levels/1-1.scene.json");
  teleportOnto(game.find("player"), "ember_1");
  teleportOnto(game.find("player"), "exit");
  game.step(2);
  const saved = JSON.parse(storage.get("slot1"));
  expect(saved).toMatchObject({ version: 2, counter: 1 });
  expect(Object.keys(saved.levels)).toEqual(["1-1"]);
  expect(saved.levels["1-1"].embers).toEqual([true, false, false]);
  expect(storage.get("lastSlot")).toBe(1);
  // Menu goes back to the level select of this slot
  pad().tap("DpadDown");
  pad().tap("DpadDown"); // Menu
  pad().tap("A");
  game.step(3);
  expect(scene.current).toBe("scenes/menu.scene.json");
  expect(game.find("level_select").active).toBe(true);
  expect(button("lvl_1-1")).toMatch(/^1-1  First Light\nEmbers 1\/3  0:0\d\.\d\d$/);
  expect(button("lvl_1-2")).toBe("1-2  The Gate\nNot finished");
  expect(game.find("lvl_1-2").get("Button").interactable).toBe(true);
  pad().tap("B"); // the slot screen
  expect(game.find("slots").active).toBe(true);
  expect(button("slot_1")).toMatch(/^Slot 1: 1\/6 levels  1\/18 embers  0:0\d\.\d\d$/);
  pad().tap("B"); // the main menu
  expect(game.find("main_menu").active).toBe(true);
});

test("continue a used slot: its summary, the level select numbers and unlocking", () => {
  fresh();
  storage.set("slot2", used(5, { ...TWO_LEVELS, "1-3": done(70, [true, true, false]) }));
  game.load("scenes/menu.scene.json");
  game.step(2);
  pad().tap("A"); // Play
  expect(button("slot_1")).toBe("Slot 1: New game");
  expect(button("slot_2")).toBe("Slot 2: 3/6 levels  6/18 embers  2:21.25");
  pad().tap("DpadDown");
  pad().tap("A");
  expect(session.slot).toBe(2);
  expect(progress.totalEmbers()).toBe(6);
  expect(button("lvl_1-2")).toBe("1-2  The Gate\nEmbers 1/3  0:41.25");
  expect(button("lvl_1-3")).toBe("1-3  Over the Wall\nEmbers 2/3  1:10.00");
  expect(button("lvl_2-1")).toBe("2-1  Down the Stairs\nNot finished");
  expect(button("lvl_2-2")).toBe("2-2  Drip and Dust\nLocked");
  pad().tap("DpadDown"); // the second world
  expect(ui.focused.id).toBe("lvl_2-1");
  pad().tap("A");
  waitForScene("scenes/levels/2-1.scene.json");
});

test("a locked level does not start", () => {
  fresh();
  pad().tap("A");
  pad().tap("A");
  expect(() => ui.focus(game.find("lvl_2-3"))).toThrow(/interactable/); // the pad cannot reach a locked level
  pad().tap("A");
  waitForScene("scenes/levels/1-1.scene.json");
});

test("the main menu's Continue resumes the last used slot", () => {
  fresh();
  expect(game.find("continue").active).toBe(false);
  storage.set("slot3", used(2, TWO_LEVELS));
  storage.set("lastSlot", 3);
  game.load("scenes/menu.scene.json");
  game.step(2);
  expect(game.find("continue").active).toBe(true);
  expect(button("continue")).toBe("Continue");
  pad().tap("DpadDown");
  expect(ui.focused.id).toBe("continue");
  pad().tap("A");
  expect(session.slot).toBe(3);
  expect(game.find("level_select").active).toBe(true);
  pad().tap("B"); // main menu again, not the slot screen
  expect(game.find("main_menu").active).toBe(true);
});

test("delete asks first: Keep it (the default, and B) deletes nothing, Delete empties the slot", () => {
  fresh();
  storage.set("slot1", used(1, TWO_LEVELS));
  game.load("scenes/menu.scene.json");
  game.step(2);
  pad().tap("A");
  pad().tap("DpadRight");
  expect(ui.focused.id).toBe("delete_1");
  pad().tap("A");
  expect(game.find("delete_confirm").active).toBe(true);
  expect(text("confirm_title")).toBe("Delete slot 1?");
  expect(ui.focused.id).toBe("confirm_no");
  pad().tap("A"); // Keep it
  expect(game.find("slots").active).toBe(true);
  expect(storage.get("slot1", null)).not.toBeNull();
  expect(ui.focused.id).toBe("delete_1"); // the focus came back
  pad().tap("A");
  pad().tap("B");
  expect(storage.get("slot1", null)).not.toBeNull();
  pad().tap("A"); // delete again
  pad().tap("DpadDown");
  expect(ui.focused.id).toBe("confirm_yes");
  pad().tap("A");
  expect(storage.get("slot1", null)).toBeNull();
  expect(game.find("slots").active).toBe(true);
  expect(button("slot_1")).toBe("Slot 1: New game");
  expect(game.find("delete_1").get("Button").interactable).toBe(false);
});

test("version 1 saves are migrated from the fixture file", () => {
  const r = saves.parse(JSON.stringify(v1));
  expect(r.ok).toBe(true);
  expect(r.data).toEqual({ version: 2, counter: 0, levels: { "1-1": done(41.2), "1-2": done(55.5) } });
  storage.set("slot1", JSON.stringify(v1));
  expect(saves.peek(1).summary).toEqual({ levels: 2, totalLevels: 6, embers: 0, totalEmbers: 18, time: 96.7 });
  expect(saves.choose(1)).toBe(true);
  expect(progress.isUnlocked("1-3")).toBe(true);
  expect(progress.of("1-2").bestTime).toBe(55.5);
  progress.record({ level: "1-3", time: 20, embers: [true, true, true], deaths: 0 }); // the next save is version 2
  const saved = JSON.parse(storage.get("slot1"));
  expect(saved.version).toBe(2);
  expect(Object.keys(saved.levels)).toEqual(["1-1", "1-2", "1-3"]);
  expect(saved.cleared).toBeUndefined();
  storage.remove("slot1");
  session.slot = null;
});

test("a damaged save does not crash the game: the slot says so and can be deleted", () => {
  fresh();
  storage.set("slot1", "{ this is not json");
  storage.set("slot2", JSON.stringify({ version: 99, counter: 3, levels: {} }));
  storage.set("slot3", JSON.stringify({ version: 2, levels: { "1-1": { completed: "yes" } } }));
  expect(saves.parse("{").reason).toMatch(/not valid JSON/);
  expect(saves.parse(JSON.stringify({ version: 99 })).reason).toMatch(/newer than this game/);
  expect(saves.parse("[1]").ok).toBe(false);
  game.load("scenes/menu.scene.json");
  game.step(2);
  expect(game.find("continue").active).toBe(false);
  pad().tap("A");
  for (const n of [1, 2, 3]) expect(button(`slot_${n}`)).toBe(`Slot ${n}: Damaged`);
  expect(text("slots_note")).toMatch(/Delete it/);
  pad().tap("A"); // choosing it does nothing
  expect(session.slot).toBeFalsy();
  expect(game.find("level_select").active).toBe(false);
  pad().tap("DpadRight");
  pad().tap("A");
  pad().tap("DpadDown");
  pad().tap("A");
  expect(storage.get("slot1", null)).toBeNull();
  expect(button("slot_1")).toBe("Slot 1: New game");
  pad().tap("A"); // and it works as a new game
  expect(session.slot).toBe(1);
});

test("a damaged storage.json: storage.corrupt is true, the slots start empty and saving still works", () => {
  fresh();
  game.setStorageText('{"slot1": "{\\"version\\": 2, "'); // a save file cut in the middle: it does not parse
  expect(storage.corrupt).toBe(true); // the engine keeps the bytes as storage.corrupt.json and starts with empty data
  expect(storage.keys().length).toBe(0);
  game.load("scenes/menu.scene.json");
  game.step(2);
  expect(game.find("continue").active).toBe(false);
  pad().tap("A");
  for (const n of [1, 2, 3]) expect(button(`slot_${n}`)).toBe(`Slot ${n}: New game`);
  pad().tap("A");
  expect(session.slot).toBe(1);
  progress.record({ level: "1-1", time: 30, embers: [true, true, true], deaths: 0 });
  expect(saves.peek(1).status).toBe("used"); // the next save is a valid storage again
  expect(saves.peek(1).summary.levels).toBe(1);
  game.setStorageText(null); // the tests after this one start from a good, empty storage
  expect(storage.corrupt).toBe(false);
});

test("cloud: a saved slot is uploaded when the player is signed in", async () => {
  fresh();
  saves.choose(2);
  progress.record({ level: "1-1", time: 30, embers: [true, true, true], deaths: 0 });
  const cloud = game.platform.state().fake.cloud;
  expect(JSON.parse(JSON.stringify(cloud.slot2 ?? null))).toBeTruthy();
  progress.record({ level: "1-2", time: 40, embers: [false, false, false], deaths: 0 });
  expect(await platform.cloud.list()).toEqual(["slot2"]);
  expect(JSON.parse(await platform.cloud.load("slot2")).counter).toBe(2);
});

test("cloud: the copy with the higher save counter wins when the slot screen opens", async () => {
  fresh();
  storage.set("slot1", used(2, { "1-1": done(30) }));
  storage.set("slot2", used(9, { "1-1": done(30) }));
  storage.set("slot3", "{ damaged");
  await platform.cloud.save("slot1", used(4, TWO_LEVELS)); // cloud ahead
  await platform.cloud.save("slot2", used(3, TWO_LEVELS)); // local ahead
  await platform.cloud.save("slot3", used(1, TWO_LEVELS)); // local damaged: the cloud copy replaces it
  pad().tap("A"); // Play: opens the slot screen, which syncs
  await saves.syncCloud();
  game.step(2);
  expect(button("slot_1")).toBe("Slot 1: 2/6 levels  4/18 embers  1:11.25"); // cloud copy
  expect(JSON.parse(storage.get("slot1")).counter).toBe(4);
  expect(saves.peek(2).data.counter).toBe(9); // local kept...
  expect(JSON.parse(await platform.cloud.load("slot2")).counter).toBe(9); // ...and uploaded
  expect(saves.peek(3).status).toBe("used");
});

test("cloud: failures never lose or block the local save", async () => {
  fresh();
  saves.choose(1);
  game.platform.respond("cloud.save", { error: "network" });
  progress.record({ level: "1-1", time: 30, embers: [true, false, false], deaths: 0 });
  await Promise.resolve();
  expect(JSON.parse(storage.get("slot1")).counter).toBe(1); // the failed upload changed nothing locally
  game.platform.set({ signedIn: false });
  progress.record({ level: "1-2", time: 30, embers: [false, false, false], deaths: 0 });
  expect(JSON.parse(storage.get("slot1")).counter).toBe(2);
  // a failed download keeps the local slots and does not throw
  game.platform.set({ signedIn: true });
  storage.set("slot3", used(7, TWO_LEVELS));
  game.platform.respond("cloud.load", { error: "network" });
  expect(await saves.syncCloud()).toBe(false);
  expect(saves.peek(3).data.counter).toBe(7);
  // the slot screen still works with the store down
  game.platform.set({ signedIn: false });
  game.load("scenes/menu.scene.json");
  game.step(2);
  pad().tap("A");
  pad().tap("A");
  expect(game.find("level_select").active).toBe(true);
  game.platform.set({ signedIn: true });
});

test("deleting a slot removes its cloud copy too, so it does not come back", async () => {
  fresh();
  storage.set("slot1", used(1, TWO_LEVELS));
  await platform.cloud.save("slot1", used(1, TWO_LEVELS));
  saves.remove(1);
  await Promise.resolve();
  expect(await platform.cloud.list()).toEqual([]);
  expect(await saves.syncCloud()).toBe(false);
  expect(saves.peek(1).status).toBe("empty");
});

test("the slot screen and the level select follow the language", () => {
  fresh();
  storage.set("slot1", used(1, TWO_LEVELS));
  game.load("scenes/menu.scene.json");
  game.step(2);
  pad().tap("A");
  i18n.setLanguage("es");
  game.step(2);
  expect(text("slots_title")).toBe("Partidas");
  expect(button("slot_1")).toBe("Partida 1: 2/6 niveles  4/18 ascuas  1:11.25");
  expect(button("slot_2")).toBe("Partida 2: Nueva partida");
  pad().tap("A");
  game.step(2);
  expect(text("select_title")).toBe("Elige un nivel");
  expect(button("lvl_1-1")).toBe("1-1  Primera luz\nAscuas 3/3  0:30.00");
  expect(button("lvl_2-1")).toBe("2-1  Escaleras abajo\nBloqueado");
});
