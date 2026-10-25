// Helpers for the P4 tests: the walk from the results through the camp to the next shift, and a title that starts clean.
import { expect, game } from "factoria:test";
import { scene, storage } from "factoria";
import * as players from "../../scripts/game/players.js";
import * as saveFile from "../../scripts/game/save.js";

export const SHIFT = "scenes/shift.scene.json";
export const CAMP = "scenes/camp.scene.json";
export const TITLE = "scenes/menu.scene.json";
export const LOADING = "scenes/loading.scene.json";
export const JOIN = "scenes/join.scene.json";

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

function tapKey(name) {
  game.keyDown(name);
  game.step(1);
  game.keyUp(name);
  game.step(1);
}

/** After a way into a run on the title (a slot, Continue, the daily dig, a seed code): through the loading screen to the join
 * screen, where the keyboard joins and starts, then through the loading screen again to `file` (the shift or the camp). */
export function enterRun(file) {
  arrive(JOIN, 40);
  tapKey("Enter"); // the keyboard joins
  tapKey("Enter"); // the keyboard player is the host: the run begins
  arrive(file, 40);
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
  enterRun(SHIFT);
}
