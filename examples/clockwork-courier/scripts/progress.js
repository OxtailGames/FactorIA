// @ts-check
// Saved progress, the courier's profile and the daily route times: the local save, kept with `storage` (storage.json in
// the save folder, in memory in tests and headless runs). The layout, its versions and the migration from P1's format
// are in scripts/save_data.js; the copy in the store's cloud is scripts/cloud_sync.js.
//
//   load()              the whole save (version 2; a save of an older version is migrated in memory, an unusable one is empty)
//   resultFor(id)       the best result of a level { time, springLeft, stars, goals }, or null when it was never won
//   record(id, r)       keeps r = { time, springLeft, stars, goals? } when it is better than the saved one; returns true if it was saved
//   totalStars()        the sum of the best stars of every level of the player's list
//   isUnlocked(id)      a level is open when the level before it was won AND its district is open (the first level always is)
//   isDistrictUnlocked(district)  the stars won in the districts before it reach DISTRICTS[n].stars
//   districtStarsNeeded(district) / starsBefore(district)  what the lock screen shows
//   nextUnfinished()    the first open level without a result (what Continue starts), or null when every open level was won
//   name() / hasName() / setName(text)   the courier's name (profile), cleaned by save_data.cleanName
//   dailyRoute() / setDailyRoute(route) / dailyTime(date) / recordDaily(date, level, time)   scripts/daily.js
//   reset()             forgets everything (a "delete save" button)
//
// Every change is ONE storage.set() of the whole save with its counter + 1, then a best-effort upload to the cloud
// (cloud_sync.push). A save the game cannot read (damaged, or from a newer game) is copied to the key "progressBackup"
// before the first write replaces it, so an update that was rolled back never destroys the newer game's file.
import { storage } from "factoria";
import { LEVELS, DISTRICTS } from "./levels.js";
import * as saveData from "./save_data.js";
import * as cloud from "./cloud_sync.js";

const KEY = saveData.KEY;

/** @returns {import("./save_data.js").SaveData} */
export function load() {
  const parsed = saveData.parse(storage.get(KEY, null));
  return parsed.ok ? parsed.data : saveData.empty();
}

/** Writes `data` as the new save: counter + 1, one storage.set, then the cloud copy follows. */
function write(data) {
  const raw = storage.get(KEY, null);
  if (raw !== null && !saveData.parse(raw).ok && storage.get("progressBackup", null) === null) storage.set("progressBackup", raw);
  const next = { ...data, version: saveData.VERSION, counter: data.counter + 1 };
  storage.set(KEY, next);
  cloud.push(next);
  return next;
}

export function resultFor(id) {
  return load().results[id] ?? null;
}

export function record(id, result) {
  const data = load();
  const old = data.results[id] ?? null;
  const next = { time: round(result.time), springLeft: round(result.springLeft), stars: result.stars | 0, goals: result.goals ?? null };
  if (!saveData.better(next, old)) return false;
  data.results[id] = next;
  write(data);
  return true;
}

export function totalStars() {
  return saveData.totalStars(load());
}

/** Stars won in the districts BEFORE `district` (what unlocks it). */
export function starsBefore(district) {
  const data = load();
  const i = DISTRICTS.findIndex((d) => d.id === district);
  const earlier = new Set(DISTRICTS.slice(0, Math.max(0, i)).map((d) => d.id));
  return LEVELS.filter((l) => earlier.has(l.district)).reduce((n, l) => n + (data.results[l.id]?.stars ?? 0), 0);
}

export function districtStarsNeeded(district) {
  return DISTRICTS.find((d) => d.id === district)?.stars ?? 0;
}

export function isDistrictUnlocked(district) {
  return starsBefore(district) >= districtStarsNeeded(district);
}

export function isUnlocked(id) {
  const i = LEVELS.findIndex((l) => l.id === id);
  if (i < 0) return false;
  if (!isDistrictUnlocked(LEVELS[i].district)) return false;
  if (i === 0) return true;
  return resultFor(LEVELS[i - 1].id) !== null;
}

export function nextUnfinished() {
  return LEVELS.find((l) => isUnlocked(l.id) && resultFor(l.id) === null) ?? null;
}

export function name() {
  return load().name;
}

export function hasName() {
  return load().name !== "";
}

/** Saves the courier's name; returns the cleaned name ("" when there was nothing usable, then nothing is saved). */
export function setName(text) {
  const clean = saveData.cleanName(text);
  if (clean === "") return "";
  const data = load();
  if (data.name !== clean) {
    data.name = clean;
    write(data);
  }
  return clean;
}

/** Today's route as saved by the daily module, or null. */
export function dailyRoute() {
  return load().daily;
}

export function setDailyRoute(route) {
  const data = load();
  data.daily = route;
  write(data);
}

/** The best finished daily time of a date { level, time }, or null. */
export function dailyTime(date) {
  return load().dailyTimes[date] ?? null;
}

/** Keeps the time when it beats the day's saved one; returns true when it did. */
export function recordDaily(date, level, time) {
  const data = load();
  const old = data.dailyTimes[date];
  if (old && old.time <= time) return false;
  data.dailyTimes[date] = { level, time: round(time) };
  write(data);
  return true;
}

export function reset() {
  storage.remove(KEY);
}

function round(x) {
  return Math.round(x * 100) / 100;
}
