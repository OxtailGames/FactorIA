import { test, expect, game } from "factoria:test";
import { ui, scene, storage, audio, i18n, time, session } from "factoria";
import * as progress from "../scripts/progress.js";
import { listen, teleportOnto } from "./helpers/autoplay.js";
import en from "../locales/en.json";
import es from "../locales/es.json";

// Each test file starts on the main menu (factoria.json mainScene) with empty storage and session.
// The menus are driven with the gamepad only, like a player on a couch would.
const pad = () => game.gamepad(0);
const text = (id) => game.find(id).get("Text").text;
const button = (id) => game.find(id).get("Button").text;

/** Every test starts like a new run of the game: English, nothing saved, nothing finished, not paused. */
function fresh() {
  progress.reset();
  session.slot = null;
  session.menuTarget = null;
  for (const n of [1, 2, 3]) storage.remove(`slot${n}`);
  storage.remove("lastSlot");
  storage.remove("settings");
  i18n.setLanguage("en");
  time.scale = 1;
}

/** Plays through the loading screen: the level scene is current a few frames after Play, Next or Retry. */
function waitForScene(path) {
  for (let i = 0; i < 12 && scene.current !== path; i++) game.step(1);
  expect(scene.current).toBe(path);
  game.step(3); // the new scene's scripts start
}

test("the main menu shows the game's name and the first button has the focus", () => {
  fresh();
  game.step(2);
  expect(scene.current).toBe("scenes/menu.scene.json");
  expect(text("title")).toBe("Lantern Keep");
  expect(ui.focused.id).toBe("play");
  expect(game.find("shop_button")).not.toBeNull(); // the store package adds Achievements, Leaderboards and Shop
});

test("gamepad only: Play, a slot, then a level starts it through the loading screen", () => {
  fresh();
  game.step(2);
  pad().tap("A"); // Play: the save slots (tests/saves.test.js)
  pad().tap("A"); // slot 1: the level select
  pad().tap("A"); // 1-1
  waitForScene("scenes/levels/1-1.scene.json");
  expect(text("hud_level")).toBe("1-1  First Light");
});

test("gamepad only: pause with Start, resume with A; the player does not jump when Resume is clicked", () => {
  fresh();
  game.load("scenes/levels/1-1.scene.json");
  game.step(60);
  const player = game.find("player");
  const y0 = player.position.y;
  pad().tap("Start");
  expect(time.scale).toBe(0);
  expect(game.find("pause_panel").active).toBe(true);
  expect(ui.focused.id).toBe("resume");
  const t = game.find("level").behaviour.time;
  game.step(30);
  expect(game.find("level").behaviour.time).toBe(t); // the level is frozen
  pad().tap("A"); // Resume
  game.step(3);
  expect(time.scale).toBe(1);
  expect(game.find("pause_panel").active).toBe(false);
  game.step(5);
  expect(player.position.y).toBeLessThan(y0 + 2); // no jump came out of the click
  // the pause button also closes the pause menu
  pad().tap("Start");
  expect(time.scale).toBe(0);
  pad().tap("Start");
  game.step(3);
  expect(time.scale).toBe(1);
});

test("gamepad only: pause menu -> Main menu goes back to the title screen", () => {
  fresh();
  game.load("scenes/levels/1-1.scene.json");
  game.step(5);
  pad().tap("Start");
  pad().tap("DpadDown"); // Options
  pad().tap("DpadDown"); // Main menu
  pad().tap("A");
  game.step(3);
  expect(scene.current).toBe("scenes/menu.scene.json");
  expect(time.scale).toBe(1);
});

test("gamepad only: Options -> Language switches the whole game to Spanish and back", () => {
  fresh();
  game.load("scenes/menu.scene.json");
  game.step(2);
  pad().tap("DpadDown"); // Options
  pad().tap("A");
  pad().tap("DpadRight"); // Audio
  pad().tap("DpadRight"); // Controls
  pad().tap("DpadRight"); // Language
  pad().tap("A");
  pad().tap("DpadDown"); // the language button
  expect(ui.focused.id).toBe("language");
  expect(button("language")).toBe("Language: English");
  pad().tap("A");
  game.step(2);
  expect(i18n.language).toBe("es");
  expect(button("language")).toBe("Idioma: Español");
  expect(storage.get("settings").language).toBe("es");
  pad().tap("B"); // back to the main menu
  expect(ui.focused.id).toBe("options_button");
  expect(button("play")).toBe("Jugar");
  expect(button("options_button")).toBe("Opciones");
  expect(button("credits_button")).toBe("Créditos");
  expect(button("quit")).toBe("Salir");
  expect(text("title")).toBe("Lantern Keep");
  // a level started now is in Spanish: HUD, level name
  pad().tap("DpadUp");
  pad().tap("A"); // Play
  pad().tap("A"); // slot 1
  pad().tap("A"); // 1-1
  waitForScene("scenes/levels/1-1.scene.json");
  expect(i18n.language).toBe("es");
  expect(text("hud_level")).toBe("1-1  Primera luz");
  expect(text("hud_embers")).toBe("Ascuas 0/3");
  expect(text("hud_timer")).toMatch(/^Tiempo 0:00\.\d\d$/);
  // the pause menu too
  pad().tap("Start");
  expect(text("pause_title")).toBe("Pausa");
  expect(button("resume")).toBe("Continuar");
  // and the level end panel
  pad().tap("A");
  game.step(3);
  teleportOnto(game.find("player"), "exit");
  expect(text("end_title")).toBe("Nivel completado");
  expect(text("end_embers")).toBe("Ascuas: 0/3");
  expect(button("end_next")).toBe("Siguiente");
  i18n.setLanguage("en");
  game.step(2);
  expect(text("end_title")).toBe("Level complete");
  expect(text("end_embers")).toBe("Embers: 0/3");
});

test("every string of the English table has a Spanish one", () => {
  const keys = (o, prefix = "") => Object.entries(o).flatMap(([k, v]) => (typeof v === "object" ? keys(v, `${prefix}${k}.`) : [`${prefix}${k}`]));
  expect(keys(es).sort()).toEqual(keys(en).sort());
});

test("gamepad only: the music volume of Options is applied and saved (the menu recipe)", () => {
  fresh();
  game.load("scenes/menu.scene.json");
  game.step(2);
  pad().tap("DpadDown");
  pad().tap("A");
  pad().tap("DpadRight"); // Audio
  pad().tap("A");
  pad().tap("DpadDown"); // Master
  pad().tap("DpadDown"); // Music
  pad().tap("DpadRight"); // 0.6 -> 0.7
  pad().tap("B");
  expect(ui.focused.id).toBe("options_button");
  expect(audio.getVolume("music")).toBeCloseTo(0.7);
  expect(storage.get("settings").volume.music).toBeCloseTo(0.7);
});

test("credits list the game, then the software inside the runtime", () => {
  fresh();
  game.load("scenes/menu.scene.json");
  game.step(2);
  pad().tap("DpadDown");
  pad().tap("DpadDown"); // Credits
  pad().tap("A");
  game.step(2);
  const lines = game.find("credits_list").children.map((c) => c.get("Text").text);
  expect(lines[0]).toBe("Lantern Keep");
  expect(lines[1]).toBe("Lantern Keep: the FactorIA reference game.");
  expect(lines[2]).toBe("Made with FactorIA");
  expect(lines.length).toBeGreaterThan(6);
  pad().tap("B");
  expect(ui.focused.id).toBe("credits_button");
});

test("gamepad only: the level end panel shows the result and Next loads the next level", () => {
  fresh();
  game.load("scenes/levels/1-1.scene.json");
  game.step(30);
  const seen = listen("level_completed");
  teleportOnto(game.find("player"), "ember_1"); // on its ledge
  teleportOnto(game.find("player"), "ember_3");
  game.step(60);
  teleportOnto(game.find("player"), "exit");
  game.step(2);
  expect(seen.level_completed).toHaveLength(1);
  expect(text("end_title")).toBe("Level complete");
  expect(text("end_time")).toMatch(/^Time: 0:0\d\.\d\d$/);
  expect(text("end_best")).toMatch(/^Best time: 0:0\d\.\d\d$/);
  expect(game.find("end_new_best").active).toBe(true); // the first run is a record
  expect(text("end_embers")).toBe("Embers: 2/3");
  expect(text("end_deaths")).toBe("Deaths: 0");
  expect(ui.focused.id).toBe("end_next");
  expect(button("end_next")).toBe("Next");
  expect(button("end_retry")).toBe("Retry");
  expect(button("end_menu")).toBe("Menu");
  expect(time.scale).toBe(0);
  pad().tap("Start"); // the pause button does nothing now
  expect(game.find("pause_panel").active).toBe(false);
  pad().tap("A"); // Next
  waitForScene("scenes/levels/1-2.scene.json");
  expect(time.scale).toBe(1);
  expect(text("hud_level")).toBe("1-2  The Gate");
  expect(progress.isUnlocked("1-2")).toBe(true);
});

test("gamepad only: Retry restarts the level and Menu goes to the title screen; a slower run is not a new best", () => {
  fresh();
  progress.record({ level: "1-1", time: 0.2, embers: [false, false, false], deaths: 0 });
  game.load("scenes/levels/1-1.scene.json");
  game.step(30);
  teleportOnto(game.find("player"), "exit");
  game.step(2);
  expect(game.find("end_new_best").active).toBe(false);
  expect(text("end_best")).toBe("Best time: 0:00.20");
  pad().tap("DpadDown"); // Retry
  expect(ui.focused.id).toBe("end_retry");
  pad().tap("A");
  waitForScene("scenes/levels/1-1.scene.json");
  expect(game.find("level").behaviour.time).toBeLessThan(0.2);
  expect(game.find("level_end").active).toBe(false);
  teleportOnto(game.find("player"), "exit");
  game.step(2);
  pad().tap("DpadDown");
  pad().tap("DpadDown"); // Menu
  expect(ui.focused.id).toBe("end_menu");
  pad().tap("A");
  game.step(2);
  expect(scene.current).toBe("scenes/menu.scene.json");
  expect(time.scale).toBe(1);
});

test("the last level has no Next button", () => {
  fresh();
  game.load("scenes/levels/2-3.scene.json");
  game.step(30);
  teleportOnto(game.find("player"), "exit");
  game.step(2);
  expect(game.find("end_next").active).toBe(false);
  expect(ui.focused.id).toBe("end_retry");
});
