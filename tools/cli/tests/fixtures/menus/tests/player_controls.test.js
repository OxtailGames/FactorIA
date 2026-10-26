import { test, expect, game } from "factoria:test";
import { input, storage, session, scene } from "factoria";
import * as settings from "../scripts/settings.js";

// The Controls tab of a game with local multiplayer: the options script's `players` property (docs/MENUS.md, Options).
// A scene made here holds the options panel with `players: 2`; the main menu's own panel keeps the default 1.
const pad = game.gamepad(0);

function twoPlayerOptions() {
  storage.clear();
  delete session.settingsApplied;
  input.resetBindings();
  for (let i = 0; i < 4; i++) input.player(i).use(null);
  game.loadJson({
    format: "factoria.scene/1",
    entities: [
      { id: "camera", components: { Transform: { position: [0, 0, 0] }, Camera: { projection: "orthographic", orthoSize: 360, primary: true } } },
      { id: "options", prefab: "prefabs/ui/options.prefab.json", components: { Script: { props: { players: 2 } } } },
    ],
  });
  const current = scene.current;
  game.step(3);
  expect(scene.current).toBe(current); // the panel built itself in this scene
}

const text = (id) => game.find(id).get("Button").text;

test("players 2: a Player button cycles the players and the rows show each player's keys and pad buttons", () => {
  twoPlayerOptions();
  game.click("tab_controls");
  expect(game.find("controls_player")).toBeTruthy();
  expect(text("controls_player")).toBe("Player 1");
  expect(text("bind_jump")).toBe("Jump: Space / W / Up  |  A");
  game.click("controls_player");
  game.step(1);
  expect(text("controls_player")).toBe("Player 2");
  game.click("controls_player");
  game.step(1);
  expect(text("controls_player")).toBe("Player 1");
});

test("players 2: a key rebinds the shown player only, is saved by player, and Reset puts it back", () => {
  twoPlayerOptions();
  game.click("tab_controls");
  game.click("controls_player"); // Player 2
  game.step(1);
  game.click("bind_jump");
  game.step(2);
  game.keyDown("K");
  game.step(2);
  game.keyUp("K");
  game.step(2);
  expect(input.player(1).bindings("jump", "keys")).toEqual(["K"]);
  expect(input.player(0).bindings("jump", "keys")).toEqual(["Space", "W", "Up"]);
  expect(input.bindings("jump")).toEqual(["Space", "W", "Up", "GamepadA"]); // the global bindings are not touched
  expect(storage.get("settings").playerBindings["1"]).toEqual({ keys: { jump: ["K"] } });
  expect(text("bind_jump")).toBe("Jump: K  |  A");
  game.click("reset_controls");
  game.step(1);
  expect(input.player(1).bindings("jump", "keys")).toEqual(["Space", "W", "Up"]);
  expect(storage.get("settings").playerBindings["1"]).toBeUndefined();
});

test("players 2: a gamepad button replaces the pad list of that player and keeps its keys", () => {
  twoPlayerOptions();
  game.click("tab_controls");
  game.click("bind_jump");
  game.step(2);
  pad.press("Y");
  game.step(2);
  pad.release("Y");
  game.step(2);
  expect(input.player(0).bindings("jump", "pad")).toEqual(["GamepadY"]);
  expect(input.player(0).bindings("jump", "keys")).toEqual(["Space", "W", "Up"]);
  expect(input.player(1).bindings("jump", "pad")).toEqual(["GamepadA"]);
});

test("settings.apply puts the saved bindings of every player back, and logs what the engine refused", () => {
  storage.clear();
  input.resetBindings();
  for (let i = 0; i < 4; i++) input.player(i).reset();
  const s = settings.load();
  s.playerBindings = { 1: { keys: { jump: ["K"] } }, 2: { keys: { fly: ["Space"] } } };
  settings.apply(s);
  expect(input.player(1).bindings("jump", "keys")).toEqual(["K"]);
  expect(input.player(2).bindings("jump", "keys")).toEqual(["Space", "W", "Up"]);
  expect(input.player(0).bindings("jump", "keys")).toEqual(["Space", "W", "Up"]);
});

test("a game with one player keeps the plain Controls tab: no Player button, the global bindings", () => {
  storage.clear();
  delete session.settingsApplied;
  input.resetBindings();
  game.load("scenes/menu.scene.json");
  game.step(2);
  game.click("options_button");
  game.click("tab_controls");
  expect(game.find("controls_player")).toBeFalsy();
  expect(text("bind_jump")).toBe("Jump: Space");
});
