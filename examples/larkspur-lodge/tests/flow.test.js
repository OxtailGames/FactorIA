// The flow of the game: title -> loading -> the lodge -> pause -> title, and a new game starting clean.
import { test, expect, game } from "factoria:test";
import { scene, session } from "factoria";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";
import { porter } from "./helpers/lodge.js";

/** Steps until `path` is the current scene (the loading screen takes a few frames), at most `max` frames. */
function waitForScene(path, max = 400) {
  for (let i = 0; i < max && scene.current !== path; i++) game.step(1);
  return scene.current === path;
}

test("Play goes through the loading screen to the hall, with a clean story and no items", () => {
  game.resetState();
  story.set("open.library_door");
  items.add("library_key", "test");
  scene.load("scenes/menu.scene.json");
  game.step(3);
  expect(scene.current).toBe("scenes/menu.scene.json");
  game.click(game.find("play"));
  game.step(2);
  expect(scene.current).toBe("scenes/loading.scene.json");
  expect(waitForScene("scenes/ground.scene.json")).toBe(true);
  game.step(30);
  expect(story.has("open.library_door")).toBe(false);
  expect(items.has("library_key")).toBe(false);
  expect(porter().behaviour.grounded).toBe(true);
  expect(session.area).toBe("ground");
});

test("the pause action opens the pause menu and stops the porter; Resume gives the game back", () => {
  game.resetState();
  game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
  game.step(30);
  expect(game.paused).toBe(false);
  game.tap("pause");
  game.step(3);
  expect(game.paused).toBe(true);
  expect(game.find("pause_panel").active).toBe(true);
  const z0 = porter().position.z;
  game.press("move_forward");
  game.step(30);
  game.release("move_forward");
  expect(Math.abs(porter().position.z - z0)).toBeLessThan(0.05); // paused: the keys move nobody
  game.click(game.find("resume"));
  game.step(5);
  expect(game.paused).toBe(false);
  game.press("move_forward");
  game.step(30);
  expect(z0 - porter().position.z).toBeGreaterThan(0.5);
});

test("pause -> Main menu returns to the title screen and the game runs again", () => {
  game.resetState();
  game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
  game.step(30);
  game.tap("pause");
  game.step(3);
  expect(game.paused).toBe(true);
  game.click(game.find("to_main_menu"));
  game.step(5);
  expect(scene.current).toBe("scenes/menu.scene.json");
  expect(game.paused).toBe(false);
  expect(game.find("play").active).toBe(true);
});
