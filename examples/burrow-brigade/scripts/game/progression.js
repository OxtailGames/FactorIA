// @ts-check
// Where the run goes after a shift: the ONE place that knows the order of the floors. results.js asks `plan(summary)` what
// comes next and calls `go(plan)` when the player presses the button; P4 puts the camp between the results and the next
// floor by changing `nextScene` here, and nothing else.
//
// The descent: three strata (generator.js STRATA), three floors each, nine floors in all. Floor 3 of the last stratum, the
// Magma Deep, is the Mole King's floor.
//   a shift that ended with "lift"  ->  the next floor; after floor 3 of a stratum, floor 1 of the next stratum;
//                                       after the boss floor: victory
//   a shift that ended "dark" or "allDown"  ->  the same floor again (a new mine of the same stratum and floor)
import { scene, session } from "factoria";
import { STRATA, isBossFloor, stratumInfo } from "./generator.js";
import { run, startRun } from "./run_state.js";
import * as saveFile from "./save.js";

/** The scene of a shift. */
export const SHIFT_SCENE = "scenes/shift.scene.json";
/** The camp between two floors (scripts/camp.js). */
export const CAMP_SCENE = "scenes/camp.scene.json";
/** The title. */
export const TITLE_SCENE = "scenes/menu.scene.json";
/** The loading screen that reads `session.nextScene` ahead of time. */
export const LOADING_SCENE = "scenes/loading.scene.json";
/** The join screen (scripts/join.js): every way into a run from the title passes it, then goes on to `session.afterJoin`. */
export const JOIN_SCENE = "scenes/join.scene.json";

/** Floors in one stratum (every stratum has the same number). */
export const FLOORS_PER_STRATUM = STRATA[0].floors;

/**
 * @typedef {object} Plan
 * @property {"next"|"retry"|"victory"} kind  next: a deeper floor; retry: the same floor again; victory: the King is down and the lift went up.
 * @property {number} stratum   The stratum to play next (for victory: the one just finished).
 * @property {number} floor     The floor to play next.
 * @property {boolean} newStratum  True when `stratum` is deeper than the one just played.
 * @property {boolean} boss     True when the next floor is the Mole King's.
 */

/**
 * What comes after a shift. Pure: it reads the summary and changes nothing.
 * @param {{outcome: string, stratum: number, floor: number}} summary  `run.lastShift`.
 * @returns {Plan}
 */
export function plan(summary) {
  const { stratum, floor } = summary;
  if (summary.outcome !== "lift") return { kind: "retry", stratum, floor, newStratum: false, boss: isBossFloor(stratum, floor) };
  if (isBossFloor(stratum, floor)) return { kind: "victory", stratum, floor, newStratum: false, boss: true };
  const last = floor >= stratumInfo(stratum).floors;
  const next = last ? { stratum: stratum + 1, floor: 1 } : { stratum, floor: floor + 1 };
  return { kind: "next", ...next, newStratum: last, boss: isBossFloor(next.stratum, next.floor) };
}

/**
 * The scene that follows the results of a plan: the camp between two floors; after a victory a new run starts at once (or the
 * title, for a daily dig, which is one try).
 */
export function nextScene(p) {
  if (p.kind !== "victory") return CAMP_SCENE;
  return run.mode === "daily" ? TITLE_SCENE : SHIFT_SCENE;
}

/**
 * Takes the run to the planned floor: sets `run.stratum` and `run.floor` and loads the next scene (the camp) through the
 * loading screen. A victory starts a fresh run at the top that keeps the slot with its play time and best depth, and writes it
 * to the slot (a daily dig is over: back to the title).
 * @param {Plan} p
 */
export function go(p) {
  const target = nextScene(p);
  if (p.kind === "victory") {
    if (target === TITLE_SCENE) {
      scene.load(TITLE_SCENE);
      return;
    }
    startRun({ slot: run.slot, playTime: run.playTime, bestDepth: run.bestDepth });
    saveFile.save();
  } else {
    run.stratum = p.stratum;
    run.floor = p.floor;
  }
  session.nextScene = target;
  scene.load(LOADING_SCENE);
}
