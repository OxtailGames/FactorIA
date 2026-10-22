// @ts-check
// Saved progress: the best result of every level, kept with `storage` (storage.json in the save folder, in memory in
// tests and headless runs). The file shape is { version: 1, results: { <level id>: { time, springLeft, stars } } }.
//
//   load()            the whole saved object (a fresh one when there is none)
//   resultFor(id)     the best result of a level, or null when it was never won
//   record(id, r)     keeps r = { time, springLeft, stars } when it is better than the saved one; returns true if it was saved
//   isUnlocked(id)    the first level always is; the others open when the one before them was won
//   reset()           forgets everything (a "delete save" button)
import { storage } from "factoria";
import { LEVELS } from "./levels.js";

const KEY = "progress";

export function load() {
  const saved = storage.get(KEY, null);
  if (!saved || typeof saved !== "object" || typeof saved.results !== "object") return { version: 1, results: {} };
  return { version: 1, results: { ...saved.results } };
}

export function resultFor(id) {
  return load().results[id] ?? null;
}

/** "Better" = more stars, then less time. */
function better(a, b) {
  if (!b) return true;
  if (a.stars !== b.stars) return a.stars > b.stars;
  return a.time < b.time;
}

export function record(id, result) {
  const progress = load();
  const old = progress.results[id] ?? null;
  const next = { time: round(result.time), springLeft: round(result.springLeft), stars: result.stars | 0 };
  if (!better(next, old)) return false;
  progress.results[id] = next;
  storage.set(KEY, progress);
  return true;
}

export function isUnlocked(id) {
  const i = LEVELS.findIndex((l) => l.id === id);
  if (i < 0) return false;
  if (i === 0) return true;
  return resultFor(LEVELS[i - 1].id) !== null;
}

export function reset() {
  storage.remove(KEY);
}

function round(x) {
  return Math.round(x * 100) / 100;
}
