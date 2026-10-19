// @ts-check
// Moving between scenes: levels go through the loading screen, the menu does not. Every "start this level" in the game
// (Play, Next, Retry) is startLevel().
import { game, scene, session, time } from "factoria";
import { find } from "./levels.js";

/** Starts level `id` through the loading screen. */
export function startLevel(id) {
  const level = find(id);
  if (!level) throw new Error(`startLevel: unknown level "${id}". See scripts/levels.js.`);
  game.paused = false; // time.scale outlives scene loads
  time.scale = 1;
  session.nextScene = level.scene;
  scene.load("scenes/loading.scene.json");
}

/** Back to the main menu (`toLevelSelect`: straight to the level select of the current save slot). */
export function openMenu(toLevelSelect = false) {
  game.paused = false;
  time.scale = 1;
  session.menuTarget = toLevelSelect ? "level_select" : null; // main_menu.js opens it when a save slot is chosen
  scene.load("scenes/menu.scene.json");
}
