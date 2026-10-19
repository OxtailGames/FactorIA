// @ts-check
// Save slots. A slot is a string in `storage` ("slot1".."slot3", JSON text) and, when the player is signed in to a store,
// a copy in the cloud under the same key. The format is versioned (README: "Saves and the level select"):
//
//   version 2: { version: 2, counter: 7, levels: { "1-1": { completed: true, bestTime: 41.2, embers: [true, false, true] } } }
//   version 1 (a file written before `version` existed): { cleared: ["1-1"], best: { "1-1": 41.2 } }
//
// `counter` goes up by one on every save. It decides which copy (local or cloud) has more progress; the wall clock is
// never read (determinism). This module works on `session.progress` (the data of scripts/progress.js) and does not
// import progress.js, which calls save() after every finished level.
import { storage, session, platform } from "factoria";
import { LEVELS, EMBERS_PER_LEVEL, find } from "./levels.js";

export const VERSION = 2;
export const SLOTS = [1, 2, 3];
const key = (n) => `slot${n}`;

/**
 * Reads save text of any version. Returns `{ ok: true, data }` (data is version 2, checked and cleaned) or
 * `{ ok: false, reason }` for text that is not JSON, not an object, from a newer game or not shaped like a save.
 * A damaged `storage.json` as a whole is the engine's job (`storage.corrupt`: it keeps the file and starts empty);
 * this checks ONE slot, which can still be valid JSON of the wrong shape, from a newer game or a cloud copy.
 */
export function parse(text) {
  let raw;
  try {
    raw = typeof text === "string" ? JSON.parse(text) : text;
  } catch (e) {
    return { ok: false, reason: `not valid JSON (${e.message})` };
  }
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return { ok: false, reason: "not a JSON object" };
  const version = raw.version === undefined ? 1 : raw.version;
  if (!Number.isInteger(version) || version < 1) return { ok: false, reason: `bad version ${JSON.stringify(raw.version)}` };
  if (version > VERSION) return { ok: false, reason: `version ${version} is newer than this game's (${VERSION})` };
  const data = version === 1 ? migrate1(raw) : raw;
  if (!data) return { ok: false, reason: "version 1 data needs `cleared` (a list of level ids)" };
  const levels = {};
  if (!data.levels || typeof data.levels !== "object") return { ok: false, reason: "`levels` is missing" };
  for (const level of LEVELS) {
    const e = data.levels[level.id];
    if (e === undefined) continue; // levels the game does not know are dropped
    const embers = Array.isArray(e?.embers) ? Array.from({ length: EMBERS_PER_LEVEL }, (_, i) => e.embers[i] === true) : null;
    if (!e || typeof e !== "object" || !embers || (e.bestTime !== null && typeof e.bestTime !== "number")) {
      return { ok: false, reason: `levels["${level.id}"] is not { completed, bestTime, embers }` };
    }
    levels[level.id] = { completed: !!e.completed, bestTime: e.bestTime, embers };
  }
  const counter = Number.isInteger(data.counter) && data.counter >= 0 ? data.counter : 0;
  return { ok: true, data: { version: VERSION, counter, levels } };
}

/** Version 1 -> 2. Version 1 knew finished levels and best times, not embers (they start unfound). */
export function migrate1(old) {
  if (!Array.isArray(old.cleared)) return null;
  const best = old.best && typeof old.best === "object" ? old.best : {};
  const levels = {};
  for (const id of old.cleared) {
    if (find(id)) levels[id] = { completed: true, bestTime: typeof best[id] === "number" ? best[id] : null, embers: Array(EMBERS_PER_LEVEL).fill(false) };
  }
  return { counter: 0, levels };
}

/** What the slot screen shows: `{ status: "empty" | "used" | "damaged", reason?, data?, summary? }`. */
export function peek(n) {
  const text = storage.get(key(n), null);
  if (text === null) return { status: "empty" };
  const r = parse(text);
  if (!r.ok) return { status: "damaged", reason: r.reason };
  const done = Object.values(r.data.levels);
  const summary = {
    levels: done.filter((e) => e.completed).length,
    totalLevels: LEVELS.length,
    embers: done.reduce((a, e) => a + e.embers.filter(Boolean).length, 0),
    totalEmbers: LEVELS.length * EMBERS_PER_LEVEL,
    time: done.reduce((a, e) => a + (e.bestTime ?? 0), 0),
  };
  return { status: "used", data: r.data, summary };
}

/** The slot of the last save, if it is a usable one (the main menu's Continue), else 0. */
export function lastUsed() {
  const n = storage.get("lastSlot", 0);
  return SLOTS.includes(n) && peek(n).status === "used" ? n : 0;
}

/** Makes slot `n` the current one and loads its progress (an empty slot starts a new game). False for a damaged slot. */
export function choose(n) {
  const p = peek(n);
  if (p.status === "damaged") return false;
  session.progress = p.status === "used" ? { levels: JSON.parse(JSON.stringify(p.data.levels)) } : { levels: {} };
  session.slot = n;
  session.slotCounter = p.status === "used" ? p.data.counter : 0;
  return true;
}

/** Writes the current slot (nothing when no slot was chosen) and uploads it. Called by progress.record. */
export function save() {
  const n = session.slot;
  if (!n) return;
  const text = JSON.stringify({ version: VERSION, counter: ++session.slotCounter, levels: session.progress.levels });
  storage.set(key(n), text);
  storage.set("lastSlot", n);
  upload(n, text);
}

/** Empties slot `n` here and in the cloud (otherwise the next sync would bring it back). */
export function remove(n) {
  storage.remove(key(n));
  if (storage.get("lastSlot", 0) === n) storage.remove("lastSlot");
  if (session.slot === n) session.slot = null;
  if (platform.has("cloudSave")) platform.cloud.remove(key(n)).catch(() => {}); // ponytail: a failed delete can come back at the next sync
}

function upload(n, text) {
  if (platform.has("cloudSave")) platform.cloud.save(key(n), text).catch(() => {}); // the local save stands whatever the store says
}

/**
 * Compares every slot with its cloud copy: the copy with the higher `counter` wins (the cloud one replaces the local
 * one; a better local one is uploaded). A store that is down or a player who is not signed in changes nothing.
 * Resolves with true when a local slot was replaced.
 */
export async function syncCloud() {
  if (!platform.has("cloudSave")) return false;
  let replaced = false;
  for (const n of SLOTS) {
    try {
      const cloud = await platform.cloud.load(key(n));
      const local = peek(n);
      const remote = cloud === undefined ? null : parse(cloud);
      if (remote?.ok && (local.status !== "used" || remote.data.counter > local.data.counter)) {
        storage.set(key(n), JSON.stringify(remote.data));
        replaced = true;
      } else if (local.status === "used" && (!remote?.ok || local.data.counter > remote.data.counter)) {
        upload(n, storage.get(key(n)));
      }
    } catch {
      return replaced; // offline or signed out: keep what is here
    }
  }
  return replaced;
}
