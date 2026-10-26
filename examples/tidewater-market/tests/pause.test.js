// Escape pauses the game over the map and the pause menu works with the mouse; the map does not react while it is open.
import { test, expect, game } from "factoria:test";
import { scene } from "factoria";

test("pause menu: Escape opens it, Resume closes it, and a click on the panel builds nothing", () => {
  game.load("scenes/game.scene.json", { testMap: true });
  game.step(3);
  const ctl = game.find("controller").behaviour;
  game.click("btn_build");
  expect(game.find("build_bar").active).toBe(true);
  // the first Escape only puts the open build menu away
  game.press("pause");
  game.press("escape"); // the Escape key is both actions
  game.step(2);
  game.release("pause");
  game.release("escape");
  game.step(1);
  expect(game.paused).toBe(false);
  expect(game.find("build_bar").active).toBe(false);
  game.press("pause");
  game.step(2);
  game.release("pause");
  game.step(1);
  expect(game.paused).toBe(true);
  expect(game.find("pause_panel").active).toBe(true);
  game.click("resume");
  game.step(3);
  expect(game.paused).toBe(false);
  expect(scene.current).toBe("scenes/game.scene.json");
  expect(ctl.state.list()).toHaveLength(0);
});
