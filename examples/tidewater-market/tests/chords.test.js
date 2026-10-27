// Modifier chords (engine M31.18): Ctrl+Z / Ctrl+Y undo and redo (plain Z and Y still do), and Shift + click lays a road with two clicks.
import { test, expect, game } from "factoria:test";
import { scene, storage } from "factoria";
import { cellToWorld } from "../scripts/game/iso.js";
import { pickFromMenu } from "./ui_helper.js";

const GAME = "scenes/game.scene.json";

function playFromTitle() {
  storage.clear();
  game.platform.reset();
  game.load("scenes/menu.scene.json");
  game.step(3);
  game.click("play");
  game.step(2);
  game.click("slot_1_main");
  game.step(2);
  game.click("scenario_first_harbour");
  game.step(1);
  let guard = 0;
  while (scene.current !== GAME && guard++ < 300) game.step(1);
  expect(scene.current).toBe(GAME); // never act on the new scene before it is the current one
  game.step(3);
  return { ctl: game.find("controller").behaviour, rig: game.find("camera").behaviour };
}

const at = (rig, c, r) => {
  const [x, y] = cellToWorld(c, r);
  const [sx, sy] = rig.worldToScreen(x, y);
  return { x: sx, y: sy };
};

test("Shift + click lays a road with two clicks; Ctrl+Z and Ctrl+Y undo and redo it", () => {
  const { ctl, rig } = playFromTitle();
  const state = ctl.state;
  pickFromMenu("road");

  // Shift + click on the first end, move, a plain click on the second end.
  game.mouseMove(at(rig, 18, 18));
  game.step(1);
  game.keyDown("Shift");
  game.step(1);
  game.mouseDown("left");
  game.step(1);
  game.mouseUp("left");
  game.step(1);
  game.keyUp("Shift");
  game.step(1);
  expect(ctl.drag && ctl.drag.twoClicks).toBe(true); // nothing is built until the second click, though the button is up
  expect(state.list("road")).toHaveLength(0);
  game.mouseMove(at(rig, 22, 18));
  game.step(1);
  game.mouseDown("left");
  game.step(1);
  game.mouseUp("left");
  game.step(1);
  expect(scene.current).toBe(GAME);
  expect(state.list("road")).toHaveLength(5);
  expect(state.undoStack).toHaveLength(1);

  game.tapKey("Ctrl+Z");
  game.step(1);
  expect(state.list("road")).toHaveLength(0);
  game.tapKey("Ctrl+Y");
  game.step(1);
  expect(state.list("road")).toHaveLength(5);
  game.tapKey("Z"); // the plain keys keep working
  game.step(1);
  expect(state.list("road")).toHaveLength(0);
  game.tapKey("Y");
  game.step(1);
  expect(state.list("road")).toHaveLength(5);
});
