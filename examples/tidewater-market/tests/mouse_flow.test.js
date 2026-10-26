// The whole game with the mouse alone, from the title screen: Play -> loading -> the map, then lay a road by dragging, place
// buildings (rotating one with the button), demolish, undo and redo with the buttons. No key is pressed in this file.
import { test, expect, game } from "factoria:test";
import { scene, ui, storage } from "factoria";
import { cellToWorld } from "../scripts/game/iso.js";

const GAME = "scenes/game.scene.json";

/** Open the game scene the way a player does: Play, a new game in slot 1, the first scenario, then wait for the loading screen to hand over. */
function playFromTitle() {
  storage.clear(); // no saves: slot 1 is empty, so it offers a new game
  game.platform.reset();
  game.load("scenes/menu.scene.json");
  game.step(3);
  expect(scene.current).toBe("scenes/menu.scene.json");
  game.click("play"); // the save slots (P4): a new game in slot 1, of the first scenario, which starts like the plain game did
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

function drag(rig, from, to) {
  game.mouseMove(at(rig, from[0], from[1]));
  game.step(1);
  game.mouseDown("left");
  game.step(1);
  // move in a few steps like a hand does
  for (let i = 1; i <= 4; i++) {
    const c = Math.round(from[0] + ((to[0] - from[0]) * i) / 4);
    const r = Math.round(from[1] + ((to[1] - from[1]) * i) / 4);
    game.mouseMove(at(rig, c, r));
    game.step(1);
  }
  game.mouseUp("left");
  game.step(1);
}

test("title screen to a small town, mouse only", () => {
  const { ctl, rig } = playFromTitle();
  const state = ctl.state;
  expect(state.economy.coins).toBe(1000);
  expect(ctl.tool.kind).toBe("none");
  expect(game.find("coins_text").get("Text").text).toBe("1000");
  expect(game.find("hud_date").get("Text").text).toBe("Spring 1, year 1");

  // 1. a road along row 18, laid by dragging
  game.click("tool_road");
  expect(ctl.tool).toEqual({ kind: "build", type: "road", rot: 0 });
  drag(rig, [18, 18], [22, 18]);
  expect(state.list("road")).toHaveLength(5);
  expect(state.economy.coins).toBe(1000 - 10);
  expect(game.find("coins_text").get("Text").text).toBe("990");
  expect(state.undoStack).toHaveLength(1);

  // 2. a right click puts the tool away; a click on the map then only looks
  game.click(at(rig, 20, 20), "right");
  game.step(1);
  expect(ctl.tool.kind).toBe("none");
  game.click(at(rig, 20, 20));
  game.step(1);
  expect(state.list()).toHaveLength(5);

  // 3. houses
  game.click("tool_house");
  game.click(at(rig, 21, 20));
  game.click(at(rig, 22, 20));
  expect(state.list("house")).toHaveLength(2);
  expect(state.economy.coins).toBe(990 - 80);
  expect(state.economy.get("wood")).toBe(52);

  // pressing a palette button while a tool is active builds nothing
  game.click("btn_rotate");
  expect(state.list()).toHaveLength(7);
  expect(ctl.tool.rot).toBe(1); // the rotation is kept when the next building is picked

  // 4. a warehouse needs a road at its door: turn it (it faces +r now) until it faces the road row above it, then place it
  game.click("tool_warehouse");
  game.mouseMove(at(rig, 19, 20));
  game.step(2);
  expect(ctl.check.ok).toBe(false); // no road in front of this door
  expect(ctl.check.reasons[0].code).toBe("no_road");
  expect(game.find("status_text").get("Text").text).toBe("Needs a road in front of its door.");
  game.click("btn_rotate");
  game.click("btn_rotate");
  expect(ctl.tool.rot).toBe(3);
  game.mouseMove(at(rig, 19, 20));
  game.step(2);
  expect(ctl.check.ok).toBe(true);
  game.click(at(rig, 19, 20));
  expect(state.list("warehouse")).toHaveLength(1);
  const wh = state.list("warehouse")[0];
  expect([wh.x, wh.y, wh.w, wh.h, wh.rot]).toEqual([19, 19, 2, 3, 3]);
  expect(state.economy.get("planks")).toBe(2);
  // a workshop needs 6 planks and 2 are left: the click builds nothing and the toast says what is missing
  game.click("tool_workshop");
  game.click(at(rig, 21, 21));
  expect(state.list("workshop")).toHaveLength(0);
  expect(game.find("toast").get("Text").text).toBe("Not enough: you lack 4 planks.");

  // 5. demolish a house: half of it comes back
  game.click("tool_demolish");
  expect(ctl.tool.kind).toBe("demolish");
  const coins = state.economy.coins;
  game.click(at(rig, 21, 20));
  expect(state.list("house")).toHaveLength(1);
  expect(state.economy.coins).toBe(coins + 20);

  // 6. undo and redo with the buttons (the clock is paused so the town does not move between the two hashes)
  state.clock.setSpeed(0);
  const hash = state.hash();
  expect(ui.rectOf("btn_undo")).not.toBeNull();
  game.click("btn_undo");
  expect(state.list("house")).toHaveLength(2);
  expect(state.economy.coins).toBe(coins);
  expect(game.find("btn_redo").get("Button").interactable).toBe(true);
  game.click("btn_redo");
  expect(state.hash()).toBe(hash);
  expect(game.find("btn_redo").get("Button").interactable).toBe(false);

  // the screen as the player sees it
  game.step(5);
  game.screenshot(".factoria/tmp/mouse_flow.png");
});

test("a new game scene starts with the state of its seed, and the scene props choose the map", () => {
  game.load(GAME, { seed: 7 });
  game.step(2);
  const ctl = game.find("controller").behaviour;
  expect(ctl.state.map.seed).toBe(7);
  expect(ctl.state.map.hash()).toBe("1664d8bc");
  game.load(GAME, { testMap: true });
  game.step(2);
  expect(game.find("controller").behaviour.state.map.width).toBe(12);
});
