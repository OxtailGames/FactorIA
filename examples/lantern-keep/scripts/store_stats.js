// @ts-check
// Store services fed by the game events (README "Contract 3"): stats, achievements and best times for the leaderboards.
// One entity of every level (id "store_stats") carries this script. Everything here is best effort: a store that is not
// there, a player who is not signed in or a request that fails never stops the game, the call is just lost (the next
// event brings the totals up to date again). Requests go one after the other so that a get-then-set never overlaps.
import { Behaviour, platform, session, storage } from "factoria";
import * as progress from "./progress.js";
import { LEVELS, EMBERS_PER_LEVEL } from "./levels.js";

/** Level 1-1 must be finished in less than this many seconds for "Quick Feet". */
export const QUICK_SECONDS = 28;
/** Jumps needed for "Leap of Faith". */
export const JUMPS_GOAL = 500;
/** Deaths needed for "Hard Lessons". */
export const DEATHS_GOAL = 25;
/** Jumps are sent to the store in groups of this size (and whenever a death or a finish comes first). */
const JUMP_BATCH = 10;

/** The id of the leaderboard of a level (factoria.json "platform.leaderboards"); `time_total` is the sum of all of them. */
export const boardOf = (level) => `time_${level}`;
export const TOTAL_BOARD = "time_total";

/** Best times (milliseconds) the game has already sent, per leaderboard id: a submit happens only when a time beats these. */
export function sentTimes() {
  return storage.get("leaderboardsSent", {});
}

export default class StoreStats extends Behaviour {
  onStart() {
    this.chain = Promise.resolve();
    this.on("player_jumped", () => {
      session.storeJumps = (session.storeJumps ?? 0) + 1;
      if (session.storeJumps >= JUMP_BATCH) this.flushJumps();
    });
    this.on("player_died", () => {
      this.flushJumps();
      this.count("deaths", DEATHS_GOAL, "hard_lessons");
    });
    this.on("level_completed", (result) => {
      this.flushJumps();
      this.completed(result);
    });
  }

  onDestroy() {
    this.flushJumps(); // the player left the level (menu, retry): the jumps counted so far still count
  }

  /** Resolves when every request started so far has been answered (tests wait on it). */
  idle() {
    return this.chain;
  }

  /** Queues `fn` after the earlier requests; a failure is swallowed (see the top of the file). */
  run(fn) {
    this.chain = this.chain.then(() => fn()).catch(() => {}); // best effort
    return this.chain;
  }

  flushJumps() {
    const n = session.storeJumps ?? 0;
    session.storeJumps = 0;
    if (n > 0) this.count("jumps", JUMPS_GOAL, "jumper", n);
  }

  /** Adds `n` to an int stat and moves the achievement that counts it. */
  count(stat, goal, achievement, n = 1) {
    if (!platform.has("stats")) return;
    this.run(async () => {
      const total = await platform.stats.add(stat, n);
      if (platform.has("achievements")) await platform.achievements.progress(achievement, Math.min(1, total / goal));
    });
  }

  unlock(id) {
    if (platform.has("achievements")) this.run(() => platform.achievements.unlock(id));
  }

  /** The exit was touched: `result` is the `level_completed` payload ({ level, time, embers, deaths, assisted? }). */
  completed(result) {
    const assisted = result.assisted === true; // assist mode (a later package) sends it; a missing field means false
    if (platform.has("stats")) {
      this.run(() => platform.stats.add("levels_finished", 1));
      this.run(() => platform.stats.set("embers_found", progress.totalEmbers()));
    }
    if (result.level === "1-1") this.unlock("first_light");
    for (const [achievement, world] of [["courtyard_clear", 1], ["cellars_clear", 2]]) {
      if (LEVELS.filter((l) => l.world === world).every((l) => progress.isCompleted(l.id))) this.unlock(achievement);
    }
    const total = progress.totalEmbers();
    if (platform.has("achievements")) {
      this.run(() => platform.achievements.progress("all_embers", Math.min(1, total / (LEVELS.length * EMBERS_PER_LEVEL))));
    }
    if (assisted) return; // assisted runs count for the story, not for records
    if (result.deaths === 0) this.unlock("untouched");
    if (result.level === "1-1" && result.time < QUICK_SECONDS) this.unlock("quick_feet");
    this.submitTime(result.level, Math.round(result.time * 1000));
  }

  /** Sends a time (milliseconds) to the level's board when it beats the last one sent, then the total when every level has one. */
  submitTime(level, ms) {
    if (!platform.has("leaderboards")) return;
    const board = boardOf(level);
    const before = sentTimes()[board];
    if (before !== undefined && ms >= before) return; // not a new best
    this.run(async () => {
      await platform.leaderboards.submit(board, ms);
      const sent = { ...sentTimes(), [board]: before === undefined ? ms : Math.min(before, ms) };
      storage.set("leaderboardsSent", sent);
      if (!LEVELS.every((l) => sent[boardOf(l.id)] !== undefined)) return;
      const sum = LEVELS.reduce((s, l) => s + sent[boardOf(l.id)], 0);
      if (sent[TOTAL_BOARD] === undefined || sum < sent[TOTAL_BOARD]) {
        await platform.leaderboards.submit(TOTAL_BOARD, sum);
        storage.set("leaderboardsSent", { ...sentTimes(), [TOTAL_BOARD]: sum });
      }
    });
  }
}
