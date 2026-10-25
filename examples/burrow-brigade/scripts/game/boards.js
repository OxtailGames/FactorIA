// @ts-check
// The leaderboards: the best run cash of all time and the best of the day's dig. Both are catalog boards (factoria.json
// "platform.leaderboards"), so the store layer keeps them: the fake store in tests, Steam in the shipped game.
//
//   BOARDS.allTime  "best_run_cash"   descending, never resets.
//   BOARDS.daily    "daily_run_cash"  descending, period "daily": the store starts it over each calendar day (`game.today()`).
//
// The score of a run is the cash it has earned: the sum of what its lifts banked (`shiftEnded.banked`), not the cash in hand, so
// spending at the camp (P4) cannot lower it. It is posted every time a shift ends on the lift, to the all-time board always and to
// the daily board when `run.mode === "daily"` (P4 sets `run.mode` and `run.dailyKey`, the local "YYYY-MM-DD" of the daily seed). A run
// with no `mode` is a normal one. The store keeps each player's best, so posting after every shift is safe.
//
// ASSISTED RUNS. A run played at a game speed under 100 % (Options > Access, `shiftStarted.speed`) is not posted: a board compares
// players, and a slower game is an assist, not a rival's score. The run still earns cash, trophies and its local results, and the
// daily dig can still be played at a slower speed (it is the same seed and mine); only the board posts are skipped
// (`status().assisted`). The flag is kept from the first shift of a run, so a run continued from a save (Continue) starts a fresh
// count: it is assisted only when a shift played after the continue was slow.
//
// The daily board is the store's board of TODAY (the engine cannot post to another day). P4's `dailyKey` is the local date the try
// began on, so a try that crosses midnight is keyed by yesterday while the store posts to today: a daily run is posted while
// `run.dailyKey` is at most one day away from today's date, and nothing is posted to the daily board for an older one
// (`lastPost.daily.skipped === "otherDay"`, the boards screen says why).
//
//   start() / stop()          subscribe / unsubscribe to the events (events.keep). start is idempotent.
//   idle()                    resolves when every post made so far has been answered.
//   top(board, count = 10)    [{ rank, name, score, isPlayer }] of the board's current period; [] when the store has no boards.
//   status()                  { runScore, mode, dailyKey, today, dailyOpen, assisted, lastPost }
import { platform, game } from "factoria";
import * as events from "./events.js";
import { run } from "./run_state.js";

export const BOARDS = Object.freeze({ allTime: "best_run_cash", daily: "daily_run_cash" });

/** @type {Array<() => void>} */
let unsubscribers = [];
let chain = Promise.resolve();
const state = {
  runScore: 0,
  lastNumber: 0,
  /** @type {{allTime?: {score: number, best: number}, daily?: {score: number, best: number} | {skipped: string}}} */
  lastPost: {},
  /** True when a shift of this run was played slower than 100 %: nothing is posted. */
  assisted: false,
};

export async function idle() {
  for (;;) {
    const c = chain;
    await c;
    if (c === chain) return;
  }
}

/** "normal" or "daily": what the run says it is (P4 sets run.mode; a missing one is a normal run). */
export function modeOf() {
  return /** @type {any} */ (run).mode === "daily" ? "daily" : "normal";
}

/** The run's daily key, or null. */
export function dailyKeyOf() {
  const k = /** @type {any} */ (run).dailyKey;
  return typeof k === "string" && /^\d{4}-\d{2}-\d{2}$/.test(k) ? k : null;
}

/** Days since 1970-01-01 of a "YYYY-MM-DD" (no clock, no time zone). @param {string} iso */
function dayNumber(iso) {
  const [y, m, d] = iso.split("-").map(Number);
  return Math.round(Date.UTC(y, m - 1, d) / 86400000);
}

/** Whether the store's daily board (today's) can take this run's score: a daily run whose key is today's date or the day next to it. */
export function dailyOpen() {
  const key = dailyKeyOf();
  return modeOf() === "daily" && key !== null && Math.abs(dayNumber(key) - dayNumber(game.today().iso)) <= 1;
}

/** @param {any} d */
function onShiftStarted(d) {
  const n = run.shiftNumber;
  if (n <= 1) {
    state.runScore = 0;
    state.assisted = false;
  } else if (n !== state.lastNumber + 1 && n !== state.lastNumber) {
    state.runScore = run.cash; // a continued run: start from the cash in hand
    state.assisted = false; // and a fresh assist count
  }
  if (d && typeof d.speed === "number" && d.speed < 1) state.assisted = true;
  state.lastNumber = n;
}

/** @param {any} d */
function onShiftEnded(d) {
  if (d.outcome !== "lift") return;
  state.runScore += d.banked ?? 0;
  const score = Math.max(0, Math.floor(state.runScore));
  if (score <= 0 || state.assisted || !platform.has("leaderboards")) return;
  const daily = modeOf() === "daily";
  const open = daily && dailyOpen();
  const key = dailyKeyOf();
  chain = chain
    .then(async () => {
      const a = await platform.leaderboards.submit(BOARDS.allTime, score);
      state.lastPost.allTime = { score, best: a.best };
      events.emit("boardPosted", { board: BOARDS.allTime, score, period: "allTime" });
      if (!daily) return;
      if (open) {
        const b = await platform.leaderboards.submit(BOARDS.daily, score);
        state.lastPost.daily = { score, best: b.best };
        events.emit("boardPosted", { board: BOARDS.daily, score, period: key });
      } else {
        state.lastPost.daily = { skipped: "otherDay" };
      }
    })
    .catch((e) => console.warn(`boards: the score was not posted: ${e && e.message ? e.message : e}`));
}

export function start() {
  if (unsubscribers.length) return;
  unsubscribers = [events.keep("shiftStarted", onShiftStarted), events.keep("shiftEnded", onShiftEnded)];
}

export function stop() {
  for (const off of unsubscribers) off();
  unsubscribers = [];
  state.runScore = 0;
  state.lastNumber = 0;
  state.lastPost = {};
  state.assisted = false;
}

/**
 * The top of a board for a screen.
 * @param {string} board  BOARDS.allTime or BOARDS.daily
 * @param {number} [count]
 * @returns {Promise<Array<{rank: number, name: string, score: number, isPlayer: boolean}>>}
 */
export async function top(board, count = 10) {
  if (!platform.has("leaderboards")) return [];
  const rows = await platform.leaderboards.entries(board, { range: "top", count });
  return rows.map((r) => ({ rank: r.rank, name: r.name, score: r.score, isPlayer: !!r.isPlayer }));
}

export function status() {
  return {
    runScore: state.runScore,
    mode: modeOf(),
    dailyKey: dailyKeyOf(),
    today: game.today().iso,
    dailyOpen: dailyOpen(),
    assisted: state.assisted,
    lastPost: state.lastPost,
  };
}
