// @ts-check
// Achievements and stats, driven by the game events bus (events.js) and written to the store layer (`platform`). The catalog
// (ids, names, descriptions) is factoria.json "platform"; the rules that unlock them are ACHIEVEMENTS below. Everything is best
// effort: a store that is missing, signed out or failing never reaches the player (a warning in the log at most).
//
//   start()          subscribes to the events for good (events.keep: a new run does not drop the listeners). Idempotent.
//   stop()           unsubscribes (tests).
//   idle()           a Promise that resolves when every store call made so far has been answered (tests await it).
//   list()           the achievements for a screen: [{ id, name, description, unlocked, icon, progress? }].
//   statValues()     the stats for a screen: [{ id, label, value }].
//
// Stats (counted for ever, kept by the store): oreDug, molesRescued, floorsCleared, enemiesDefeated.
// Achievements: see ACHIEVEMENTS. Those with a `stat` unlock when that stat reaches `atLeast`; the others by their own rule.
import { platform, i18n, game } from "factoria";
import * as events from "./events.js";
import { stratumInfo } from "./generator.js";

/** The stats the game keeps: id -> the event that adds one (documented in the README, Contracts). */
export const STATS = Object.freeze({
  oreDug: "orePicked",
  molesRescued: "moleRescued",
  floorsCleared: "shiftEnded with outcome lift",
  enemiesDefeated: "enemyDefeated",
});

/**
 * The achievements, in the order of the screen. `icon` is a 64 px picture (assets/src/make_online_art.py); `stat` + `atLeast`
 * unlock it from a stat, `rule` says what else unlocks it (the code is in `onEvent` below).
 */
export const ACHIEVEMENTS = Object.freeze([
  { id: "first_ore", icon: "assets/achievements/first_ore.png", stat: "oreDug", atLeast: 1, rule: "the first ore ever picked up" },
  { id: "mole_rescuer", icon: "assets/achievements/mole_rescuer.png", stat: "molesRescued", atLeast: 10, rule: "10 moles rescued, over all runs" },
  { id: "mole_king", icon: "assets/achievements/mole_king.png", rule: "the Mole King beaten (bossDefeated)" },
  { id: "bright_stratum", icon: "assets/achievements/bright_stratum.png", rule: "the last floor of a stratum cleared on the lift, and no lamp went out in that stratum" },
  { id: "full_house", icon: "assets/achievements/full_house.png", rule: "a shift with 4 players that ends on the lift" },
  { id: "bug_squasher", icon: "assets/achievements/bug_squasher.png", stat: "enemiesDefeated", atLeast: 25, rule: "25 enemies defeated, over all runs" },
]);

/** @type {Array<() => void>} */
let unsubscribers = [];
let chain = Promise.resolve();
/** Achievements already asked for in this session (a second unlock call would only repeat the store's answer). */
const asked = new Set();
/** The last values the store gave for each stat. */
const known = /** @type {Record<string, number>} */ ({});
/** What the current run has shown (not saved): the players of the shift, the lamp that went out, the last outcome. */
const track = { players: 0, stratum: -1, clean: true, lastOutcome: /** @type {string|null} */ (null), lastFloor: 0 };

function enqueue(fn) {
  chain = chain.then(fn).catch((e) => console.warn(`trophies: the store call failed: ${e && e.message ? e.message : e}`));
  return chain;
}

/** Resolves when every store call queued so far has finished. */
export async function idle() {
  for (;;) {
    const c = chain;
    await c;
    if (c === chain) return;
  }
}

function unlock(id) {
  if (asked.has(id) || !platform.has("achievements")) return Promise.resolve();
  return enqueue(() => unlockNow(id));
}

/** The name of an achievement in the current language, from the catalog (factoria.json "platform"). */
function nameOf(id) {
  const def = (game.project.platform?.achievements ?? []).find((a) => a.id === id);
  return def ? (def.nameKey ? i18n.t(def.nameKey) : def.name ?? id) : id;
}

function addStat(id, n = 1) {
  if (!platform.has("stats")) return Promise.resolve();
  return enqueue(async () => {
    const value = await platform.stats.add(id, n);
    known[id] = value;
    for (const a of ACHIEVEMENTS) if (a.stat === id && value >= /** @type {number} */ (a.atLeast)) await unlockNow(a.id);
  });
}

/** `unlock` from inside the queue (it must not queue again, or it would wait for itself). */
async function unlockNow(id) {
  if (asked.has(id) || !platform.has("achievements")) return;
  asked.add(id);
  const r = await platform.achievements.unlock(id);
  if (r.newly) events.emit("achievementUnlocked", { id, name: nameOf(id) });
}

/** @param {any} d */
function onShiftStarted(d) {
  track.players = d.players ?? 0;
  const retryOfFirst = track.lastOutcome !== null && track.lastOutcome !== "lift" && track.stratum === d.stratum && track.lastFloor === 1 && d.floor === 1;
  // A new stratum (or a new run) starts clean; the same floor again after a bad shift does not wash the record.
  if (d.stratum !== track.stratum || (d.floor === 1 && !retryOfFirst)) track.clean = true;
  track.stratum = d.stratum;
  track.lastFloor = d.floor;
}

/** @param {any} d */
function onShiftEnded(d) {
  track.lastOutcome = d.outcome;
  if (d.outcome !== "lift") return;
  addStat("floorsCleared", 1);
  if (track.players >= 4) unlock("full_house");
  if (track.clean && d.floor >= stratumInfo(d.stratum).floors) unlock("bright_stratum");
}

/** Subscribes to the events. Idempotent. */
export function start() {
  if (unsubscribers.length) return;
  unsubscribers = [
    events.keep("orePicked", () => addStat("oreDug", 1)),
    events.keep("moleRescued", () => addStat("molesRescued", 1)),
    events.keep("enemyDefeated", () => addStat("enemiesDefeated", 1)),
    events.keep("bossDefeated", () => unlock("mole_king")),
    events.keep("lampOut", () => { track.clean = false; }),
    events.keep("shiftStarted", onShiftStarted),
    events.keep("shiftEnded", onShiftEnded),
  ];
}

/** Unsubscribes and forgets the session (tests). */
export function stop() {
  for (const off of unsubscribers) off();
  unsubscribers = [];
  asked.clear();
  for (const k of Object.keys(known)) delete known[k];
  Object.assign(track, { players: 0, stratum: -1, clean: true, lastOutcome: null, lastFloor: 0 });
}

/**
 * The achievements as a screen shows them: name and description in the current language from the store layer, the unlock state,
 * the icon, and for a stat-driven one the progress `{ value, goal }`.
 * @returns {Promise<Array<{id: string, name: string, description: string, unlocked: boolean, icon: string, progress: {value: number, goal: number}|null}>>}
 */
export async function list() {
  if (!platform.has("achievements")) return [];
  const rows = await platform.achievements.list();
  const stats = platform.has("stats") ? await statValues() : [];
  return ACHIEVEMENTS.map((a) => {
    const row = rows.find((r) => r.id === a.id);
    const s = a.stat ? stats.find((x) => x.id === a.stat) : null;
    return {
      id: a.id,
      name: row?.name ?? a.id,
      description: row?.description ?? "",
      unlocked: !!row?.unlocked,
      icon: a.icon,
      progress: a.stat && s ? { value: Math.min(s.value, a.atLeast), goal: a.atLeast } : null,
    };
  });
}

/** The stats: id, the name in the current language and the value the store holds. */
export async function statValues() {
  if (!platform.has("stats")) return [];
  const out = [];
  for (const id of Object.keys(STATS)) out.push({ id, label: i18n.t(`stats.${id}`), value: await platform.stats.get(id) });
  return out;
}
