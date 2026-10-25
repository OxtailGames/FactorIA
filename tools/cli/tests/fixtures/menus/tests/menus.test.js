import { test, expect, game } from "factoria:test";
import { ui, input, storage, audio, scene, session, game as running } from "factoria";

// tests/recipe.test.js is the acceptance test (main menu -> options -> saved volume); these cover the rest.
// The menus are driven the way a player with only a gamepad would: D-pad to move the focus, A to press, B to go back.
// `game` is the test driver (steps, presses); `running` is the game's own object (paused, notices()).
const pad = game.gamepad(0);
const focused = () => (ui.focused ? ui.focused.id : null);
const shown = (id) => game.find(id).activeInHierarchy;

// Storage and session last for the whole test file: each test starts with no saved settings (or `saved`), the
// project's controls, and settings that scripts/settings.js has not applied yet.
function load(path, saved) {
  storage.clear();
  if (saved) storage.set("settings", saved);
  delete session.settingsApplied;
  input.resetBindings();
  game.load(path);
}

function mainMenu(saved) {
  load("scenes/menu.scene.json", saved);
  game.step(2);
  expect(focused()).toBe("play"); // the first button has autoFocus
}

test("saved settings are applied when the game starts", () => {
  mainMenu({ volume: { music: 0.3 }, bindings: { jump: ["K"] } });
  expect(audio.getVolume("music")).toBeCloseTo(0.3);
  expect(audio.getVolume("sfx")).toBeCloseTo(1);
  expect(input.bindings("jump")).toEqual(["K"]);
});

test("controls: a gamepad button rebinds jump and keeps its keyboard keys", () => {
  mainMenu();
  pad.tap("DpadDown");
  pad.tap("A"); // options
  pad.tap("DpadRight");
  pad.tap("DpadRight");
  pad.tap("A"); // the Controls tab
  pad.tap("DpadDown");
  expect(focused()).toBe("bind_jump"); // input.actions() order: the game's actions without the ui_* ones
  pad.tap("A");
  expect(game.find("bind_jump").get("Button").text).toContain("press a key or button");
  pad.tap("B"); // captured as the new binding, so it does not close the panel
  expect(shown("options")).toBe(true);
  expect(input.bindings("jump")).toEqual(["GamepadB", "Space", "W", "Up"]);
  expect(storage.get("settings").bindings.jump).toEqual(["GamepadB", "Space", "W", "Up"]);
  expect(focused()).toBe("bind_jump");
});

test("credits list the software inside the runtime", () => {
  mainMenu();
  pad.tap("DpadDown");
  pad.tap("DpadDown");
  pad.tap("A");
  expect(shown("credits")).toBe(true);
  const lines = game.find("credits_list").children.map((e) => e.get("Text").text);
  for (const n of running.notices()) expect(lines.some((l) => l.startsWith(n.name))).toBe(true);
  pad.tap("B");
  expect(focused()).toBe("credits_button");
});

test("Play goes through the loading screen to the level", () => {
  mainMenu();
  pad.tap("A");
  expect(scene.current).toBe("scenes/loading.scene.json");
  game.step(3);
  expect(scene.current).toBe("scenes/level.scene.json");
  expect(game.find("player")).toBeTruthy();
});

test("pause freezes the level, and Resume does not make the player jump", () => {
  load("scenes/level.scene.json");
  game.step(60);
  const player = game.find("player");
  const p0 = player.position.clone();
  pad.tap("Start");
  expect(running.paused).toBe(true);
  expect(focused()).toBe("resume");
  game.press("move_right");
  game.step(30);
  game.release("move_right");
  expect(player.position.x).toBeCloseTo(p0.x);
  pad.tap("A"); // Resume (A is also jump)
  expect(running.paused).toBe(false);
  expect(shown("pause_panel")).toBe(false);
  game.step(10);
  expect(player.position.y).toBeCloseTo(p0.y, 0);
});

test("pause -> options -> the pause key goes back one panel at a time", () => {
  load("scenes/level.scene.json");
  game.step(2);
  game.tap("pause");
  pad.tap("DpadDown");
  pad.tap("A");
  expect(shown("options")).toBe(true);
  game.tap("pause");
  expect(shown("options")).toBe(false);
  expect(focused()).toBe("pause_options");
  game.tap("pause");
  game.step(1);
  expect(running.paused).toBe(false);
});

// ---- colour filter (Camera.colorFilter) -----------------------------------------------------------------------------
const cameraFilter = () => game.find("camera").get("Camera").colorFilter;

test("options: the colour filter button cycles Camera.colorFilter and saves the choice", () => {
  mainMenu();
  expect(cameraFilter()).toBe("none");
  pad.tap("DpadDown");
  pad.tap("A"); // options, on the Video tab
  for (let i = 0; i < 6 && focused() !== "color_filter"; i++) pad.tap("DpadDown"); // the window rows are greyed out without a window
  expect(focused()).toBe("color_filter");
  expect(game.find("color_filter").get("Button").text).toBe("Color filter: off");
  pad.tap("A");
  expect(cameraFilter()).toBe("greyscale");
  expect(game.find("color_filter").get("Button").text).toBe("Color filter: greyscale");
  expect(storage.get("settings").colorFilter).toBe("greyscale");
  pad.tap("A");
  pad.tap("A");
  pad.tap("A");
  expect(cameraFilter()).toBe("deuteranopia");
  pad.tap("A");
  pad.tap("A"); // tritanopia, then it wraps around to none
  expect(cameraFilter()).toBe("none");
  expect(storage.get("settings").colorFilter).toBe("none");
});

test("a saved colour filter is on in every scene, also after a scene load", () => {
  load("scenes/menu.scene.json", { colorFilter: "protanopia" });
  game.step(2);
  expect(cameraFilter()).toBe("protanopia");
  load("scenes/level.scene.json", { colorFilter: "tritanopia" });
  game.step(2);
  expect(cameraFilter()).toBe("tritanopia");
  scene.load("scenes/menu.scene.json"); // a new scene has a new camera: the filter is set again
  game.step(2);
  expect(cameraFilter()).toBe("tritanopia");
});
