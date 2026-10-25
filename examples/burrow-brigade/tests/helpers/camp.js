// Helpers for the P4 tests: the walk from the results through the camp to the next shift, and a title that starts clean.
import { expect, game } from "factoria:test";
import { scene, storage } from "factoria";
import * as players from "../../scripts/game/players.js";
import * as saveFile from "../../scripts/game/save.js";

export const SHIFT = "scenes/shift.scene.json";
export const CAMP = "scenes/camp.scene.json";
export const TITLE = "scenes/menu.scene.json";
export const LOADING = "scenes/loading.scene.json";

/** Empties the three slots, their cloud copies and sync records (the storage and the fake store of a test file are shared by its tests). */
export function clearSlots() {
  for (let n = 1; n <= saveFile.SLOT_COUNT; n++) {
    saveFile.erase(n);
    storage.remove(`burrow.cloudBase.${n}`);
    storage.remove(`burrow.backup.${n}`);
  }
  game.platform.reset();
}

/** Waits for the loading screen to hand over to `file`. */
export function arrive(file, frames = 40) {
  game.step(5);
  game.step(frames);
  expect(scene.current).toBe(file);
  game.step(3);
}

/** On the results screen: the button goes to the camp. */
export function toCamp() {
  game.click("again");
  arrive(CAMP, 40);
}

/** In the camp: down to the next shift. */
export function descend() {
  game.click("descend");
  arrive(SHIFT, 40);
}

/** On the results screen: through the camp to the next shift, buying nothing. */
export function nextShift() {
  toCamp();
  descend();
}

/** From the title to a shift in progress in slot `n` (a new run when it is empty). */
export function startInSlot(n = 1) {
  players.clear();
  game.load(TITLE);
  game.step(5);
  game.click("play");
  game.step(2);
  game.click(`slot_${n}`);
  arrive(SHIFT, 40);
}
