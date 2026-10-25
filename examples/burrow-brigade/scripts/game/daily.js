// @ts-check
// The daily dig: one mine for everybody on a date. The seed comes from the date alone, so every player of the date meets the same
// floors; the player's own record of the date (tries and deepest depth) is kept in `storage` under "burrow.daily".
//
// THE RULES
//   - One shared seed per date. The date is read with `game.today()` (the engine's calendar; tests fix it with `game.setDate`),
//     never from a wall clock, and never inside the simulation: only the title asks for it, once, when the run starts.
//   - Any number of tries. Each try is a fresh run from the Topsoil, floor 1: no cash, the starting pick and lamp, nothing
//     carried over from a save slot. A try ends when the player leaves for the title or the Mole King falls.
//   - The same floor is the same mine however often it is played that day (a run in the "daily" mode plays `run.seed` on
//     every shift, see mineSeed in run_state.js), so a lost floor can be learned and tried again.
//   - A daily try is never written to a slot (`run.slot` is null) and there is no Continue for it.
//   - `run.mode` is "daily" and `run.dailyKey` is the date; for every other run they are "normal" and null. P5 posts the daily
//     board from these two fields.
//   - The date is the one `game.today()` gives, which is the player's LOCAL calendar date (the engine gives no clock time, so the
//     UTC date cannot be worked out: ENGINE_FEEDBACK). Players in other time zones therefore roll over at their own midnight.
import { game, storage } from "factoria";
import { run, startRun, depthOf } from "./run_state.js";

const KEY = "burrow.daily";

/** The date a daily dig started now belongs to: "YYYY-MM-DD". */
export function todayKey() {
  return game.today().iso;
}

/** True for a "YYYY-MM-DD" text. */
export function isKey(key) {
  return typeof key === "string" && /^\d{4}-\d{2}-\d{2}$/.test(key);
}

/**
 * The seed of a date: a 31-bit hash of its text, the same on every machine. Never 0.
 * @param {string} key  "YYYY-MM-DD"
 */
export function seedFor(key) {
  if (!isKey(key)) throw new Error(`the daily dig needs a date like 2026-01-31, not '${key}'.`);
  let h = 0x811c9dc5;
  for (const ch of `burrow-brigade/daily/${key}`) {
    h ^= ch.charCodeAt(0);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return (h & 0x7fffffff) || 1;
}

/**
 * What the player did on a date.
 * @param {string} [key]  Default: today.
 * @returns {{key: string, tries: number, bestDepth: number, won: boolean}}
 */
export function status(key = todayKey()) {
  const saved = storage.get(KEY, null);
  if (saved && saved.key === key) {
    return { key, tries: Number(saved.tries) || 0, bestDepth: Number(saved.bestDepth) || 0, won: saved.won === true };
  }
  return { key, tries: 0, bestDepth: 0, won: false };
}

function write(s) {
  storage.set(KEY, { key: s.key, tries: s.tries, bestDepth: s.bestDepth, won: s.won });
}

/**
 * Starts a try of today's daily dig: a fresh run of the date's seed (mode "daily"). Counts the try.
 * @param {string} [key]  A date other than today (tests, a replay).
 */
export function start(key = todayKey()) {
  const seed = seedFor(key);
  startRun({ seed, mode: "daily", dailyKey: key });
  const s = status(key);
  s.tries += 1;
  write(s);
  return { key, seed };
}

/**
 * Records a finished shift of a daily try: the deepest floor reached today, and a win. The shift script calls it.
 * @param {{stratum: number, floor: number, outcome: string}} summary  `run.lastShift`.
 * @param {boolean} [victory]  True when the Mole King's lift ended the run.
 */
export function noteShift(summary, victory = false) {
  const key = run.dailyKey ?? todayKey(); // the date the try began on, even if midnight passed meanwhile
  const s = status(key);
  s.bestDepth = Math.max(s.bestDepth, depthOf(summary.stratum, summary.floor));
  s.won = s.won || victory;
  write(s);
  return s;
}
