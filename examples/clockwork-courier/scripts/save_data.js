// @ts-check
// The shape of the save and the rules that keep it healthy. Pure functions (no storage, no platform): progress.js
// reads and writes the local copy, cloud_sync.js moves it to and from the store, tests feed them old layouts.
//
// The save is ONE object under the storage key "progress" (one slot is enough for this game). It is written with a
// single storage.set(), and the engine saves storage.json through a temporary file and a rename, so a crash mid-write
// leaves the previous complete save (never half of this one). Layouts:
//
//   version 1 (P1/P2)  { version: 1, results: { <level id>: { time, springLeft, stars, goals } } }
//   version 2 (P3)     { version: 2, counter, name, results, daily, dailyTimes }
//
//   counter     goes up by one on every save: it orders copies without a wall clock (determinism) and decides which
//               copy is "newer" when two devices disagree (cloud_sync.js)
//   name        the courier's name ("" until the first-run screen sets it)
//   daily       today's route as picked once for the day { date, level, order }: kept in the save so the route does not
//               change mid-day when a level unlocks (scripts/daily.js)
//   dailyTimes  { "YYYY-MM-DD": { level, time } }, the best finished daily route of each of the last DAILY_KEEP days
//
// parse() reads ANY version and always returns the newest; migrate1() is the one step 1 -> 2. Add migrate2() when the
// layout changes again and keep a fixture of every old layout in tests/fixtures/.
import { LEVELS, TEST_LEVELS } from "./levels.js";

/** Levels whose results are kept: the player's list and the test scenes (their results never count as stars). */
const KEPT = [...LEVELS, ...TEST_LEVELS];

export const VERSION = 2;
/** Key of the save in `storage`. */
export const KEY = "progress";
/** How many days of finished daily routes the save keeps. */
export const DAILY_KEEP = 30;
/** The longest courier name, in characters. */
export const NAME_MAX = 12;

/** @typedef {{ time: number, springLeft: number, stars: number, goals: any }} Result */
/** @typedef {{ date: string, level: string, order: number[] }} DailyRoute */
/** @typedef {{ version: number, counter: number, name: string, results: Record<string, Result>, daily: DailyRoute | null, dailyTimes: Record<string, { level: string, time: number }> }} SaveData */

/** @returns {SaveData} a save with nothing in it */
export function empty() {
  return { version: VERSION, counter: 0, name: "", results: {}, daily: null, dailyTimes: {} };
}

/** "Better" for a level result = more stars, then less time. */
export function better(a, b) {
  if (!b) return true;
  if (a.stars !== b.stars) return a.stars > b.stars;
  return a.time < b.time;
}

/** Version 1 -> 2: the results stay, the courier has no name yet, the counter starts at 0. */
export function migrate1(old) {
  return { ...empty(), results: sanitizeResults(old.results) };
}

/**
 * Reads a save of any version from whatever the storage (or a cloud copy) holds. Never throws.
 * @returns {{ ok: true, data: SaveData, migrated: boolean } | { ok: false, reason: string }}
 */
export function parse(raw) {
  if (raw === null || raw === undefined) return { ok: false, reason: "there is no save" };
  if (typeof raw !== "object" || Array.isArray(raw)) return { ok: false, reason: "the save is not an object" };
  const version = raw.version === undefined ? 1 : raw.version;
  if (typeof version !== "number" || !Number.isInteger(version) || version < 1) return { ok: false, reason: `the save has a bad version (${String(version)})` };
  if (version > VERSION) return { ok: false, reason: `the save is version ${version}, newer than this game's (${VERSION}): update the game` };
  if (typeof raw.results !== "object" || raw.results === null || Array.isArray(raw.results)) return { ok: false, reason: "the save has no results table" };
  const data = version === 1 ? migrate1(raw) : fromV2(raw);
  return { ok: true, data, migrated: version !== VERSION };
}

function fromV2(raw) {
  const data = empty();
  data.counter = Number.isInteger(raw.counter) && raw.counter > 0 ? raw.counter : 0;
  data.name = cleanName(raw.name);
  data.results = sanitizeResults(raw.results);
  data.daily = sanitizeDaily(raw.daily);
  data.dailyTimes = sanitizeDailyTimes(raw.dailyTimes);
  return data;
}

/** Only known levels, with numbers where numbers belong: a result a player (or a bug) mangled is dropped. */
function sanitizeResults(results) {
  const out = {};
  if (!results || typeof results !== "object") return out;
  for (const l of KEPT) {
    const r = results[l.id];
    if (!r || typeof r !== "object") continue;
    if (!Number.isFinite(r.time) || r.time < 0 || !Number.isFinite(r.stars) || r.stars < 1) continue;
    out[l.id] = {
      time: r.time,
      springLeft: Number.isFinite(r.springLeft) ? r.springLeft : 0,
      stars: Math.min(3, Math.floor(r.stars)),
      goals: r.goals && typeof r.goals === "object" ? { fast: !!r.goals.fast, springy: !!r.goals.springy, thorough: r.goals.thorough ?? null } : null,
    };
  }
  return out;
}

function sanitizeDaily(d) {
  if (!d || typeof d !== "object" || !isDate(d.date) || !LEVELS.some((l) => l.id === d.level)) return null;
  if (!Array.isArray(d.order) || !d.order.every((n) => Number.isInteger(n) && n >= 0)) return null;
  return { date: d.date, level: d.level, order: d.order.slice() };
}

function sanitizeDailyTimes(t) {
  const out = {};
  if (!t || typeof t !== "object") return out;
  const dates = Object.keys(t).filter((k) => isDate(k) && t[k] && LEVELS.some((l) => l.id === t[k].level) && Number.isFinite(t[k].time));
  for (const k of dates.sort().slice(-DAILY_KEEP)) out[k] = { level: t[k].level, time: t[k].time };
  return out;
}

/** True for "YYYY-MM-DD" with a real month and day. */
export function isDate(s) {
  if (typeof s !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const [y, m, d] = s.split("-").map(Number);
  return m >= 1 && m <= 12 && d >= 1 && d <= new Date(Date.UTC(y, m, 0)).getUTCDate();
}

/** A courier name as it is saved: no control characters, spaces collapsed and trimmed, at most NAME_MAX characters. */
export function cleanName(s) {
  if (typeof s !== "string") return "";
  const t = s.replace(/[\u0000-\u001f\u007f]/g, "").replace(/\s+/g, " ").trim();
  return Array.from(t).slice(0, NAME_MAX).join("").trim();
}

/** Sum of the best stars of every level of the list. */
export function totalStars(data) {
  return LEVELS.reduce((n, l) => n + (data.results[l.id]?.stars ?? 0), 0);
}

/** The save as stable text without its counter: two saves with the same text hold the same progress. */
export function content(data) {
  const results = {};
  for (const id of Object.keys(data.results).sort()) results[id] = data.results[id];
  const times = {};
  for (const k of Object.keys(data.dailyTimes).sort()) times[k] = data.dailyTimes[k];
  return JSON.stringify({ name: data.name, results, daily: data.daily, times });
}

/**
 * Joins two copies of the same save (this device and the cloud, or two devices) without losing progress: every level
 * keeps the better result, every day the better daily time, and the name and today's route come from the copy with the
 * higher counter (a tie goes to `a`, the local one). So "newer progress wins" and "more progress wins" at once: a player
 * who played level 4 on the phone and level 5 on the tablet gets both levels, never one of them.
 * @param {SaveData} a local copy  @param {SaveData} b the other one
 * @returns {{ data: SaveData, from: "same" | "a" | "b" | "both" }}
 *   same: identical progress; a / b: that copy already has everything; both: neither did, `data` is new (counter + 1)
 */
export function merge(a, b) {
  const newer = a.counter >= b.counter ? a : b;
  const m = empty();
  m.name = newer.name || (newer === a ? b.name : a.name);
  for (const l of KEPT) {
    const x = a.results[l.id];
    const y = b.results[l.id];
    if (x && y) m.results[l.id] = better(x, y) ? x : y;
    else if (x || y) m.results[l.id] = x ?? y;
  }
  m.daily = pickDaily(a, b, newer);
  const dates = new Set([...Object.keys(a.dailyTimes), ...Object.keys(b.dailyTimes)]);
  for (const k of [...dates].sort().slice(-DAILY_KEEP)) {
    const x = a.dailyTimes[k];
    const y = b.dailyTimes[k];
    m.dailyTimes[k] = x && y ? (y.time < x.time ? y : x) : (x ?? y);
  }
  const text = content(m);
  const sameA = content(a) === text;
  const sameB = content(b) === text;
  if (sameA && sameB) return { data: a.counter >= b.counter ? a : b, from: "same" };
  if (sameA) return { data: a, from: "a" };
  if (sameB) return { data: b, from: "b" };
  m.counter = Math.max(a.counter, b.counter) + 1;
  return { data: m, from: "both" };
}

function pickDaily(a, b, newer) {
  if (!a.daily || !b.daily) return a.daily ?? b.daily;
  if (a.daily.date !== b.daily.date) return a.daily.date > b.daily.date ? a.daily : b.daily;
  return newer.daily;
}
