// @ts-check
// THE place results are recorded: the main menu, the level end panel and every later feature (save slots, the level
// select, store stats) read and write progress through these functions only. It lives in `session`; saves.js writes it to the
// chosen save slot after every record(). The data is a plain JSON object, so a save file can hold it as it is:
//
//   { levels: { "1-1": { completed: true, bestTime: 41.2, embers: [true, false, true] } } }
//
// A level that was never finished has no entry. `embers` are the ones found in ANY run (they only ever turn true).
import { session } from "factoria";
import { LEVELS, EMBERS_PER_LEVEL, find } from "./levels.js";
import { save } from "./saves.js";

function data() {
  if (!session.progress) session.progress = { levels: {} };
  return session.progress;
}

/** A copy of the whole progress object (changing it changes nothing: use record()). */
export function get() {
  return JSON.parse(JSON.stringify(data()));
}

/** Replaces the whole progress, for the code that loads a save. An object without `levels` is an empty progress. */
export function load(saved) {
  session.progress = saved && typeof saved === "object" && saved.levels ? JSON.parse(JSON.stringify(saved)) : { levels: {} };
}

/** Forgets everything. */
export function reset() {
  session.progress = { levels: {} };
}

/** The result of a level for `id` (completed false and no best time when it was never finished). */
export function of(id) {
  const e = data().levels[id];
  return e
    ? { completed: !!e.completed, bestTime: e.bestTime ?? null, embers: [...e.embers] }
    : { completed: false, bestTime: null, embers: Array(EMBERS_PER_LEVEL).fill(false) };
}

/**
 * Records a finished level: `{ level, time, embers: [bool, bool, bool], deaths }`, the payload of the `level_completed`
 * event. Keeps the best time and every ember ever found. Returns `{ firstCompletion, newBest, bestTime, previousBest }`.
 */
export function record(result) {
  if (!find(result.level)) throw new Error(`progress.record: unknown level "${result.level}". Levels: ${LEVELS.map((l) => l.id).join(", ")}.`);
  const before = of(result.level);
  const bestTime = before.bestTime === null ? result.time : Math.min(before.bestTime, result.time);
  data().levels[result.level] = {
    completed: true,
    bestTime,
    embers: before.embers.map((found, i) => found || !!result.embers[i]),
  };
  save(); // the chosen save slot (scripts/saves.js), if any
  return {
    firstCompletion: !before.completed,
    newBest: before.bestTime === null || result.time < before.bestTime,
    bestTime,
    previousBest: before.bestTime,
  };
}

/** True when the level was finished at least once. */
export function isCompleted(id) {
  return of(id).completed;
}

/** `1-1` is always open; any other level opens when the one before it was finished. */
export function isUnlocked(id) {
  const i = LEVELS.findIndex((l) => l.id === id);
  return i === 0 || (i > 0 && isCompleted(LEVELS[i - 1].id));
}

/** Embers found in all levels (at most EMBERS_PER_LEVEL * LEVELS.length). */
export function totalEmbers() {
  return Object.values(data().levels).reduce((n, e) => n + e.embers.filter(Boolean).length, 0);
}

/** What the main menu's Play starts: the first unlocked level that is not finished (the last level when all are). */
export function nextToPlay() {
  return LEVELS.find((l) => isUnlocked(l.id) && !isCompleted(l.id)) ?? LEVELS[LEVELS.length - 1];
}
