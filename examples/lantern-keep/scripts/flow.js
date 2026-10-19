// @ts-check
// Moving between scenes: levels go through the loading screen, the menu does not. Every "start this level" in the game
// (Play, Next, Retry) is startLevel().
import { game, scene, session } from "factoria";
import { find } from "./levels.js";

/** Starts level `id` through the loading screen. */
export function startLevel(id) {
  const level = find(id);
  if (!level) throw new Error(`startLevel: unknown level "${id}". See scripts/levels.js.`);
  game.paused = false; // time.scale outlives scene loads
  session.nextScene = level.scene;
  scene.load("scenes/loading.scene.json");
}

/** Back to the main menu. */
export function openMenu() {
  game.paused = false;
  scene.load("scenes/menu.scene.json");
}
